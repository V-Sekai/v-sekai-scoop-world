# Update Scoop Manifest Workflow

This workflow guides you through updating an existing application manifest in the scoop-world bucket.

## When to Update

- New version release of the application
- URL change for the download location
- Metadata updates (description, homepage, license)
- Bin alias changes

## Steps

### 1. Identify Changes Needed

Determine what needs to be updated:

- Version number
- Download URL
- Hash (always required when URL changes)
- Bin configuration
- Other metadata

### 2. Update Version and URL

Edit the manifest file (`<app-name>.json`):

```json
{
    "version": "NEW_VERSION",
    "url": "https://github.com/owner/repo/releases/download/NEW_TAG/file.exe",
    ...
}
```

### 3. Recalculate Hash

When the URL changes, always recalculate the SHA256 hash:

```powershell
Invoke-WebRequest -Uri 'NEW_DOWNLOAD_URL' -OutFile temp.exe; (Get-FileHash temp.exe -Algorithm SHA256).Hash; Remove-Item temp.exe
```

Update the `hash` field with the new value.

### 4. Update Bin Alias (if needed)

If the executable filename changed in the new release:

```json
"bin": [["new-executable-name.exe", "vsekai_alias"]]
```

Keep the alias consistent unless there's a good reason to change it.

### 5. Update README (if needed)

Only update README.md if:

- The description changed significantly
- The command alias changed
- Additional usage information is needed

### 6. Test the Update

Test the updated manifest:

```bash
# Uninstall old version
scoop uninstall app-name

# Install new version
scoop install .\app-name.json

# Verify it works
vsekai_alias --version
```

### 7. Commit Changes

```bash
git add app-name.json
git commit -m "Update app-name to version X.Y.Z"
```

## Example

Updating v-sekai-godot from v1.0 to v2.0:

1. **Updated version**: `"version": "2.0"`
2. **Updated URL**: New release tag in URL
3. **Recalculated hash**: Downloaded new exe and got new hash
4. **Kept bin alias**: `vsekai_editor` remained the same
5. **Tested**: Uninstalled v1.0, installed v2.0, verified command
6. **Committed**: `git commit -m "Update v-sekai-godot to 2.0"`

## Common Issues

- **Forgot to update hash**: Scoop will fail to install with hash mismatch error
- **Wrong version in URL**: Ensure the version in `version` field matches the tag in `url`
- **Broke existing alias**: Keep bin aliases consistent to avoid breaking user scripts

## Checklist

- [ ] Version field updated
- [ ] URL points to new release
- [ ] Hash recalculated and updated
- [ ] Bin configuration verified
- [ ] Tested installation locally
- [ ] README updated (if needed)
- [ ] Changes committed
