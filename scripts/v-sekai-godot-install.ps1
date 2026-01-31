# Install export templates for V-Sekai Godot (run by Scoop installer)
$release_version = 'latest.v-sekai-editor-279'
$base_templates_dir = "$env:APPDATA\Godot\export_templates"
$temp_dir = "$base_templates_dir\.tmp_$release_version"
New-Item -ItemType Directory -Path $temp_dir -Force | Out-Null

$templates_url = "https://github.com/V-Sekai/world-godot/releases/download/$release_version/v-sekai-godot-templates.zip.001"
$templates_sha256 = 'BFD7A64A0E1F477F642A90C111AF73425AB172F7C40ABE5109935B6C73904C79'
$templates_file_001 = "$temp_dir\v-sekai-godot-templates.zip.001"
Invoke-WebRequest -Uri $templates_url -OutFile $templates_file_001
$hash = Get-FileHash $templates_file_001 -Algorithm SHA256
if ($hash.Hash -ne $templates_sha256) { throw 'Templates hash mismatch' }
$templates_combined = "$temp_dir\v-sekai-godot-templates.zip"
Copy-Item $templates_file_001 $templates_combined

$symbols_url_001 = "https://github.com/V-Sekai/world-godot/releases/download/$release_version/v-sekai-godot-templates-symbols.zip.001"
$symbols_sha256_001 = 'E3FC838F3F8A8520EE2346FBE417F85F748699A0B38F062E4881FB2003BAE5CA'
$symbols_file_001 = "$temp_dir\v-sekai-godot-templates-symbols.zip.001"
Invoke-WebRequest -Uri $symbols_url_001 -OutFile $symbols_file_001
$hash = Get-FileHash $symbols_file_001 -Algorithm SHA256
if ($hash.Hash -ne $symbols_sha256_001) { throw 'Symbols 001 hash mismatch' }

$symbols_url_002 = "https://github.com/V-Sekai/world-godot/releases/download/$release_version/v-sekai-godot-templates-symbols.zip.002"
$symbols_sha256_002 = '5DF25D79D4C862E314C9E78101A2489F88DEEC733FE76C546EB2DDC151CBBD37'
$symbols_file_002 = "$temp_dir\v-sekai-godot-templates-symbols.zip.002"
Invoke-WebRequest -Uri $symbols_url_002 -OutFile $symbols_file_002
$hash = Get-FileHash $symbols_file_002 -Algorithm SHA256
if ($hash.Hash -ne $symbols_sha256_002) { throw 'Symbols 002 hash mismatch' }

$symbols_combined = "$temp_dir\v-sekai-godot-templates-symbols.zip"
$content1 = [System.IO.File]::ReadAllBytes($symbols_file_001)
$content2 = [System.IO.File]::ReadAllBytes($symbols_file_002)
$combined = $content1 + $content2
[System.IO.File]::WriteAllBytes($symbols_combined, $combined)

$extract_temp = "$temp_dir\extract"
New-Item -ItemType Directory -Path $extract_temp -Force | Out-Null
Expand-Archive -Path $templates_combined -DestinationPath $extract_temp
Expand-Archive -Path $symbols_combined -DestinationPath $extract_temp

$tpz = Get-ChildItem $extract_temp -Filter *.tpz -Recurse | Select-Object -First 1
if ($tpz) { Expand-Archive -Path $tpz.FullName -DestinationPath $extract_temp }

$version_file = Get-ChildItem $extract_temp -Filter version.txt -Recurse | Select-Object -First 1
if ($version_file) {
    $template_version = (Get-Content $version_file.FullName -Raw).Trim()
} else {
    throw 'Could not find version.txt'
}

$templates_dir = "$base_templates_dir\$template_version"
New-Item -ItemType Directory -Path $templates_dir -Force | Out-Null
Get-ChildItem $extract_temp -Recurse | Where-Object { -not $_.PSIsContainer } | ForEach-Object {
    $target = $_.FullName.Replace($extract_temp, $templates_dir)
    $target_dir = Split-Path $target
    New-Item -ItemType Directory -Path $target_dir -Force | Out-Null
    Move-Item $_.FullName $target -Force
}

$version_txt_path = "$templates_dir\version.txt"
if (-not (Test-Path $version_txt_path)) { Set-Content $version_txt_path $template_version }
Remove-Item $temp_dir -Recurse -Force
