# Build-Installer.ps1
# PowerShell script to build MSI installer using WiX Toolset

param(
    [string]$OutputPath = ".\dist",
    [string]$MSIName = "EldenRingSaveBackup.msi",
    [switch]$Clean = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=== Elden Ring Save Backup - MSI Builder ===" -ForegroundColor Green

# Find WiX installation dynamically
$wixPath = $null

# First, try to find from PATH
$candle = Get-Command candle -ErrorAction SilentlyContinue
if ($candle) {
    $wixPath = Split-Path $candle.Source
    Write-Host "Found WiX in PATH at: $wixPath" -ForegroundColor Green
} else {
    # Search for WiX installations in common locations
    $allWixDirs = @()
    if (Test-Path "${env:ProgramFiles(x86)}\WiX Toolset*") {
        $allWixDirs += Get-ChildItem "${env:ProgramFiles(x86)}\WiX Toolset*" -Directory
    }
    if (Test-Path "${env:ProgramFiles}\WiX Toolset*") {
        $allWixDirs += Get-ChildItem "${env:ProgramFiles}\WiX Toolset*" -Directory
    }
    
    $allWixDirs = $allWixDirs | Sort-Object Name -Descending
    
    foreach ($wixDir in $allWixDirs) {
        $binPath = Join-Path $wixDir.FullName "bin"
        if (Test-Path (Join-Path $binPath "candle.exe")) {
            $wixPath = $binPath
            Write-Host "Found WiX installation: $wixPath" -ForegroundColor Green
            break
        }
    }
}

if (-not $wixPath) {
    Write-Host "ERROR: WiX Toolset not found. Please install WiX Toolset v3.11 or later." -ForegroundColor Red
    exit 1
}

Write-Host "Found WiX Toolset at: $wixPath" -ForegroundColor Green

# Set up paths
$candle = Join-Path $wixPath "candle.exe"
$light = Join-Path $wixPath "light.exe"
$wxsFile = "EldenRingSaveBackup.wxs"
$wixObjFile = "EldenRingSaveBackup.wixobj"

# Create output directory
if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    Write-Host "Created output directory: $OutputPath" -ForegroundColor Green
}

# Clean previous build if requested
if ($Clean) {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    if (Test-Path $wixObjFile) { Remove-Item $wixObjFile -Force }
    if (Test-Path (Join-Path $OutputPath $MSIName)) { Remove-Item (Join-Path $OutputPath $MSIName) -Force }
}

# Verify source file exists
if (-not (Test-Path $wxsFile)) {
    Write-Host "ERROR: WiX source file not found: $wxsFile" -ForegroundColor Red
    exit 1
}

# Verify all required files exist
$requiredFiles = @(
    "EldenRingSaveBackup.ps1",
    "config.example.json",
    "languages.json",
    "er.ico",
    "StartEldenRingBackup.bat",
    "StartEldenRingBackup-Console.bat",
    "StartEldenRingBackup.vbs",
    "EldenRingSaveBackup.exe.manifest",
    "README.md",
    "license.rtf"
)

Write-Host "Verifying required files..." -ForegroundColor Yellow
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "ERROR: Required file not found: $file" -ForegroundColor Red
        exit 1
    }
    Write-Host "  ✓ $file" -ForegroundColor Green
}

# Clean user-specific config before building
Write-Host ""
Write-Host "Cleaning user-specific config for deployment..." -ForegroundColor Yellow
if (Test-Path "config.json") {
    try {
        $config = Get-Content "config.json" -Raw | ConvertFrom-Json
        
        # Clear user-specific paths
        $config.GameExecutable = ""
        $config.SaveFilePath = ""
        $config.BackupFolder = ""
        $config.LaunchArguments = ""
        
        # Reset to default values
        $config.IsRunning = $false
        $config.MaxBackups = 50
        
        # Save cleaned config
        $config | ConvertTo-Json -Depth 10 | Set-Content "config.json" -Encoding UTF8
        Write-Host "  ✓ Cleaned user-specific paths from config.json" -ForegroundColor Green
    }
    catch {
        Write-Host "  ⚠ Warning: Could not clean config.json: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✓ No config.json found (using example config)" -ForegroundColor Green
}

# Step 1: Compile WiX source (candle)
Write-Host ""
Write-Host "Step 1: Compiling WiX source..." -ForegroundColor Cyan
$candleArgs = @("-out", $wixObjFile, $wxsFile)
Write-Host "Running: $candle $($candleArgs -join ' ')" -ForegroundColor Yellow

$process = Start-Process -FilePath $candle -ArgumentList $candleArgs -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) {
    Write-Host "ERROR: Candle compilation failed with exit code $($process.ExitCode)" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $wixObjFile)) {
    Write-Host "ERROR: Candle compilation failed - no .wixobj file created" -ForegroundColor Red
    exit 1
}
Write-Host "✓ WiX source compiled successfully" -ForegroundColor Green

# Step 2: Link MSI (light)
Write-Host ""
Write-Host "Step 2: Linking MSI..." -ForegroundColor Cyan
$msiPath = Join-Path $OutputPath $MSIName
$lightArgs = @("-out", $msiPath, $wixObjFile, "-ext", "WixUIExtension")
Write-Host "Running: $light $($lightArgs -join ' ')" -ForegroundColor Yellow

$process = Start-Process -FilePath $light -ArgumentList $lightArgs -Wait -PassThru -NoNewWindow
if ($process.ExitCode -ne 0) {
    Write-Host "ERROR: Light linking failed with exit code $($process.ExitCode)" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $msiPath)) {
    Write-Host "ERROR: Light linking failed - no MSI file created" -ForegroundColor Red
    exit 1
}

# Get MSI file info
$msiInfo = Get-Item $msiPath
$msiSizeKB = [math]::Round($msiInfo.Length / 1KB, 2)

Write-Host ""
Write-Host "=== BUILD SUCCESSFUL ===" -ForegroundColor Green
Write-Host "MSI created: $msiPath" -ForegroundColor Green
Write-Host "File size: $msiSizeKB KB" -ForegroundColor Green
Write-Host ""
Write-Host "To install: Double-click the MSI file" -ForegroundColor Yellow
Write-Host "To uninstall: Use Add/Remove Programs or run: msiexec /x `"$msiPath`"" -ForegroundColor Yellow

# Clean up intermediate files
if (Test-Path $wixObjFile) {
    Remove-Item $wixObjFile -Force
    Write-Host ""
    Write-Host "Cleaned up intermediate files" -ForegroundColor Gray
}
