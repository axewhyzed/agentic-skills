# install.ps1 - Cross-Platform Skill Installer for Windows
param (
    [string]$Target = "global" # Options: 'global' or 'workspace'
)

$ErrorActionPreference = "Stop"

$sourceDir = Join-Path $PSScriptRoot "..\skills"
if (-not (Test-Path $sourceDir)) {
    $sourceDir = Join-Path $PSScriptRoot "..\.agents\skills"
}

if ($Target -eq "global") {
    $destDir = [System.IO.Path]::Combine($env:USERPROFILE, ".gemini", "config", "skills")
    Write-Host "Installing Agentic Skills globally into $destDir..." -ForegroundColor Cyan
} else {
    $destDir = Join-Path (Get-Location) ".agents\skills"
    Write-Host "Installing Agentic Skills into current workspace: $destDir..." -ForegroundColor Cyan
}

if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}

Copy-Item -Recurse -Force -Path (Join-Path $sourceDir "*") -Destination $destDir

Write-Host "Successfully installed skills:" -ForegroundColor Green
Get-ChildItem -Directory -Path $destDir | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Yellow
}
