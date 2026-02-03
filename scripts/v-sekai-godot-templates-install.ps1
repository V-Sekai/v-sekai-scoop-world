# Install export templates for V-Sekai Godot (run by Scoop installer for v-sekai-godot-templates)
# Use gh release download for assets. If v-sekai-godot-templates.tpz exists in app dir (Scoop cache), use it.
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

$release_version = 'latest.v-sekai-editor-280'
$repo = 'V-Sekai/world-godot'
$base_templates_dir = "$env:APPDATA\Godot\export_templates"
$temp_dir = "$base_templates_dir\.tmp_$release_version"
New-Item -ItemType Directory -Path $temp_dir -Force | Out-Null

$templates_tpz_sha256 = '9BBEA79A650EDAFAA1574FA5B942DB05DCE2B74D972EDC9D8242AF50A13C2A43'
$cached_tpz = Join-Path $scriptDir 'v-sekai-godot-templates.tpz'
if (Test-Path $cached_tpz) {
    Copy-Item $cached_tpz $temp_dir
    $tpz_path = "$temp_dir\v-sekai-godot-templates.tpz"
    $hash = Get-FileHash $tpz_path -Algorithm SHA256
    if ($hash.Hash -ne $templates_tpz_sha256) { throw 'Templates tpz hash mismatch (cached file)' }
} else {
    gh release download $release_version --repo $repo -D $temp_dir --pattern 'v-sekai-godot-templates.tpz'
    if ($LASTEXITCODE -ne 0) { throw 'Templates tpz download failed' }
    $tpz_path = "$temp_dir\v-sekai-godot-templates.tpz"
    $hash = Get-FileHash $tpz_path -Algorithm SHA256
    if ($hash.Hash -ne $templates_tpz_sha256) { throw 'Templates tpz hash mismatch' }
}

$symbols_sha256_001 = '6662AF45769AAA1ED463F7C2CF58E593F0C2C5AE5FB824AE68B81FA5497B2436'
$symbols_sha256_002 = 'A7ABD1E91E74EAA3767DBE98577DFAFB1863ECE458B11E4361E0221D081E3C26'
gh release download $release_version --repo $repo -D $temp_dir --pattern 'v-sekai-godot-templates-symbols.zip.001' --pattern 'v-sekai-godot-templates-symbols.zip.002'
if ($LASTEXITCODE -ne 0) { throw 'Symbols download failed' }
$symbols_file_001 = "$temp_dir\v-sekai-godot-templates-symbols.zip.001"
$symbols_file_002 = "$temp_dir\v-sekai-godot-templates-symbols.zip.002"
$hash = Get-FileHash $symbols_file_001 -Algorithm SHA256
if ($hash.Hash -ne $symbols_sha256_001) { throw 'Symbols 001 hash mismatch' }
$hash = Get-FileHash $symbols_file_002 -Algorithm SHA256
if ($hash.Hash -ne $symbols_sha256_002) { throw 'Symbols 002 hash mismatch' }

$symbols_combined = "$temp_dir\v-sekai-godot-templates-symbols.zip"
$outStream = [System.IO.File]::Create($symbols_combined)
try {
    $in1 = [System.IO.File]::OpenRead($symbols_file_001)
    try { $in1.CopyTo($outStream) } finally { $in1.Close() }
    $in2 = [System.IO.File]::OpenRead($symbols_file_002)
    try { $in2.CopyTo($outStream) } finally { $in2.Close() }
} finally { $outStream.Close() }

$extract_temp = "$temp_dir\extract"
New-Item -ItemType Directory -Path $extract_temp -Force | Out-Null

& 7z x $tpz_path "-o$extract_temp" -y | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Templates tpz extraction failed' }

& 7z x $symbols_combined "-o$extract_temp" -y | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Symbols zip extraction failed' }

# Always extract all .tpz in extract_temp (repeat until none left)
do {
    $tpz_list = Get-ChildItem $extract_temp -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue
    foreach ($tpz in $tpz_list) {
        & 7z x $tpz.FullName "-o$extract_temp" -y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "tpz extraction failed: $($tpz.FullName)" }
        Remove-Item $tpz.FullName -Force
    }
} while ((Get-ChildItem $extract_temp -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue))

$version_file = Get-ChildItem $extract_temp -Filter version.txt -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $version_file) { throw 'Could not find version.txt' }
$template_version = (Get-Content $version_file.FullName -Raw).Trim()

# Target folder is named from version.txt so Godot finds templates by version
$templates_dir = "$base_templates_dir\$template_version"
New-Item -ItemType Directory -Path $templates_dir -Force | Out-Null
Get-ChildItem $extract_temp -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
    $target = $_.FullName.Replace($extract_temp, $templates_dir)
    $target_dir = Split-Path $target
    New-Item -ItemType Directory -Path $target_dir -Force | Out-Null
    Move-Item $_.FullName $target -Force
}

# Extract any .tpz into the version-named folder (repeat until none left)
do {
    $tpz_list = Get-ChildItem $templates_dir -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue
    foreach ($tpz in $tpz_list) {
        & 7z x $tpz.FullName "-o$templates_dir" -y | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "tpz extraction failed: $($tpz.FullName)" }
        Remove-Item $tpz.FullName -Force
    }
} while ((Get-ChildItem $templates_dir -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue))

$version_txt_path = "$templates_dir\version.txt"
if (-not (Test-Path $version_txt_path)) { Set-Content $version_txt_path $template_version }
Remove-Item $temp_dir -Recurse -Force
