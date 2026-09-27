# E:\work\TQ\Repos\InnermetrixAustralia-CIC\deploy-structai.ps1
# StructAI-App Deployment Script

$appName     = "StructAI-App"
$id          = "Innermetrix-CIC"
$accountName = "InnermetrixAustralia"
$reposName   = "CIC"

# Paths
$srcRoot   = "E:\work\TQ\Kepler\StructAI\StructAI.App"
$reposRoot = "E:\work\TQ\Repos"

$deploy  = "$srcRoot\wwwroot.deploy.$id"

$publish = "$reposRoot\$accountName-$reposName\wwwroot"
$docs    = "$reposRoot\$accountName-$reposName\docs"

Write-Host "=== Building StructAI (Release) ==="
dotnet publish -c Release -p:PublishProfile=$id

Write-Host "=== Cleaning old GitHub Pages deployment ==="
Remove-Item "$docs\*" -Recurse -Force

Write-Host "=== Copying published build ==="
robocopy $publish $docs /MIR

Write-Host "=== Overlaying deploy-specific files ==="
robocopy $deploy $docs /E

Write-Host "=== Committing and pushing to GitHub ==="
cd "$reposRoot\$accountName-$reposName"
git add .
git commit -m "Auto-deploy $appName ($id)"
git push

cd "$srcRoot"

Write-Host "=== Deployment complete ==="
Write-Host "Open: https://$accountName.github.io/$reposName"
