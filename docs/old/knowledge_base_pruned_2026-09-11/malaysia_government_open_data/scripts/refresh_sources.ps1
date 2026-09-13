param(
    [switch]$KeepTemporaryClone
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$KnowledgeBaseRoot = Split-Path -Parent $PSScriptRoot
$SourcesDirectory = Join-Path $KnowledgeBaseRoot 'sources'
$MetadataSnapshotDirectory = Join-Path $SourcesDirectory 'catalog_metadata'
$TemporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('mygov-open-data-' + [guid]::NewGuid().ToString('N'))
$MetadataRepository = Join-Path $TemporaryRoot 'datagovmy-meta'

New-Item -ItemType Directory -Path $TemporaryRoot -Force | Out-Null
New-Item -ItemType Directory -Path $MetadataSnapshotDirectory -Force | Out-Null

Invoke-WebRequest -Uri 'https://storage.data.gov.my/metrics/dataset_list.csv' -OutFile (Join-Path $SourcesDirectory 'dataset_list.csv')
git clone --depth 1 --filter=blob:none --sparse https://github.com/data-gov-my/datagovmy-meta.git $MetadataRepository
git -C $MetadataRepository sparse-checkout set data-catalogue

$DatasetIds = (Import-Csv (Join-Path $SourcesDirectory 'dataset_list.csv')).id
foreach ($DatasetId in $DatasetIds) {
    $SourcePath = Join-Path $MetadataRepository ('data-catalogue\' + $DatasetId + '.json')
    if (-not (Test-Path -LiteralPath $SourcePath)) {
        throw "Official metadata is missing for dataset ID: $DatasetId"
    }
    Copy-Item -LiteralPath $SourcePath -Destination (Join-Path $MetadataSnapshotDirectory ($DatasetId + '.json')) -Force
}

Get-ChildItem -LiteralPath $MetadataSnapshotDirectory -Filter '*.json' |
    Where-Object { $_.BaseName -notin $DatasetIds } |
    Remove-Item -Force

$CatalogueMetadata = Get-Content -Raw -Encoding utf8 (Join-Path $MetadataSnapshotDirectory 'datasets.json') | ConvertFrom-Json
$ProvenancePath = Join-Path $SourcesDirectory 'provenance.json'
$Provenance = Get-Content -Raw -Encoding utf8 $ProvenancePath | ConvertFrom-Json
$Provenance.captured_at = (Get-Date).ToString('o')
$Provenance.dataset_list.sha256 = (Get-FileHash -Algorithm SHA256 (Join-Path $SourcesDirectory 'dataset_list.csv')).Hash
$Provenance.dataset_list.data_as_of = $CatalogueMetadata.data_as_of
$Provenance.dataset_list.page_last_updated = $CatalogueMetadata.last_updated
$Provenance.datagovmy_meta.commit = (git -C $MetadataRepository rev-parse HEAD).Trim()
$Provenance.datagovmy_meta.commit_time = (git -C $MetadataRepository log -1 --format='%cI').Trim()
$Provenance | ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 $ProvenancePath

Write-Warning 'Realtime API resources are generated from the pinned developer-documentation commit. Review current official GTFS and Weather documentation before changing that pinned commit.'
node (Join-Path $PSScriptRoot 'build.mjs')
node (Join-Path $PSScriptRoot 'validate.mjs')

if (-not $KeepTemporaryClone) {
    Remove-Item -LiteralPath $TemporaryRoot -Recurse -Force
}
