param(
  [string]$Workspace = "c:/development/coop_commerce",
  [string]$DeviceId = "",
  [string]$EvidenceDir = "evidence"
)

$ErrorActionPreference = "Stop"
Set-Location $Workspace

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
  Write-Error "adb is not installed or not in PATH."
}

$devices = adb devices | Select-String "\tdevice$" | ForEach-Object {
  ($_ -split "\t")[0]
}

if ($DeviceId -eq "") {
  if ($devices.Count -eq 0) {
    Write-Error "No connected Android devices. Connect device and retry."
  }
  $DeviceId = $devices[0]
}

$targetDir = Join-Path $Workspace $EvidenceDir
if (-not (Test-Path $targetDir)) {
  New-Item -ItemType Directory -Path $targetDir | Out-Null
}

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

$shots = @(
  "home_member",
  "nav_categories",
  "nav_messenger",
  "nav_cart",
  "nav_profile",
  "product_detail",
  "settings",
  "seller_home",
  "wholesale_home",
  "admin_home"
)

Write-Host "Connected device: $DeviceId"
Write-Host "Evidence output: $targetDir"
Write-Host ""
Write-Host "For each prompt, navigate the app on device first, then press Enter here to capture."

foreach ($name in $shots) {
  Read-Host "Ready to capture $name. Navigate on device then press Enter"
  $remote = "/sdcard/$name`_$stamp.png"
  $local = Join-Path $targetDir "$name`_$stamp.png"

  adb -s $DeviceId shell screencap -p $remote | Out-Null
  adb -s $DeviceId pull $remote $local | Out-Null
  adb -s $DeviceId shell rm $remote | Out-Null

  Write-Host "Captured: $local"
}

Write-Host ""
Write-Host "Capture session complete."
