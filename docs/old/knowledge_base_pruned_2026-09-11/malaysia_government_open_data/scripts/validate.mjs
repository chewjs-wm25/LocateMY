import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const failures = [];
const warnings = [];

function assert(condition, message) {
  if (!condition) failures.push(message);
}

function sha256(content) {
  return crypto.createHash("sha256").update(content).digest("hex");
}

function parseCsv(text) {
  const rows = [];
  let row = [];
  let value = "";
  let quoted = false;
  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    if (quoted) {
      if (char === '"' && text[i + 1] === '"') { value += '"'; i += 1; }
      else if (char === '"') quoted = false;
      else value += char;
    } else if (char === '"') quoted = true;
    else if (char === ",") { row.push(value); value = ""; }
    else if (char === "\n") { row.push(value.replace(/\r$/, "")); rows.push(row); row = []; value = ""; }
    else value += char;
  }
  if (value.length || row.length) { row.push(value.replace(/\r$/, "")); rows.push(row); }
  const headers = rows.shift();
  return rows.filter((item) => item.some(Boolean)).map((item) => Object.fromEntries(headers.map((header, index) => [header, item[index] ?? ""])));
}

function normalizeList(value) {
  if (Array.isArray(value)) return value.map(String).map((item) => item.trim()).filter(Boolean);
  return String(value ?? "").split(",").map((item) => item.trim()).filter(Boolean);
}

function sameList(left, right) {
  return JSON.stringify(normalizeList(left)) === JSON.stringify(normalizeList(right));
}

function readJsonl(relativePath) {
  const lines = fs.readFileSync(path.join(root, relativePath), "utf8").trim().split(/\r?\n/);
  return lines.map((line, index) => {
    try { return JSON.parse(line); }
    catch (error) { failures.push(`${relativePath}:${index + 1} invalid JSON: ${error.message}`); return null; }
  }).filter(Boolean);
}

const catalogue = readJsonl("data/catalogue_datasets.jsonl");
const realtime = readJsonl("data/realtime_resources.jsonl");
const all = readJsonl("data/all_resources.jsonl");
const summary = JSON.parse(fs.readFileSync(path.join(root, "data/summary.json"), "utf8"));
const manifest = JSON.parse(fs.readFileSync(path.join(root, "manifest.json"), "utf8"));
const provenance = JSON.parse(fs.readFileSync(path.join(root, "sources/provenance.json"), "utf8"));
const datasetListContent = fs.readFileSync(path.join(root, "sources/dataset_list.csv"));
const datasetList = parseCsv(datasetListContent.toString("utf8"));

assert(catalogue.length === 290, `Expected 290 catalogue datasets, found ${catalogue.length}`);
assert(realtime.length === 34, `Expected 34 realtime resources, found ${realtime.length}`);
assert(all.length === catalogue.length + realtime.length, "all_resources count does not equal catalogue + realtime");
assert(summary.totals.catalogue_datasets === catalogue.length, "summary catalogue count mismatch");
assert(summary.totals.realtime_resources === realtime.length, "summary realtime count mismatch");
assert(datasetList.length === catalogue.length, `dataset_list.csv count ${datasetList.length} != catalogue count ${catalogue.length}`);

const ids = new Set();
for (const record of all) {
  assert(!ids.has(record.id), `Duplicate resource id: ${record.id}`);
  ids.add(record.id);
  assert(record.title && Object.hasOwn(record.title, "en"), `${record.id}: missing title.en`);
  assert(record.description && Object.hasOwn(record.description, "en"), `${record.id}: missing description.en`);
  assert(Array.isArray(record.fields), `${record.id}: fields is not an array`);
  assert(Array.isArray(record.official_pages) && record.official_pages.length > 0, `${record.id}: missing official page`);
  const fieldNames = new Set();
  for (const field of record.fields ?? []) {
    assert(field.name && typeof field.name === "string", `${record.id}: invalid field name`);
    assert(!fieldNames.has(field.name), `${record.id}: duplicate field ${field.name}`);
    fieldNames.add(field.name);
    assert(field.sql_type_suggested, `${record.id}.${field.name}: missing SQL type suggestion`);
  }
}

const expectedAllIds = new Set([...catalogue, ...realtime].map((record) => record.id));
assert(expectedAllIds.size === all.length, "catalogue/realtime union contains duplicate IDs");
for (const record of all) assert(expectedAllIds.has(record.id), `all_resources contains unexpected ID: ${record.id}`);

const catalogueById = new Map(catalogue.map((record) => [record.id, record]));
const listIds = new Set();
for (const row of datasetList) {
  assert(!listIds.has(row.id), `dataset_list.csv duplicate ID: ${row.id}`);
  listIds.add(row.id);
  const record = catalogueById.get(row.id);
  assert(Boolean(record), `dataset_list.csv ID missing from generated catalogue: ${row.id}`);
  if (!record) continue;
  assert(record.date_created === (row.date_created || null), `${row.id}: date_created differs from dataset list`);
  assert(record.title.en === row.title_en, `${row.id}: English title differs from dataset list`);
  assert(record.title.ms === row.title_bm, `${row.id}: Malay title differs from dataset list`);
  assert(record.temporal.frequency === row.frequency, `${row.id}: frequency differs from dataset list`);
  assert(String(record.temporal.dataset_begin_year ?? "") === row.dataset_begin, `${row.id}: begin year differs from dataset list`);
  assert(String(record.temporal.dataset_end_year ?? "") === row.dataset_end, `${row.id}: end year differs from dataset list`);
  assert(sameList(record.source_agencies, row.source), `${row.id}: source agencies differ from dataset list`);
  assert(sameList(record.dimensions.geography, row.geography), `${row.id}: geography differs from dataset list`);
  assert(sameList(record.dimensions.demography, row.demography), `${row.id}: demography differs from dataset list`);
}
for (const record of catalogue) assert(listIds.has(record.id), `Generated catalogue ID missing from dataset_list.csv: ${record.id}`);

const sourceMetadataFiles = fs.readdirSync(path.join(root, "sources/catalog_metadata")).filter((name) => name.endsWith(".json"));
assert(sourceMetadataFiles.length === catalogue.length, `Source metadata count ${sourceMetadataFiles.length} != catalogue count ${catalogue.length}`);

for (const record of catalogue) {
  const metadataPath = path.join(root, record.provenance.metadata_snapshot_path);
  assert(fs.existsSync(metadataPath), `${record.id}: metadata snapshot missing`);
  if (fs.existsSync(metadataPath)) {
    const content = fs.readFileSync(metadataPath);
    assert(sha256(content) === record.provenance.metadata_sha256, `${record.id}: metadata SHA-256 mismatch`);
    const raw = JSON.parse(content.toString("utf8"));
    assert(raw.title_en === record.title.en, `${record.id}: title differs from official metadata`);
    assert((raw.fields ?? []).length === record.fields.length, `${record.id}: field count differs from official metadata`);
    assert((raw.frequency ?? null) === record.temporal.frequency, `${record.id}: frequency differs from official metadata`);
    assert((raw.exclude_openapi === true) === !record.api.data_catalogue.available, `${record.id}: API availability flag mismatch`);
    for (const field of raw.fields ?? []) {
      if (String(field.name).trim() !== String(field.name)) {
        warnings.push(`${record.id}: official field name contains leading/trailing whitespace: ${JSON.stringify(field.name)}`);
      }
    }
  }
  if (!record.caveats.en) warnings.push(`${record.id}: official English caveat is blank`);
  if (!record.publications.en) warnings.push(`${record.id}: official English publication field is blank`);
}

const allowedOfficialPage = /^(https:\/\/)(data\.gov\.my|open\.dosm\.gov\.my|developer\.data\.gov\.my)(\/|$)/;
for (const record of all) {
  for (const url of record.official_pages) {
    assert(allowedOfficialPage.test(url), `${record.id}: official page outside approved Malaysian government portals: ${url}`);
  }
}

for (const record of catalogue) {
  for (const [format, url] of Object.entries(record.files)) {
    if (!url) continue;
    try { new URL(url); }
    catch { failures.push(`${record.id}: invalid ${format} URL: ${url}`); }
  }
  for (const endpoint of [record.api.data_catalogue.endpoint, record.api.opendosm.endpoint].filter(Boolean)) {
    try { new URL(endpoint); }
    catch { failures.push(`${record.id}: invalid API endpoint URL: ${endpoint}`); }
  }
}

for (const [relativePath, expected] of Object.entries(manifest.files)) {
  const content = fs.readFileSync(path.join(root, relativePath));
  assert(content.length === expected.bytes, `${relativePath}: byte length differs from manifest`);
  assert(sha256(content) === expected.sha256, `${relativePath}: SHA-256 differs from manifest`);
}

assert(sha256(datasetListContent).toUpperCase() === provenance.dataset_list.sha256.toUpperCase(), "dataset_list.csv SHA-256 differs from provenance");

const report = {
  checked_at: new Date().toISOString(),
  status: failures.length ? "FAIL" : "PASS",
  checks: {
    catalogue_records: catalogue.length,
    realtime_resources: realtime.length,
    all_resources: all.length,
    unique_ids: ids.size,
    source_metadata_files: sourceMetadataFiles.length,
    catalogue_fields: catalogue.reduce((sum, record) => sum + record.fields.length, 0),
    manifest_files_checked: Object.keys(manifest.files).length
  },
  warnings,
  failures
};
fs.writeFileSync(path.join(root, "audit_result.json"), JSON.stringify(report, null, 2) + "\n", "utf8");
console.log(JSON.stringify(report, null, 2));
if (failures.length) process.exitCode = 1;
