begin;

-- One immutable audit row identifies each frozen source and its deterministic
-- geometry derivation. Import metadata stays outside the government business
-- rows, while a versioned boundary row can point back to its evidence.
create table public.government_dataset_imports (
  dataset_id text not null,
  source_url text not null,
  source_version text not null,
  source_sha256 text not null check (source_sha256 ~ '^[0-9a-f]{64}$'),
  geometry_transform text not null,
  derived_geometry_sha256 text not null check (derived_geometry_sha256 ~ '^[0-9a-f]{64}$'),
  row_count integer not null check (row_count > 0),
  imported_at timestamptz not null default now(),
  primary key (dataset_id, source_version, derived_geometry_sha256)
);

alter table public.government_dataset_imports enable row level security;

create table public.administrative_district_boundaries (
  boundary_id text not null,
  state text not null,
  district text not null,
  source_dataset text not null,
  source_version text not null,
  derived_geometry_sha256 text not null,
  boundary_geom public.geometry(MultiPolygon, 4326) not null,
  primary key (boundary_id, source_version, derived_geometry_sha256),
  foreign key (source_dataset, source_version, derived_geometry_sha256)
    references public.government_dataset_imports
      (dataset_id, source_version, derived_geometry_sha256),
  check (public.st_srid(boundary_geom) = 4326),
  check (public.st_isvalid(boundary_geom)),
  check (not public.st_isempty(boundary_geom))
);

alter table public.administrative_district_boundaries enable row level security;

create index administrative_district_boundaries_geom_idx
  on public.administrative_district_boundaries using gist (boundary_geom);
create index administrative_district_boundaries_audit_idx
  on public.administrative_district_boundaries
    (source_dataset, source_version, derived_geometry_sha256);

-- This public RPC is the only client read path. It returns every covering
-- candidate plus the immutable import facts; Geographic Context classifies
-- zero/one/many candidates as unresolved/resolved/ambiguous.
create function public.read_administrative_boundary_candidates(
  latitude double precision,
  longitude double precision
)
returns table (
  boundary_id text,
  state text,
  district text,
  source_dataset text,
  source_url text,
  source_version text,
  source_sha256 text,
  geometry_transform text,
  derived_geometry_sha256 text,
  imported_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select
    b.boundary_id,
    b.state,
    b.district,
    b.source_dataset,
    i.source_url,
    b.source_version,
    i.source_sha256,
    i.geometry_transform,
    b.derived_geometry_sha256,
    i.imported_at
  from public.administrative_district_boundaries as b
  join public.government_dataset_imports as i
    on i.dataset_id = b.source_dataset
   and i.source_version = b.source_version
   and i.derived_geometry_sha256 = b.derived_geometry_sha256
  where latitude between -90 and 90
    and longitude between -180 and 180
    and public.st_covers(
      b.boundary_geom,
      public.st_setsrid(public.st_makepoint(longitude, latitude), 4326)
    )
  order by b.boundary_id;
$$;

revoke all on table public.government_dataset_imports,
  public.administrative_district_boundaries from public, anon, authenticated;
revoke all on function public.read_administrative_boundary_candidates(double precision, double precision)
  from public, anon;
grant execute on function public.read_administrative_boundary_candidates(double precision, double precision)
  to authenticated;

comment on table public.government_dataset_imports is
  'Immutable import audit for one-time government dataset imports.';
comment on table public.administrative_district_boundaries is
  'DOSM administrative district boundary mirror; only read through its stable RPC.';

commit;
