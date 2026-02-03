# Wrapper to run the Elixir install script from the bucket (avoids quoting issues in manifest)
$scriptPath = Join-Path $env:SCOOP_HOME "buckets\v-sekai-scoop-world\scripts\v_sekai_godot_templates_install.exs"
& elixir $scriptPath
