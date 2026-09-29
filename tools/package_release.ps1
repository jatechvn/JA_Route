# tools/package_release.ps1
param(
    [string]$ProjectRoot = (Split-Path $PSScriptRoot -Parent),
    [string]$Version = '1.3.0'
)
$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$releaseDir = Join-Path $projectRoot 'build/windows/x64/runner/Release'
$distDir = Join-Path $projectRoot 'dist'
$packageName = "JA_Route_v${Version}_Windows_x64"
$zipName = "$packageName.zip"

Write-Host "[1/4] Refreshing unpacked portable application in dist/..."
if (!(Test-Path $distDir)) { New-Item -ItemType Directory -Path $distDir -Force | Out-Null }

# Clean previous zip archives and checksums in dist/
Get-ChildItem -Path $distDir -Filter "*.zip" | Remove-Item -Force
Get-ChildItem -Path $distDir -Filter "SHA256SUMS.txt" | Remove-Item -Force

# Copy core executable and all DLL dependencies
Copy-Item (Join-Path $releaseDir 'ja_route.exe') -Destination $distDir -Force
Get-ChildItem -Path $releaseDir -Filter "*.dll" -File | Copy-Item -Destination $distDir -Force
if (Test-Path (Join-Path $releaseDir 'native_assets.json')) {
    Copy-Item (Join-Path $releaseDir 'native_assets.json') -Destination $distDir -Force
}

# Refresh data folder
$dataDest = Join-Path $distDir 'data'
if (Test-Path $dataDest) { Remove-Item $dataDest -Recurse -Force }
Copy-Item (Join-Path $releaseDir 'data') -Destination $distDir -Recurse -Force

# Copy scripts and documentation
$docFiles = @('ABOUT.txt', 'README.md', 'CHANGELOG.md', 'USERGUIDE.md', 'RELEASE_NOTES.md', 'LICENSE', 'install.bat', 'uninstall.bat', 'uninstall.ps1', 'debug.bat')
foreach ($f in $docFiles) {
    $src = Join-Path $projectRoot $f
    if (Test-Path $src) { Copy-Item $src -Destination $distDir -Force }
}

if (Test-Path (Join-Path $projectRoot 'i18n')) {
    $i18nDest = Join-Path $distDir 'i18n'
    if (Test-Path $i18nDest) { Remove-Item $i18nDest -Recurse -Force }
    Copy-Item (Join-Path $projectRoot 'i18n') -Destination $distDir -Recurse -Force
}

if (Test-Path (Join-Path $projectRoot 'assets')) {
    $assetsDest = Join-Path $distDir 'assets'
    if (Test-Path $assetsDest) { Remove-Item $assetsDest -Recurse -Force }
    Copy-Item (Join-Path $projectRoot 'assets') -Destination $distDir -Recurse -Force
}

Write-Host "[2/4] Packaging $zipName with nested parent folder..."
$distPack = Join-Path $projectRoot 'dist_pack'
if (Test-Path $distPack) { Remove-Item $distPack -Recurse -Force }
$nestedFolder = Join-Path $distPack $packageName
New-Item -ItemType Directory -Path $nestedFolder -Force | Out-Null

Get-ChildItem -Path $distDir -Exclude "*.zip", "SHA256SUMS.txt" | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $nestedFolder -Recurse -Force
}

$zipPath = Join-Path $distDir $zipName
Compress-Archive -Path $nestedFolder -DestinationPath $zipPath -Force
Remove-Item $distPack -Recurse -Force

Write-Host "[3/4] Generating cryptographic SHA256 checksum..."
$hash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
Set-Content -Path (Join-Path $distDir 'SHA256SUMS.txt') -Value "$hash  $zipName" -Encoding ASCII

Write-Host "Created: $zipPath"
Write-Host "SHA256 : $hash"

Write-Host "[4/4] Synchronizing with enterprise LAN OTA update server..."
$otaDest = "\\10.81.141.226\temp\FBT\JA_PROJECT\JA_Update\JA_Route"
if (Test-Path $otaDest) {
    Copy-Item $zipPath -Destination $otaDest -Force
    Copy-Item (Join-Path $distDir 'SHA256SUMS.txt') -Destination $otaDest -Force
    $notes = "JA_Route v1.3.0: Tich hop Official App Icon, dong bo da ngon ngu toan dien VI/EN/ZH, toi uu bang dinh tuyen IPv4 toan chieu ngang va nang cap Droplist Bento Liquid Glass."
    $versionJson = "{`n  `"version`": `"$Version`",`n  `"fileName`": `"$zipName`",`n  `"sha256`": `"$hash`",`n  `"releaseNotes`": `"$notes`"`n}"
    [System.IO.File]::WriteAllText((Join-Path $otaDest 'version.json'), $versionJson, [System.Text.Encoding]::UTF8)
    Write-Host "LAN OTA update deployed successfully to $otaDest"
} else {
    Write-Host "LAN OTA server not accessible. Skipped sync."
}
