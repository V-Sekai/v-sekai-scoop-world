# Repair: complete extraction from existing .tmp_* folder and move to versioned subdir.
# Run when v-sekai-godot-templates install left files in .tmp_* without extracting.
# Usage: run from any dir; uses %APPDATA%\Godot\export_templates\.tmp_latest.v-sekai-editor-280
$base_templates_dir = "$env:APPDATA\Godot\export_templates"
$release_version = 'latest.v-sekai-editor-280'
$temp_dir = "$base_templates_dir\.tmp_$release_version"

if (-not (Test-Path $temp_dir)) {
    Write-Host "Temp folder not found: $temp_dir"; exit 1
}

$extract_temp = Join-Path $temp_dir 'extract'
$templates_tpz = "$temp_dir\v-sekai-godot-templates.tpz"
$symbols_001 = "$temp_dir\v-sekai-godot-templates-symbols.zip.001"
$symbols_002 = "$temp_dir\v-sekai-godot-templates-symbols.zip.002"
$symbols_combined = "$temp_dir\v-sekai-godot-templates-symbols.zip"

New-Item -ItemType Directory -Path $extract_temp -Force | Out-Null

if (Test-Path $templates_tpz) {
    Write-Host 'Extracting templates tpz...'
    & 7z x $templates_tpz "-o$extract_temp" -y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Templates tpz extraction failed' }
} else {
    throw "Templates tpz not found: $templates_tpz"
}

if (-not (Test-Path $symbols_combined) -and (Test-Path $symbols_001) -and (Test-Path $symbols_002)) {
    Write-Host 'Merging symbols zip parts...'
    $outStream = [System.IO.File]::Create($symbols_combined)
    try {
        $in1 = [System.IO.File]::OpenRead($symbols_001)
        try { $in1.CopyTo($outStream) } finally { $in1.Close() }
        $in2 = [System.IO.File]::OpenRead($symbols_002)
        try { $in2.CopyTo($outStream) } finally { $in2.Close() }
    } finally { $outStream.Close() }
}
if (Test-Path $symbols_combined) {
    Write-Host 'Extracting symbols zip...'
    & 7z x $symbols_combined "-o$extract_temp" -y | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Symbols extraction failed' }
}

do {
    $tpz_list = Get-ChildItem $extract_temp -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue
    foreach ($tpz in $tpz_list) {
        Write-Host "Extracting tpz: $($tpz.Name)"
        & 7z x $tpz.FullName "-o$extract_temp" -y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "tpz extraction failed: $($tpz.FullName)" }
        Remove-Item $tpz.FullName -Force
    }
} while ((Get-ChildItem $extract_temp -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue))

$version_file = Get-ChildItem $extract_temp -Filter version.txt -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $version_file) { throw 'version.txt not found under extract. Extraction may be incomplete.' }
$template_version = (Get-Content $version_file.FullName -Raw).Trim()
Write-Host "Version from version.txt: $template_version"

$templates_dir = Join-Path $base_templates_dir $template_version
New-Item -ItemType Directory -Path $templates_dir -Force | Out-Null
Write-Host "Moving extract -> $templates_dir"
Get-ChildItem $extract_temp -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
    $target = $_.FullName.Replace($extract_temp, $templates_dir)
    $target_dir = Split-Path $target
    if (-not (Test-Path $target_dir)) { New-Item -ItemType Directory -Path $target_dir -Force | Out-Null }
    Move-Item $_.FullName $target -Force
}

do {
    $tpz_list = Get-ChildItem $templates_dir -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue
    foreach ($tpz in $tpz_list) {
        Write-Host "Extracting tpz into version folder: $($tpz.Name)"
        & 7z x $tpz.FullName "-o$templates_dir" -y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "tpz extraction failed: $($tpz.FullName)" }
        Remove-Item $tpz.FullName -Force
    }
} while ((Get-ChildItem $templates_dir -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue))

$version_txt_path = Join-Path $templates_dir 'version.txt'
if (-not (Test-Path $version_txt_path)) { Set-Content $version_txt_path $template_version }

Write-Host "Removing temp folder..."
Remove-Item $temp_dir -Recurse -Force
Write-Host "Done. Templates are at: $templates_dir"
