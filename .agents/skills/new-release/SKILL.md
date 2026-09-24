---
name: new-release
description: Skill that automatically reads the RELEASE_NOTES.md file and publishes a release (Draft) to GitHub along with the built zip file. Activates when the user requests creating a release, pushing a release, or running the New Release command.
---

# GitHub Release Automation (`new-release`)

This skill automates the process of publishing a release to GitHub based on the resources prepared by the `dart-build-pro` skill.

## 1. Input Requirements
- A built source file must exist (e.g. `dist\JA_Auto_Git_v1.6.0_Windows_x64.zip`).
- A release notes file (`dist\RELEASE_NOTES.md`) must exist with the format:
  ```text
  TAG=v...
  TITLE=...
  BODY=...
  (Body content below)
  ```

## 2. Execution Process (Script Logic)

To create a release automatically, you can run a PowerShell script that reads the `RELEASE_NOTES.md` file and passes the data into the GitHub CLI command (`gh release create`).

Sample script (`push_release.ps1` or can be typed directly):

```powershell
# 1. Read the contents of the RELEASE_NOTES.md file
$notes = Get-Content -Path "dist\RELEASE_NOTES.md" -Raw

# 2. Extract TAG, TITLE and BODY
$tag = ($notes -match 'TAG=(.*)' | Out-Null; $matches[1]).Trim()
$title = ($notes -match 'TITLE=(.*)' | Out-Null; $matches[1]).Trim()
$body = $notes -replace 'TAG=.*\r?\n', '' -replace 'TITLE=.*\r?\n', '' -replace 'BODY=\r?\n', ''

# Save the BODY temporarily to a file for gh release to read
$body | Out-File -FilePath "dist\TEMP_BODY.md" -Encoding UTF8

# 3. Get the latest zip file in the dist folder
$zipFile = Get-ChildItem -Path "dist" -Filter "*.zip" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($zipFile) {
    # 4. Run the GitHub CLI command to create the release (Draft by default for safety)
    gh release create $tag $zipFile.FullName -t "$title" -F "dist\TEMP_BODY.md" --draft

    # Remove the temporary file
    Remove-Item "dist\TEMP_BODY.md" -Force
    Write-Host "✅ Successfully created GitHub Release (Draft) for $tag!" -ForegroundColor Green
} else {
    Write-Host "❌ No zip file found in dist\" -ForegroundColor Red
}
```

## 3. Safety Notes
- **Draft Mode:** By default, the command always includes the `--draft` flag so the release is not published immediately, allowing the user to preview it on the GitHub web interface and edit it if needed. (Remove `--draft` to publish directly.)
- **GitHub CLI:** Requires the user to have GitHub CLI installed and logged in (`gh auth login`).

---

## Skill Trigger Keywords:
Whenever the user types:
- `/release` or `create release` or `push release` or `new release`
- The AI will automatically activate the `new-release` Skill and run the release-creation script above.
