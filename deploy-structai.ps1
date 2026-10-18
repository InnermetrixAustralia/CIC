# E:\work\TQ\Repos\InnermetrixAustralia-CIC\deploy-structai.ps1
# StructAI-App Deployment Script
#
# Safe version: stops at the first failure and never wipes the GitHub Pages folder
# unless the build succeeded and produced a complete output.

$ErrorActionPreference = "Stop"

$appName = "StructAI-App"
$id = "Innermetrix-CIC"
$accountName = "InnermetrixAustralia"
$reposName = "CIC"

# Paths
$srcRoot = "E:\work\TQ\Kepler\StructAI\StructAI.App"
$reposRoot = "E:\work\TQ\Repos"
$tempRoot = "E:\work\TQ\TempRepos"

$publish = "$tempRoot\$id\wwwroot"
$deploy = "$srcRoot\wwwroot.deploy.$id"
$docs = "$reposRoot\$accountName-$reposName\docs"

try {
    # dotnet publish must run in the project folder, wherever this script was started from
    Set-Location $srcRoot

    Write-Host "=== Building StructAI (Release) ==="
    dotnet publish -c Release -p:PublishProfile=$id
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet publish failed (exit code $LASTEXITCODE). Nothing was deployed."
    }

    foreach ($required in @("index.html", "_framework", "css\app.css", "js\structAI.js")) {
        if (-not (Test-Path (Join-Path $publish $required))) {
            throw "Publish output is incomplete: '$required' not found in $publish. Nothing was deployed."
        }
    }

    Write-Host "=== Cleaning old GitHub Pages deployment ==="
    Remove-Item "$docs\*" -Recurse -Force

    Write-Host "=== Copying published build ==="
    robocopy $publish $docs /MIR
    if ($LASTEXITCODE -ge 8) { throw "robocopy of the published build failed (exit code $LASTEXITCODE)." }

    Write-Host "=== Overlaying deploy-specific files ==="
    robocopy $deploy $docs /E /IS /IT
    if ($LASTEXITCODE -ge 8) { throw "robocopy of the deploy overlay failed (exit code $LASTEXITCODE)." }

    foreach ($required in @("index.html", ".nojekyll", "_framework", "css\app.css")) {
        if (-not (Test-Path (Join-Path $docs $required))) {
            throw "Deployment folder is incomplete: '$required' not found in $docs. Nothing was committed."
        }
    }

    Write-Host "=== Cleaning temporary publish folder ==="
    Remove-Item "$tempRoot\$id" -Recurse -Force

    Write-Host "=== Committing and pushing to GitHub ==="
    Set-Location "$reposRoot\$accountName-$reposName"
    git add .
    git commit -m "Auto-deploy $appName ($id)"
    git push

    Write-Host "=== Deployment complete ==="
    Write-Host "Open: https://$accountName.github.io/$reposName"
}
finally {
    Set-Location $srcRoot
}