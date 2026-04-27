$ErrorActionPreference = "Stop"

$owner = "andrejipa"
$repo = "projetos-cli"
$appName = "CertExpiryMonitor"
$assetName = "CertExpiryMonitorSetup.exe"
$installDir = Join-Path $env:LOCALAPPDATA "Programs\$appName"
$exePath = Join-Path $installDir "$appName.exe"
$tempDir = Join-Path $env:TEMP "$appName-install"
$installerPath = Join-Path $tempDir $assetName

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "Consultando ultima versao no GitHub..."
$release = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/releases/latest" -Headers @{ "User-Agent" = "$appName-installer" }
$asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
if (-not $asset) {
    throw "Asset $assetName nao encontrado na ultima release de $owner/$repo."
}

Write-Host "Baixando $assetName..."
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $installerPath -UseBasicParsing

Write-Host "Fechando versao em execucao, se houver..."
Get-Process -Name $appName -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -eq $exePath } |
    Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "Instalando no usuario atual..."
$process = Start-Process -FilePath $installerPath -ArgumentList "/verysilent /suppressmsgboxes" -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw "Instalador retornou codigo $($process.ExitCode)."
}

if (-not (Test-Path $exePath)) {
    throw "Aplicativo nao encontrado apos instalacao: $exePath"
}

if (-not (Get-Process -Name $appName -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $exePath -ArgumentList "--background"
}

Write-Host "CertExpiryMonitor instalado/atualizado com sucesso."
