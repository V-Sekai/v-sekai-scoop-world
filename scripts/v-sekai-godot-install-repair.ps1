# Repair: finish extraction (zip then tpz then version.txt) and move to versioned subdir.
# Run this if the main installer was interrupted and content is still under .tmp_*.
$base_templates_dir = "$env:APPDATA\Godot\export_templates"
$temp_dirs = Get-ChildItem $base_templates_dir -Directory -Filter '.tmp_*' -ErrorAction SilentlyContinue
if (-not $temp_dirs) {
    Write-Host 'No .tmp_* folder found under export_templates. Nothing to repair.'
    exit 0
}
foreach ($temp_dir in $temp_dirs) {
    $extract_temp = Join-Path $temp_dir.FullName 'extract'
    if (-not (Test-Path $extract_temp)) {
        Write-Host "Skipping $($temp_dir.Name): no extract subfolder."
        continue
    }
    # Extract any remaining .tpz (same order as install: zip then tpz then version.txt)
    do {
        $tpz_list = Get-ChildItem $extract_temp -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue
        foreach ($tpz in $tpz_list) {
            Write-Host "Extracting tpz: $($tpz.Name)"
            & 7z x $tpz.FullName "-o$extract_temp" -y | Out-Null
            if ($LASTEXITCODE -ne 0) { Write-Warning "tpz extraction failed: $($tpz.FullName)"; continue }
            Remove-Item $tpz.FullName -Force
        }
    } while ((Get-ChildItem $extract_temp -Filter *.tpz -Recurse -File -ErrorAction SilentlyContinue))
    $version_file = Get-ChildItem $extract_temp -Filter version.txt -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $version_file) {
        Write-Host "Skipping $($temp_dir.Name): version.txt not found under extract (extract .tpz first)."
        continue
    }
    $template_version = (Get-Content $version_file.FullName -Raw).Trim()
    $templates_dir = Join-Path $base_templates_dir $template_version
    Write-Host "Moving extract -> $template_version"
    New-Item -ItemType Directory -Path $templates_dir -Force | Out-Null
    Get-ChildItem $extract_temp -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
        $target = $_.FullName.Replace($extract_temp, $templates_dir)
        $target_dir = Split-Path $target
        if (-not (Test-Path $target_dir)) { New-Item -ItemType Directory -Path $target_dir -Force | Out-Null }
        Move-Item $_.FullName $target -Force
    }
    $version_txt_path = Join-Path $templates_dir 'version.txt'
    if (-not (Test-Path $version_txt_path)) { Set-Content $version_txt_path $template_version }
    Write-Host "Removing temp folder $($temp_dir.Name)"
    Remove-Item $temp_dir.FullName -Recurse -Force
    Write-Host "Done. Templates are now under $templates_dir"
}
