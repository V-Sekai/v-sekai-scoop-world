# Contributing to V-Sekai Scoop Bucket

This bucket (scoop-world) provides Windows manifests for V-Sekai tools and applications. Many of the same apps are also published via the [homebrew-world](https://github.com/V-Sekai/homebrew-world) tap for macOS.

## Shared process

For release workflow, getting hashes from GitHub, version bumps, and when to update Godot vs. other apps, see:

**[Contributing to V-Sekai Homebrew (and related packaging)](https://github.com/V-Sekai/homebrew-world/blob/main/CONTRIBUTING.md)** — in the homebrew-world repo.

We use `gh release view <tag> --repo <org/repo> --json assets` to get SHA256 digests instead of downloading files locally.

## Scoop-specific

- **Manifest format**: One JSON file per app (e.g. `v-sekai-godot.json`, `tool-model-explorer.json`). Fields: `version`, `url`, `hash`, `bin`, `description`, `homepage`, `license`.
- **Hash**: Use the lowercase hex from the release asset `digest` (SHA256). Required when the download URL changes.
- **Bin**: If the executable name changes in a new release, update the first element of the `bin` array; keep the alias (second element) stable when possible.
- **Godot editor** (`v-sekai-godot.json`): Editor zip only; no installer script.
- **Godot templates** (`v-sekai-godot-templates.json`): The installer script downloads templates and symbols; update `release_version` and the three SHA256 variables in `scripts/v_sekai_godot_templates_install.exs` when upgrading the release.

Detailed steps: [Update Scoop Manifest Workflow](.clinerules/workflows/update-scoop-manifest.md).
