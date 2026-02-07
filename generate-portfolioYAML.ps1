$basePath = 'C:\Repos\Mike Lister Photography'
$outputFile = Join-Path $basePath '_data\portfolio.yml'

$paths = @{
    wedding    = Join-Path $basePath 'assets\images\wedding'
    commercial = Join-Path $basePath 'assets\images\commercial'
    drone      = Join-Path $basePath 'assets\images\drone'
}

$yaml = @()

function Get-TitleFromFilename ($filename) {
    $name = $filename -replace '\.(jpg|jpeg|png|webp)$', ''

    # Remove trailing number (with optional underscore or hyphen)
    $name = $name -replace '([_-]?\d+)$', ''

    # Replace underscores and hyphens with spaces
    $name = $name -replace '[_-]', ' '

    # Clean up any double spaces left behind
    $name = $name -replace '\s{2,}', ' '

    (Get-Culture).TextInfo.ToTitleCase($name.Trim())
}


foreach ($category in $paths.Keys) {
    Get-ChildItem $paths[$category] -recurse -Include *.jpg,*.jpeg,*.png,*.webp -File | ForEach-Object {
write-host $category
        $yaml += "- image: $($_.BaseName)"
        $yaml += "  category: $category"
        $yaml += "  title: `"$((Get-TitleFromFilename $_.Name))`""

        switch ($category) {
            'wedding'    { $desc = 'Wedding photography in Cornwall' }
            'commercial' { $desc = 'Commercial photography for businesses' }
            'drone'      { $desc = 'Aerial drone photography' }
        }

        $yaml += "  description: `"$desc`""
        $yaml += ""
    }
}

$yaml | Out-File $outputFile -Encoding UTF8

Write-Host "Portfolio YAML generated successfully"
Write-Host "You might want to update the category for weddings."
