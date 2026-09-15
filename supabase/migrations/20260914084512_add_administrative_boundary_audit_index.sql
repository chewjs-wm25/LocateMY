create index administrative_district_boundaries_audit_idx
  on public.administrative_district_boundaries
    (source_dataset, source_version, derived_geometry_sha256);
;
