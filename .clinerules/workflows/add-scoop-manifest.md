# Add Scoop Manifest Workflow

This workflow guides you through adding a new application to the scoop-world bucket.

## Prerequisites

- Application download URL from GitHub releases or other source
- Basic information about the application (name, description, license)

## Steps

### 1. Create Manifest File

Create a new JSON file named `<app-name>.json` in the root directory with this structure:

```json
{
  "version": "version-string",
  "description": "Brief description of the application",
  "homepage": "https://github.com/owner/repo",
  "license": "MIT",
  "url": "https://github.com/owner/repo/releases/download/tag/file.exe",
  "hash": "",
  "bin": [["actual-filename.exe", "vsekai_alias"]]
}
```

### 2. Calculate SHA256 Hash

Run this PowerShell command to download the file and get its hash:

```powershell
Invoke-WebRequest -Uri 'DOWNLOAD_URL' -OutFile temp.exe; (Get-FileHash temp.exe -Algorithm SHA256).Hash; Remove-Item temp.exe
```

Copy the resulting hash into the manifest's `hash` field.

### 3. Configure Bin Alias

Set up the bin alias following the naming convention:

- Prefix: `vsekai_`
- Suffix: descriptive name (e.g., `editor`, `game`, `builder`)
- Format: `[["actual-executable-name.exe", "vsekai_shortname"]]`

### 4. Update README.md

Add an entry to the Apps section in README.md:

```markdown
- **app-name**: Description of the application
  - Command: `vsekai_alias`
```

### 5. Test Installation

Before committing, test the manifest locally:

```bash
scoop install .\app-name.json
```

Verify the command works:

```bash
vsekai_alias --version
```

### 6. Commit Changes

Commit the manifest and README changes together:

```bash
git add app-name.json README.md
git commit -m "Add app-name manifest"
```

## Example

Adding v-sekai-game:

1. **Created**: `v-sekai-game.json`
2. **Downloaded & hashed**: The Windows .exe file
3. **Set bin alias**: `vsekai_game`
4. **Updated**: README.md with entry and command
5. **Tested**: `scoop install .\v-sekai-game.json`
6. **Verified**: `vsekai_game` command works

## Common Issues

- **Hash mismatch**: Ensure you're downloading the exact same file specified in the URL
- **Bin not found**: Check that the actual filename in `bin` matches the extracted file name
- **Command not found**: The alias name must match what's in the second element of the bin array
