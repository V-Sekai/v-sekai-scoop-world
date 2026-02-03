# Install export templates for V-Sekai Godot (run by Scoop installer for v-sekai-godot-templates)
# Run with: elixir v_sekai_godot_templates_install.exs
# Uses curl for downloads. If v-sekai-godot-templates.tpz exists in script dir (Scoop cache), use it.

script_dir = __ENV__.file |> Path.dirname() |> Path.expand()
release_version = "latest.v-sekai-editor-280"
base_url = "https://github.com/V-Sekai/world-godot/releases/download/#{release_version}"
base_templates_dir = Path.join(System.get_env("APPDATA", ""), "Godot/export_templates")
temp_dir = Path.join(base_templates_dir, ".tmp_#{release_version}")

templates_tpz_sha256 = "9BBEA79A650EDAFAA1574FA5B942DB05DCE2B74D972EDC9D8242AF50A13C2A43"

defmodule Install do
  def run_7z(archive, out_dir) do
    {_, status} = System.cmd("7z", ["x", archive, "-o#{out_dir}", "-y"], stderr_to_stdout: true)
    status
  end

  def download(url, path) do
    {_, status} = System.cmd("curl", ["-L", "-o", path, url], stderr_to_stdout: true)
    status
  end

  def file_sha256_win(path) do
    {output, 0} = System.cmd("certutil", ["-hashfile", path, "SHA256"], stderr_to_stdout: true)
    output
    |> String.split("\n")
    |> Enum.find_value(fn line ->
      trimmed = String.trim(line)
      if String.match?(trimmed, ~r/^[a-fA-F0-9]{64}$/), do: String.upcase(trimmed)
    end)
  end

  def list_files_r(dir) do
    if File.exists?(dir) do
      File.ls!(dir)
      |> Enum.flat_map(fn name ->
        path = Path.join(dir, name)
        if File.dir?(path), do: list_files_r(path), else: [path]
      end)
    else
      []
    end
  end

  def extract_tpz_loop(extract_dir) do
    tpz_files = Path.wildcard(Path.join(extract_dir, "**/*.tpz"))
    if tpz_files == [] do
      :ok
    else
      for tpz <- tpz_files do
        run_7z(tpz, extract_dir)
        File.rm!(tpz)
      end
      extract_tpz_loop(extract_dir)
    end
  end

  def find_version_txt(dir) do
    Path.wildcard(Path.join(dir, "**/version.txt")) |> List.first()
  end

  def move_all_files(src_dir, dest_dir) do
    files = list_files_r(src_dir)
    for src <- files do
      rel = Path.relative_to(src, src_dir)
      target = Path.join(dest_dir, rel)
      File.mkdir_p!(Path.dirname(target))
      File.rename(src, target)
    end
  end
end

File.mkdir_p!(temp_dir)

tpz_path = Path.join(temp_dir, "v-sekai-godot-templates.tpz")
cached_tpz = Path.join(script_dir, "v-sekai-godot-templates.tpz")

if File.exists?(cached_tpz) do
  File.cp!(cached_tpz, tpz_path)
  hash = Install.file_sha256_win(tpz_path)
  if hash != templates_tpz_sha256, do: raise("Templates tpz hash mismatch (cached file)")
else
  if Install.download("#{base_url}/v-sekai-godot-templates.tpz", tpz_path) != 0,
    do: raise("Templates tpz download failed")
  hash = Install.file_sha256_win(tpz_path)
  if hash != templates_tpz_sha256, do: raise("Templates tpz hash mismatch")
end

extract_temp = Path.join(temp_dir, "extract")
File.mkdir_p!(extract_temp)

if Install.run_7z(tpz_path, extract_temp) != 0, do: raise("Templates tpz extraction failed")

Install.extract_tpz_loop(extract_temp)

version_file = Install.find_version_txt(extract_temp)
if version_file == nil, do: raise("Could not find version.txt")

template_version = version_file |> File.read!() |> String.trim()
templates_dir = Path.join(base_templates_dir, template_version)
File.mkdir_p!(templates_dir)

Install.move_all_files(extract_temp, templates_dir)
Install.extract_tpz_loop(templates_dir)

version_txt_path = Path.join(templates_dir, "version.txt")
unless File.exists?(version_txt_path), do: File.write!(version_txt_path, template_version)

File.rm_rf(temp_dir)
