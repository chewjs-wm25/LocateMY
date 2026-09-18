import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(scriptDir, "..");
const sourcesDir = path.join(root, "sources");
const metadataDir = path.join(sourcesDir, "catalog_metadata");
const outputDir = path.join(root, "data");
const schemaDir = path.join(root, "schema");

fs.mkdirSync(outputDir, { recursive: true });
fs.mkdirSync(schemaDir, { recursive: true });

const provenance = JSON.parse(fs.readFileSync(path.join(sourcesDir, "provenance.json"), "utf8"));
const sourceRows = parseCsv(fs.readFileSync(path.join(sourcesDir, "dataset_list.csv"), "utf8"));

function parseCsv(text) {
  const rows = [];
  let row = [];
  let value = "";
  let quoted = false;
  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    if (quoted) {
      if (char === '"' && text[i + 1] === '"') {
        value += '"';
        i += 1;
      } else if (char === '"') {
        quoted = false;
      } else {
        value += char;
      }
    } else if (char === '"') {
      quoted = true;
    } else if (char === ",") {
      row.push(value);
      value = "";
    } else if (char === "\n") {
      row.push(value.replace(/\r$/, ""));
      rows.push(row);
      row = [];
      value = "";
    } else {
      value += char;
    }
  }
  if (value.length || row.length) {
    row.push(value.replace(/\r$/, ""));
    rows.push(row);
  }
  const headers = rows.shift();
  return rows.filter((item) => item.some(Boolean)).map((item) =>
    Object.fromEntries(headers.map((header, index) => [header, item[index] ?? ""]))
  );
}

function csvEscape(value) {
  const text = value == null ? "" : Array.isArray(value) ? value.join(" | ") : String(value);
  return /[",\r\n]/.test(text) ? `"${text.replaceAll('"', '""')}"` : text;
}

function sha256(content) {
  return crypto.createHash("sha256").update(content).digest("hex");
}

function normalizeList(value) {
  if (Array.isArray(value)) return value.map(String).map((item) => item.trim()).filter(Boolean);
  if (!value) return [];
  return String(value).split(",").map((item) => item.trim()).filter(Boolean);
}

function nullableInteger(value) {
  return value === "" || value == null ? null : Number(value);
}

function officialLogicalType(description) {
  const match = String(description ?? "").match(/^\s*\[([^\]]+)\]/);
  if (!match) return null;
  const raw = match[1].trim();
  const token = raw.split(",")[0].trim().toUpperCase();
  const normalized = token === "KATEGORI" ? "CATEGORICAL" : token;
  const supported = new Set(["DATE", "TIMESTAMP", "DATETIME", "INTEGER", "FLOAT", "NUMERIC", "STRING", "CATEGORICAL", "BOOLEAN"]);
  return supported.has(normalized) ? { raw, normalized } : { raw, normalized: null };
}

function sqlType(logicalType) {
  switch (logicalType) {
    case "DATE": return "DATE";
    case "TIMESTAMP":
    case "DATETIME": return "TIMESTAMP";
    case "INTEGER": return "BIGINT";
    case "FLOAT": return "DOUBLE PRECISION";
    case "NUMERIC": return "NUMERIC";
    case "BOOLEAN": return "BOOLEAN";
    case "STRING":
    case "CATEGORICAL": return "TEXT";
    default: return "TEXT";
  }
}

function normalizedField(field) {
  const type = officialLogicalType(field.description_en);
  const officialName = String(field.name ?? "");
  const normalizedName = officialName.trim();
  return {
    name: normalizedName,
    name_official_raw: officialName === normalizedName ? null : officialName,
    title: { en: field.title_en ?? null, ms: field.title_ms ?? null },
    description: { en: field.description_en ?? null, ms: field.description_ms ?? null },
    logical_type_official: type?.normalized ?? null,
    logical_type_annotation_raw: type?.raw ?? null,
    sql_type_suggested: sqlType(type?.normalized),
    sql_type_basis: type?.normalized ? "official_description_annotation" : "fallback_text_no_official_type_annotation"
  };
}

function quotedIdentifier(value) {
  return `"${String(value).replaceAll('"', '""')}"`;
}

function suggestedDdl(id, fields) {
  const columns = fields.map((field) => `  ${quotedIdentifier(field.name)} ${field.sql_type_suggested}`).join(",\n");
  return `CREATE TABLE ${quotedIdentifier(id)} (\n${columns}\n);`;
}

const catalogue = sourceRows.map((row) => {
  const metadataPath = path.join(metadataDir, `${row.id}.json`);
  const metadataText = fs.readFileSync(metadataPath, "utf8");
  const meta = JSON.parse(metadataText);
  const sites = [...new Set((meta.site_category ?? []).map((item) => item.site))];
  const apiAvailable = meta.exclude_openapi !== true;
  const fields = (meta.fields ?? []).map(normalizedField);
  const dataCataloguePage = `https://data.gov.my/data-catalogue/${encodeURIComponent(row.id)}`;
  const openDosmPage = sites.includes("opendosm")
    ? `https://open.dosm.gov.my/data-catalogue/${encodeURIComponent(row.id)}`
    : null;
  return {
    knowledge_base_version: "1.0.0",
    record_kind: "catalogue_dataset",
    id: row.id,
    date_created: row.date_created || null,
    title: { en: meta.title_en ?? row.title_en ?? null, ms: meta.title_ms ?? row.title_bm ?? null },
    description: { en: meta.description_en ?? null, ms: meta.description_ms ?? null },
    classification: {
      category: { en: row.category_en || null, ms: row.category_bm || null },
      subcategory: { en: row.subcategory_en || null, ms: row.subcategory_bm || null }
    },
    source_agencies: normalizeList(meta.data_source),
    source_units: normalizeList(meta.data_source_granular),
    portal_visibility: sites,
    api: {
      data_catalogue: {
        available: apiAvailable,
        endpoint: apiAvailable ? `https://api.data.gov.my/data-catalogue?id=${encodeURIComponent(row.id)}` : null
      },
      opendosm: {
        available: apiAvailable && sites.includes("opendosm"),
        endpoint: apiAvailable && sites.includes("opendosm")
          ? `https://api.data.gov.my/opendosm?id=${encodeURIComponent(row.id)}`
          : null
      },
      exclusion_flag_official: meta.exclude_openapi === true
    },
    files: {
      csv: meta.link_csv ?? null,
      parquet: meta.link_parquet ?? null,
      preview: meta.link_preview ?? null
    },
    edition_keys: meta.link_editions ?? [],
    temporal: {
      frequency: meta.frequency ?? row.frequency ?? null,
      data_as_of: meta.data_as_of ?? null,
      last_updated: meta.last_updated ?? null,
      next_update: meta.next_update ?? null,
      dataset_begin_year: nullableInteger(meta.dataset_begin ?? row.dataset_begin),
      dataset_end_year: nullableInteger(meta.dataset_end ?? row.dataset_end)
    },
    dimensions: {
      geography: normalizeList(meta.geography ?? row.geography),
      demography: normalizeList(meta.demography ?? row.demography)
    },
    methodology: { en: meta.methodology_en ?? null, ms: meta.methodology_ms ?? null },
    caveats: { en: meta.caveat_en ?? null, ms: meta.caveat_ms ?? null },
    publications: { en: meta.publication_en ?? null, ms: meta.publication_ms ?? null },
    license: {
      name: "Creative Commons Attribution 4.0 International",
      identifier: "CC-BY-4.0",
      basis: "Platform-wide licence stated by Malaysia's Official Open API FAQ"
    },
    fields,
    sql_structure: {
      official: false,
      dialect: "PostgreSQL-compatible suggestion",
      warning: "This DDL is derived from type labels in official field descriptions; it is not an official database schema. Nullability, keys, constraints, indexes and precision are not published.",
      ddl: suggestedDdl(row.id, fields)
    },
    dataviz: meta.dataviz ?? [],
    related_datasets: meta.related_datasets ?? [],
    official_pages: [dataCataloguePage, openDosmPage].filter(Boolean),
    provenance: {
      catalogue_list_url: provenance.dataset_list.download_url,
      metadata_url: `https://github.com/data-gov-my/datagovmy-meta/blob/${provenance.datagovmy_meta.commit}/data-catalogue/${encodeURIComponent(row.id)}.json`,
      metadata_snapshot_path: `sources/catalog_metadata/${row.id}.json`,
      metadata_sha256: sha256(metadataText),
      captured_at: provenance.captured_at
    }
  };
});

const gtfsStaticAgencies = [
  ["ktmb", "KTMB", null, "DAILY at 00:01"],
  ["prasarana", "Prasarana", "rapid-bus-penang", "AS_REQUIRED"],
  ["prasarana", "Prasarana", "rapid-bus-kuantan", "AS_REQUIRED"],
  ["prasarana", "Prasarana", "rapid-bus-mrtfeeder", "AS_REQUIRED"],
  ["prasarana", "Prasarana", "rapid-rail-kl", "AS_REQUIRED"],
  ["prasarana", "Prasarana", "rapid-bus-kl", "AS_REQUIRED"],
  ["mybas-kangar", "BAS.MY Kangar", null, "AS_REQUIRED"],
  ["mybas-alor-setar", "BAS.MY Alor Setar", null, "AS_REQUIRED"],
  ["mybas-kota-bharu", "BAS.MY Kota Bharu", null, "AS_REQUIRED"],
  ["mybas-kuala-terengganu", "BAS.MY Kuala Terengganu", null, "AS_REQUIRED"],
  ["mybas-ipoh", "BAS.MY Ipoh", null, "AS_REQUIRED"],
  ["mybas-seremban-a", "BAS.MY Seremban operator A", null, "AS_REQUIRED"],
  ["mybas-seremban-b", "BAS.MY Seremban operator B", null, "AS_REQUIRED"],
  ["mybas-melaka", "BAS.MY Melaka", null, "AS_REQUIRED"],
  ["mybas-johor", "BAS.MY Johor Bahru", null, "AS_REQUIRED"],
  ["mybas-kuching", "BAS.MY Kuching", null, "AS_REQUIRED"]
];

const gtfsRealtimeAgencies = [
  ["ktmb", "KTMB", null],
  ["prasarana", "Prasarana", "rapid-bus-kl"],
  ["prasarana", "Prasarana", "rapid-bus-mrtfeeder"],
  ["prasarana", "Prasarana", "rapid-bus-kuantan"],
  ["prasarana", "Prasarana", "rapid-bus-penang"],
  ["mybas-kangar", "BAS.MY Kangar", null],
  ["mybas-alor-setar", "BAS.MY Alor Setar", null],
  ["mybas-kota-bharu", "BAS.MY Kota Bharu", null],
  ["mybas-kuala-terengganu", "BAS.MY Kuala Terengganu", null],
  ["mybas-ipoh", "BAS.MY Ipoh", null],
  ["mybas-seremban-a", "BAS.MY Seremban operator A", null],
  ["mybas-seremban-b", "BAS.MY Seremban operator B", null],
  ["mybas-melaka", "BAS.MY Melaka", null],
  ["mybas-johor", "BAS.MY Johor Bahru", null],
  ["mybas-kuching", "BAS.MY Kuching", null]
];

function realtimeBase(id, title, description, endpoint, frequency, responseFormat, fields, docsUrl) {
  return {
    knowledge_base_version: "1.0.0",
    record_kind: "realtime_api_resource",
    id,
    title: { en: title, ms: null },
    description: { en: description, ms: null },
    api: { available: true, method: "GET", endpoint, authentication_required: false, rate_limit: "4 requests per minute" },
    temporal: { frequency },
    response_format: responseFormat,
    fields,
    sql_structure: fields.length
      ? {
          official: false,
          dialect: "PostgreSQL-compatible suggestion",
          warning: "Derived from official API documentation, not an official database schema.",
          ddl: suggestedDdl(id, fields)
        }
      : {
          official: false,
          dialect: null,
          warning: "No SQL DDL is generated because the Malaysian official documentation refers to an external transport standard without publishing the complete field schema.",
          ddl: null
        },
    license: { name: "Creative Commons Attribution 4.0 International", identifier: "CC-BY-4.0", basis: "Platform-wide licence stated by Malaysia's Official Open API FAQ" },
    official_pages: [docsUrl],
    provenance: { docs_url: docsUrl, docs_commit: provenance.datagovmy_front.commit, captured_at: provenance.captured_at }
  };
}

const realtime = [];

for (const [agency, operator, category, frequency] of gtfsStaticAgencies) {
  const query = category ? `?category=${category}` : "";
  const id = `gtfs_static_${agency.replaceAll("-", "_")}${category ? `_${category.replaceAll("-", "_")}` : ""}`;
  const caveats = agency === "prasarana" && category === "rapid-bus-kl"
    ? ["The official documentation says a small number of trips (about 2%) were removed from stop_times.txt because of operational data-accuracy issues."]
    : [];
  realtime.push({
    ...realtimeBase(
      id,
      `GTFS Static: ${operator}${category ? ` (${category})` : ""}`,
      "Standardized public-transport schedules and geographic information packaged as a GTFS ZIP feed.",
      `https://api.data.gov.my/gtfs-static/${agency}${query}`,
      frequency,
      "application/zip (GTFS text files)",
      [],
      "https://developer.data.gov.my/realtime-api/gtfs-static"
    ),
    source_operators: [operator],
    container_members_officially_listed: ["agency.txt", "stops.txt", "routes.txt", "trips.txt", "stop_times.txt", "calendar.txt"],
    optional_container_members_officially_mentioned: ["frequencies.txt", "shapes.txt"],
    caveats
  });
}

for (const [agency, operator, category] of gtfsRealtimeAgencies) {
  const query = category ? `?category=${category}` : "";
  const id = `gtfs_realtime_vehicle_position_${agency.replaceAll("-", "_")}${category ? `_${category.replaceAll("-", "_")}` : ""}`;
  const caveats = ["Occasional erroneous GPS transponder data may place a vehicle outside the service area (validator E028)."];
  if (agency === "prasarana" && ["rapid-bus-kuantan", "rapid-bus-penang"].includes(category)) {
    caveats.push("The official documentation records legacy-system validation issues E003/E004 involving trip_id and route_id alignment with the static feed.");
  }
  if (agency === "prasarana" && category === "rapid-bus-penang") {
    caveats.push("Realtime trip IDs must be matched to the suffix of corresponding static-feed trip IDs.");
  }
  realtime.push({
    ...realtimeBase(
      id,
      `GTFS Realtime Vehicle Position: ${operator}${category ? ` (${category})` : ""}`,
      "Live public-transport vehicle positions. The Malaysian API currently provides vehicle-position feeds, not service alerts or trip updates.",
      `https://api.data.gov.my/gtfs-realtime/vehicle-position/${agency}${query}`,
      "EVERY_30_SECONDS",
      "Protocol Buffers (GTFS Realtime FeedMessage)",
      [],
      "https://developer.data.gov.my/realtime-api/gtfs-realtime"
    ),
    source_operators: [operator],
    feed_type: "vehicle-position",
    caveats
  });
}

function documentedField(name, logicalType, description) {
  return {
    name,
    title: { en: null, ms: null },
    description: { en: description, ms: null },
    logical_type_official: logicalType,
    logical_type_annotation_raw: logicalType,
    sql_type_suggested: sqlType(logicalType),
    sql_type_basis: "official_developer_documentation"
  };
}

const forecastFields = [
  documentedField("location.location_id", "STRING", "Unique location identifier; prefixes identify State, Recreation Centre, District, Town or Division."),
  documentedField("location.location_name", "STRING", "Location name."),
  documentedField("date", "DATE", "Forecast date."),
  documentedField("morning_forecast", "STRING", "Morning-period forecast."),
  documentedField("afternoon_forecast", "STRING", "Afternoon-period forecast."),
  documentedField("night_forecast", "STRING", "Night-period forecast."),
  documentedField("summary_forecast", "STRING", "Daily forecast summary."),
  documentedField("summary_when", "STRING", "Timing covered by the summarized forecast."),
  documentedField("min_temp", "INTEGER", "Minimum daily temperature in degrees Celsius."),
  documentedField("max_temp", "INTEGER", "Maximum daily temperature in degrees Celsius.")
];

const warningFields = [
  documentedField("warning_issue.issued", "TIMESTAMP", "Date and time the warning was issued."),
  documentedField("warning_issue.title_bm", "STRING", "Warning title in Bahasa Melayu."),
  documentedField("warning_issue.title_en", "STRING", "Warning title in English."),
  documentedField("valid_from", "TIMESTAMP", "Start of the warning validity period."),
  documentedField("valid_to", "TIMESTAMP", "End of the warning validity period."),
  ...["heading_en", "text_en", "instruction_en", "heading_bm", "text_bm", "instruction_bm"].map((name) => documentedField(name, "STRING", `${name.replaceAll("_", " ")}.`))
];

const earthquakeFields = [
  documentedField("utcdatetime", "TIMESTAMP", "Earthquake date and time in UTC."),
  documentedField("localdatetime", "TIMESTAMP", "Earthquake local date and time (UTC+08:00)."),
  documentedField("lat", "FLOAT", "Latitude."),
  documentedField("lon", "FLOAT", "Longitude."),
  documentedField("depth", "FLOAT", "Depth in kilometres."),
  documentedField("location", "STRING", "Location description in Bahasa Melayu."),
  documentedField("location_original", "STRING", "Location description in English."),
  documentedField("n_distancemas", "STRING", "Distance from Malaysia in English."),
  documentedField("n_distancerest", "STRING", "Distance from other locations in English."),
  documentedField("nbm_distancemas", "STRING", "Distance from Malaysia in Bahasa Melayu."),
  documentedField("nbm_distancerest", "STRING", "Distance from other locations in Bahasa Melayu."),
  documentedField("magdefault", "FLOAT", "Default magnitude."),
  documentedField("magtypedefault", "STRING", "Default magnitude type."),
  documentedField("status", "STRING", "Earthquake status."),
  documentedField("visible", "BOOLEAN", "Visibility status."),
  documentedField("lat_vector", "STRING", "Latitude vector representation in Bahasa Melayu."),
  documentedField("lon_vector", "STRING", "Longitude vector representation in Bahasa Melayu.")
];

realtime.push({
  ...realtimeBase("weather_forecast_7day", "Weather: 7-day General Forecast", "Seven-day general forecast from MET Malaysia.", "https://api.data.gov.my/weather/forecast", "DAILY", "JSON records", forecastFields, "https://developer.data.gov.my/realtime-api/weather"),
  source_agencies: ["MET Malaysia"],
  caveats: ["Forecast enumeration values are currently available only in Bahasa Melayu.", "Marine forecast data is unavailable according to the official documentation."]
});
realtime.push({
  ...realtimeBase("weather_warning", "Weather: Warning Forecast", "Live weather warnings from MET Malaysia.", "https://api.data.gov.my/weather/warning", "AS_REQUIRED", "JSON records", warningFields, "https://developer.data.gov.my/realtime-api/weather"),
  source_agencies: ["MET Malaysia"], caveats: []
});
realtime.push({
  ...realtimeBase("weather_warning_earthquake", "Weather: Earthquake Warning", "Earthquake warnings from MET Malaysia, separated because of their unique format.", "https://api.data.gov.my/weather/warning/earthquake", "AS_REQUIRED", "JSON records", earthquakeFields, "https://developer.data.gov.my/realtime-api/weather"),
  source_agencies: ["MET Malaysia"], caveats: []
});

catalogue.sort((a, b) => a.id.localeCompare(b.id));
realtime.sort((a, b) => a.id.localeCompare(b.id));
const allResources = [...catalogue, ...realtime].sort((a, b) => a.id.localeCompare(b.id));

function writeJsonl(filename, records) {
  fs.writeFileSync(path.join(outputDir, filename), `${records.map((item) => JSON.stringify(item)).join("\n")}\n`, "utf8");
}

writeJsonl("catalogue_datasets.jsonl", catalogue);
writeJsonl("realtime_resources.jsonl", realtime);
writeJsonl("all_resources.jsonl", allResources);

const indexHeaders = ["id", "record_kind", "title_en", "title_ms", "category_en", "subcategory_en", "source_agencies", "frequency", "api_available", "opendosm_api_available", "field_count", "data_begin_year", "data_end_year", "last_updated", "next_update", "official_page"];
const indexRows = allResources.map((item) => ({
  id: item.id,
  record_kind: item.record_kind,
  title_en: item.title?.en,
  title_ms: item.title?.ms,
  category_en: item.classification?.category?.en,
  subcategory_en: item.classification?.subcategory?.en,
  source_agencies: item.source_agencies ?? item.source_operators,
  frequency: item.temporal?.frequency,
  api_available: item.record_kind === "catalogue_dataset" ? item.api.data_catalogue.available : item.api.available,
  opendosm_api_available: item.api?.opendosm?.available ?? false,
  field_count: item.fields?.length ?? 0,
  data_begin_year: item.temporal?.dataset_begin_year,
  data_end_year: item.temporal?.dataset_end_year,
  last_updated: item.temporal?.last_updated,
  next_update: item.temporal?.next_update,
  official_page: item.official_pages?.[0]
}));
fs.writeFileSync(path.join(outputDir, "resource_index.csv"), [
  indexHeaders.join(","),
  ...indexRows.map((row) => indexHeaders.map((header) => csvEscape(row[header])).join(","))
].join("\n") + "\n", "utf8");

function distribution(records, selector) {
  const counts = new Map();
  for (const record of records) {
    const values = selector(record);
    for (const value of Array.isArray(values) ? values : [values]) {
      const key = value || "UNSPECIFIED";
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
  }
  return Object.fromEntries([...counts.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0])));
}

const summary = {
  knowledge_base_version: "1.0.0",
  captured_at: provenance.captured_at,
  totals: {
    catalogue_datasets: catalogue.length,
    catalogue_api_available: catalogue.filter((item) => item.api.data_catalogue.available).length,
    catalogue_not_api_available: catalogue.filter((item) => !item.api.data_catalogue.available).length,
    opendosm_visible: catalogue.filter((item) => item.portal_visibility.includes("opendosm")).length,
    opendosm_api_available: catalogue.filter((item) => item.api.opendosm.available).length,
    realtime_resources: realtime.length,
    all_resources: allResources.length,
    catalogue_fields: catalogue.reduce((sum, item) => sum + item.fields.length, 0),
    catalogue_fields_without_official_type_annotation: catalogue.flatMap((item) => item.fields).filter((field) => !field.logical_type_official).length
  },
  distributions: {
    catalogue_frequency: distribution(catalogue, (item) => item.temporal.frequency),
    catalogue_source_agency: distribution(catalogue, (item) => item.source_agencies),
    catalogue_category_en: distribution(catalogue, (item) => item.classification.category.en),
    portal_visibility: distribution(catalogue, (item) => item.portal_visibility.join("+"))
  }
};
fs.writeFileSync(path.join(outputDir, "summary.json"), JSON.stringify(summary, null, 2) + "\n", "utf8");

const schema = {
  $schema: "https://json-schema.org/draft/2020-12/schema",
  title: "Malaysia Government Open Data Knowledge Base record",
  type: "object",
  required: ["knowledge_base_version", "record_kind", "id", "title", "description", "api", "temporal", "fields", "license", "official_pages", "provenance"],
  properties: {
    knowledge_base_version: { type: "string" },
    record_kind: { enum: ["catalogue_dataset", "realtime_api_resource"] },
    id: { type: "string", minLength: 1 },
    title: { type: "object", required: ["en", "ms"] },
    description: { type: "object", required: ["en", "ms"] },
    fields: { type: "array", items: { type: "object", required: ["name", "description", "logical_type_official", "sql_type_suggested", "sql_type_basis"] } },
    official_pages: { type: "array", minItems: 1, items: { type: "string", format: "uri" } },
    provenance: { type: "object" }
  }
};
fs.writeFileSync(path.join(schemaDir, "resource.schema.json"), JSON.stringify(schema, null, 2) + "\n", "utf8");

const filesForManifest = [
  "data/catalogue_datasets.jsonl",
  "data/realtime_resources.jsonl",
  "data/all_resources.jsonl",
  "data/resource_index.csv",
  "data/summary.json",
  "schema/resource.schema.json"
];
const manifest = {
  knowledge_base_version: "1.0.0",
  captured_at: provenance.captured_at,
  files: Object.fromEntries(filesForManifest.map((relativePath) => {
    const content = fs.readFileSync(path.join(root, relativePath));
    return [relativePath.replaceAll("\\", "/"), { bytes: content.length, sha256: sha256(content) }];
  }))
};
fs.writeFileSync(path.join(root, "manifest.json"), JSON.stringify(manifest, null, 2) + "\n", "utf8");

console.log(JSON.stringify(summary.totals, null, 2));
