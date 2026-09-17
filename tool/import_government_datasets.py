#!/usr/bin/env python3
"""Manual, resumable import of locally verified government files. No scheduler."""
import argparse
import csv
import hashlib
import json
import math
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor
from decimal import Decimal
from pathlib import Path

from import_home_datasets import read_values

ROOT = Path(__file__).resolve().parents[1]
DOWNLOADS = ROOT / "data/government-downloads"
EVIDENCE = ROOT / "build/government-import-2026-09-17"
IMPORT_ID = "manual-2026-09-17-basket-v1"
BASKET = {1, 16, 118, 224, 272, 904, 918, 1589, 1605, 1645, 1541}
SPECS = {
    "lookup_item": (["item_code"], {"item_code"}, set(), "https://storage.data.gov.my/pricecatcher/lookup_item.csv"),
    "lookup_premise": (["premise_code"], {"premise_code"}, set(), "https://storage.data.gov.my/pricecatcher/lookup_premise.csv"),
    "hh_inequality_state": (["state", "date"], set(), {"gini"}, "https://storage.dosm.gov.my/hies/hh_inequality_state.csv"),
    "hies_state_percentile": (["date", "state", "percentile", "variable"], {"percentile", "income"}, set(), "https://storage.dosm.gov.my/hies/hies_state_percentile.csv"),
    "population_district": (["date", "state", "district", "sex", "age", "ethnicity"], set(), {"population"}, "https://storage.dosm.gov.my/population/population_district.csv"),
    "pricecatcher": (["date", "premise_code", "item_code"], {"premise_code", "item_code"}, {"price"}, ""),
}


def integer(value):
    number = Decimal(value)
    if not number.is_finite() or number != number.to_integral_value():
        raise ValueError("Noninteger official identifier or integer field")
    return int(number)


def request(config, path, records=None, prefer=None):
    headers = {
        "apikey": config["SUPABASE_SECRET_KEY"],
        "Authorization": "Bearer " + config["SUPABASE_SECRET_KEY"],
        "Content-Type": "application/json",
    }
    if prefer:
        headers["Prefer"] = prefer
    data = None if records is None else json.dumps(records, allow_nan=False).encode()
    req = urllib.request.Request(config["SUPABASE_URL"] + "/rest/v1/" + path,
                                 headers=headers, data=data,
                                 method="GET" if records is None else "POST")
    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            raw = response.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as error:
        raise RuntimeError("Import HTTP " + str(error.code) + "; details redacted") from None
    except Exception:
        raise RuntimeError("Import request failed; sensitive details redacted") from None


def sha256_file(path):
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        while block := stream.read(1024 * 1024):
            digest.update(block)
    return digest.hexdigest()


def canonical(value):
    if value is None:
        return "<NULL>"
    if isinstance(value, (int, float)):
        return format(Decimal(str(value)).normalize(), "f")
    return value


def import_file(config, dataset, path, dry_run=False):
    keys, integers, floats, url = SPECS[dataset]
    if dataset == "pricecatcher":
        url = "https://storage.data.gov.my/pricecatcher/" + path.name
    file_hash = sha256_file(path)
    checkpoint = EVIDENCE / (path.stem + "-checkpoint.json")
    completed = set()
    if checkpoint.exists():
        previous = json.loads(checkpoint.read_text())
        if previous["sha256"] != file_hash or previous["import_id"] != IMPORT_ID:
            raise RuntimeError("Checkpoint does not match this immutable source")
        completed = set(previous["completed_chunks"])
    selection = "all official rows"
    if dataset == "pricecatcher":
        selection = "cost-basket-v1 item_code in (" + ",".join(map(str, sorted(BASKET))) + ")"
    if dataset == "lookup_premise":
        selection = "all official rows with a nonempty premise_code; isolate empty-key row"
    digest_columns = None
    digest_sums = [0, 0]
    count = 0
    excluded = 0
    rejected = 0
    total = 0
    chunk = []
    chunk_index = 0
    futures = []

    def submit(pool, values, index):
        if dry_run or index in completed:
            return
        query = urllib.parse.urlencode({"on_conflict": ",".join(keys)})
        future = pool.submit(request, config, dataset + "?" + query, values,
                             "resolution=merge-duplicates,return=minimal")
        futures.append((index, future))
        if len(futures) >= 4:
            finish()

    def finish():
        index, future = futures.pop(0)
        future.result()
        completed.add(index)
        checkpoint.write_text(json.dumps({"sha256": file_hash, "import_id": IMPORT_ID,
                                          "completed_chunks": sorted(completed)}) + "\n")

    with ThreadPoolExecutor(max_workers=4) as pool, path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        digest_columns = sorted(reader.fieldnames)
        for raw in reader:
            total += 1
            if None in raw or any(value is None for value in raw.values()):
                raise ValueError("Malformed CSV row")
            if dataset == "lookup_premise" and not raw["premise_code"]:
                rejected += 1
                continue
            row = dict(raw)
            for key in integers:
                row[key] = None if raw[key] == "" else integer(raw[key])
            for key in floats:
                row[key] = None if raw[key] == "" else float(raw[key])
                if row[key] is not None and not math.isfinite(row[key]):
                    raise ValueError("Nonfinite official observation")
            if dataset == "pricecatcher" and row["item_code"] not in BASKET:
                excluded += 1
                continue
            if any(row[key] is None or row[key] == "" for key in keys):
                raise ValueError("Missing business key")
            if dataset == "pricecatcher" and row["date"][:7] != path.stem.removeprefix("pricecatcher_"):
                raise ValueError("Wrong monthly source")
            parts = [canonical(row[key]) for key in digest_columns]
            if dataset == "pricecatcher":
                parts[digest_columns.index("price")] = format(Decimal(str(row["price"])), ".2f")
            digest = hashlib.md5("|".join(parts).encode()).hexdigest()
            digest_sums[0] += int(digest[:15], 16)
            digest_sums[1] += int(digest[-15:], 16)
            count += 1
            chunk.append(row)
            if len(chunk) == 2500:
                submit(pool, chunk, chunk_index)
                chunk = []
                chunk_index += 1
        if chunk:
            submit(pool, chunk, chunk_index)
        while futures:
            finish()
    audit = {"import_id": IMPORT_ID, "dataset_id": dataset, "source_url": url,
             "source_sha256": file_hash, "selection_rule": selection,
             "row_count": count, "rejected_rows": {"empty_business_key": rejected}}
    if not dry_run:
        request(config, "government_data_import_files?on_conflict=import_id,dataset_id,source_sha256",
                [audit], "resolution=merge-duplicates,return=minimal")
    audit.update(file=path.name, source_rows=total, excluded_rows=excluded,
                 digest_columns=digest_columns, digest_sums=list(map(str, digest_sums)),
                 dry_run=dry_run)
    (EVIDENCE / (path.stem + "-import-audit.json")).write_text(json.dumps(audit, indent=2) + "\n")
    print("Prepared" if dry_run else "Imported", path.name, count, "rows;", excluded,
          "excluded;", rejected, "isolated", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dataset", choices=[*SPECS, "statistics", "prices", "all"], default="statistics")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    config = None if args.dry_run else read_values(ROOT / ".env")
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    datasets = list(SPECS) if args.dataset == "all" else list(SPECS)[:-1] if args.dataset == "statistics" else ["pricecatcher"] if args.dataset == "prices" else [args.dataset]
    for dataset in datasets:
        paths = sorted((DOWNLOADS / "pricecatcher").glob("pricecatcher_*.csv")) if dataset == "pricecatcher" else [DOWNLOADS / (dataset + ".csv")]
        if not paths:
            raise RuntimeError("No local source files")
        for path in paths:
            import_file(config, dataset, path, args.dry_run)


if __name__ == "__main__":
    main()
