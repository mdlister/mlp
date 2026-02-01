# Save as: Generate-WebP.ps1
# Location: C:\Repos\Mike Lister Photography\Generate-WebP.ps1

# Configuration
$ProjectRoot = "C:\Repos\Mike Lister Photography"
$JpegSource = "$ProjectRoot\assets\images"
$WebpOutput = "$ProjectRoot\assets\images\webp"
$Quality = 85  # Quality setting (1-100, 80-90 is usually good)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Mike Lister Photography WebP Generator" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Check if ImageMagick is available
try {
    $magickVersion = magick --version
    Write-Host "✓ ImageMagick found:" -ForegroundColor Green
    Write-Host "  $($magickVersion[0])" -ForegroundColor Gray
} catch {
    Write-Host "✗ ImageMagick not found or not in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please install ImageMagick from:" -ForegroundColor Yellow
    Write-Host "https://imagemagick.org/script/download.php#windows" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "After installing, restart PowerShell or add it to PATH" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# 2. Check if source directory exists
if (-not (Test-Path $JpegSource)) {
    Write-Host "✗ Source directory not found:" -ForegroundColor Red
    Write-Host "  $JpegSource" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Please check the path and try again" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# 3. Get all JPEG files
Write-Host "`n📁 Scanning for JPEG files..." -ForegroundColor Cyan
$allowedFolders = @("wedding", "commercial", "drone")

$jpegFiles = Get-ChildItem -Path $JpegSource -Recurse -Include *.jpg, *.jpeg |
Where-Object {
    $relative = $_.FullName.Substring($JpegSource.Length + 1)
    $topFolder = $relative.Split('\')[0]
    $allowedFolders -contains $topFolder
}

if ($jpegFiles.Count -eq 0) {
    Write-Host "✗ No JPEG files found in:" -ForegroundColor Red
    Write-Host "  $JpegSource" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✓ Found $($jpegFiles.Count) JPEG files" -ForegroundColor Green

# 4. Create output directory structure (matching source structure)
Write-Host "`n📂 Creating output directory structure..." -ForegroundColor Cyan

# First, clear existing WebP directory if you want fresh generation
if (Test-Path $WebpOutput) {
    Write-Host "  Removing existing WebP files..." -ForegroundColor Yellow
    #Remove-Item -Path "$WebpOutput\*" -Recurse -Force
}

# Create main output directory
#New-Item -ItemType Directory -Force -Path $WebpOutput | Out-Null

# 5. Process each file
Write-Host "`n🔄 Converting to WebP (Quality: $Quality)..." -ForegroundColor Cyan

$convertedCount = 0
$skippedCount = 0
$errors = @()

foreach ($jpeg in $jpegFiles) {
    # Calculate relative path from source directory
    $relativePath = $jpeg.FullName.Substring($JpegSource.Length + 1)
    
    # Change extension to .webp
    $webpName = [System.IO.Path]::ChangeExtension($relativePath, ".webp")
    $webpFullPath = Join-Path $WebpOutput $webpName
    
    # Create subdirectory if needed
    $webpDirectory = [System.IO.Path]::GetDirectoryName($webpFullPath)
    if (-not (Test-Path $webpDirectory)) {
        New-Item -ItemType Directory -Force -Path $webpDirectory | Out-Null
    }
    
    # Check if WebP already exists and is newer (skip if so)
    if (Test-Path $webpFullPath) {
        $jpegModified = $jpeg.LastWriteTime
        $webpModified = (Get-Item $webpFullPath).LastWriteTime
        
        if ($jpegModified -le $webpModified) {
            Write-Host "  [SKIP] $relativePath" -ForegroundColor DarkGray
            $skippedCount++
            continue
        }
    }
    
    # Convert to WebP
    Write-Host "  [CONVERT] $relativePath" -ForegroundColor White
    
    try {
        # Using ImageMagick's magick command
        magick $jpeg.FullName -quality $Quality $webpFullPath
        
        if (Test-Path $webpFullPath) {
            $convertedCount++
            
            # Get file size comparison
            $jpegSize = (Get-Item $jpeg.FullName).Length / 1KB
            $webpSize = (Get-Item $webpFullPath).Length / 1KB
            $savings = (($jpegSize - $webpSize) / $jpegSize) * 100
            
            Write-Host "    → Size: $([math]::Round($jpegSize,1))KB → $([math]::Round($webpSize,1))KB (Save: $([math]::Round($savings,1))%)" -ForegroundColor Green
        } else {
            $errors += "Failed: $relativePath"
            Write-Host "    ✗ Conversion failed" -ForegroundColor Red
        }
    } catch {
        $errors += "Error: $relativePath - $_"
        Write-Host "    ✗ Error: $_" -ForegroundColor Red
    }
}

# 6. Summary
Write-Host "`n" + ("="*50) -ForegroundColor Cyan
Write-Host "           CONVERSION COMPLETE" -ForegroundColor Cyan
Write-Host ("="*50) -ForegroundColor Cyan
Write-Host "`n📊 Summary:" -ForegroundColor Yellow
Write-Host "  Total JPEGs found: $($jpegFiles.Count)" -ForegroundColor White
Write-Host "  Newly converted:   $convertedCount" -ForegroundColor Green
Write-Host "  Skipped (up-to-date): $skippedCount" -ForegroundColor Gray

if ($errors.Count -gt 0) {
    Write-Host "  Errors:           $($errors.Count)" -ForegroundColor Red
    Write-Host "`n❌ Errors encountered:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "  - $error" -ForegroundColor Red
    }
}

Write-Host "`n📁 WebP files saved to:" -ForegroundColor Yellow
Write-Host "  $WebpOutput" -ForegroundColor White

Write-Host "`n✨ Your website now has WebP versions ready to use!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "  1. Run: bundle exec jekyll serve" -ForegroundColor White
