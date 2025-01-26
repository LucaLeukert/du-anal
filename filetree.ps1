<#
.SYNOPSIS
    Disk Usage Analysis

.DESCRIPTION
    This script calculates and displays the sizes of folders (and optionally files)
    in a directory tree. It supports filtering by minimum size and allows for
    recursive analysis up to a specified depth.

.PARAMETER Path
    The root directory to analyze. Defaults to the current working directory.

.PARAMETER Depth
    The maximum depth of recursion. A value of 0 means auto-detect full depth.

.PARAMETER MinSize
    The minimum size (in MB) for folders or files to be displayed. Defaults to 20 MB.

.PARAMETER PrintFiles
    A switch to include individual file sizes in the output.

.EXAMPLE
    .\DiskUsage.ps1 -Path "C:\MyFolder" -Depth 2 -MinSize 50 -PrintFiles

    Analyzes the folder "C:\MyFolder" up to a depth of 2, displaying only folders
    and files larger than 50 MB.

.EXAMPLE
    .\DiskUsage.ps1 -Path "C:\MyFolder" -PrintFiles

    Analyzes the folder "C:\MyFolder" and includes file sizes in the output.

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
#>

[CmdletBinding()]
param (
    [string]$Path = (Get-Location).Path,
    [int]$Depth = 0, # 0 means auto-detect full depth
    [int]$MinSize = 20,
    [switch]$PrintFiles
)

# Thread-safe hashtable for storing cumulative sizes
$FolderSizes = [System.Collections.Hashtable]::Synchronized(@{})

function FormatSize {
    param ([long]$SizeBytes)
    
    $sizeInMB = $SizeBytes / 1MB
    $sizeInGB = $SizeBytes / 1GB
    
    if ($sizeInMB -lt 200) {
        return "{0:N2} MB" -f $sizeInMB
    }
    else {
        return "{0:N2} GB" -f $sizeInGB
    }
}

function GetColorBasedOnSize {
    param ([long]$SizeBytes)
    
    $sizeInGB = $SizeBytes / 1GB
    
    switch ($sizeInGB) {
        {$_ -lt 1} { return "Green" }
        {$_ -ge 1 -and $_ -lt 5} { return "Yellow" }
        {$_ -ge 5 -and $_ -lt 10} { return "Magenta" }
        default { return "Red" }
    }
}

function CalculateAndPrintFolderSizes {
    param (
        [string]$Path,
        [int]$MaxDepth = 0,
        [int]$CurrentDepth = 1
    )
    
    # Calculate size for current folder
    $folderSize = (Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $FolderSizes[$Path] = $folderSize

    # Count subfolders
    $subFolderCount = (Get-ChildItem -Path $Path -Directory -Force -ErrorAction SilentlyContinue).Count
    
    # Print the folder only if it meets the size criteria
    if ($folderSize -ge ($MinSize * 1MB)) {
        $indent = '│   ' * ($CurrentDepth - 1)
        $folderName = if ($CurrentDepth -eq 1) { $Path } else { Split-Path -Path $Path -Leaf }
        $folderColor = GetColorBasedOnSize -SizeBytes $folderSize
        Write-Host "$indent├── " -NoNewline
        Write-Host "$folderName " -NoNewline -ForegroundColor $folderColor
        Write-Host "($(FormatSize -SizeBytes $folderSize))" -ForegroundColor Cyan -NoNewline

        # Print subfolder count only if greater than 0
        if ($subFolderCount -gt 1) {
            Write-Host " - $subFolderCount subfolders" -ForegroundColor DarkGray -NoNewline
        } elseif ($subFolderCount -eq 1) {
            Write-Host " - 1 subfolder" -ForegroundColor DarkGray -NoNewline
        }
        Write-Host "" # End the line
    }
    
    # If depth allows and PrintFiles is set, print files in the folder
    if ($PrintFiles) {
        Get-ChildItem -Path $Path -File -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Length -ge ($MinSize * 1MB) } |
            ForEach-Object {
                $fileSize = $_.Length
                $fileName = $_.Name
                $indent = '│   ' * $CurrentDepth
                Write-Host "$indent├── " -NoNewline
                Write-Host "$fileName " -NoNewline -ForegroundColor Gray
                Write-Host "($(FormatSize -SizeBytes $fileSize))" -ForegroundColor DarkGray
            }
    }
    
    # Determine max depth if not specified
    if ($MaxDepth -eq 0) {
        $MaxDepth = (Get-ChildItem -Path $Path -Recurse -Directory -Force -ErrorAction SilentlyContinue).FullName.Count
    }
    
    # Process subfolders for deeper levels
    if ($CurrentDepth -lt $MaxDepth) {
        Get-ChildItem -Path $Path -Directory -Force -ErrorAction SilentlyContinue | 
            ForEach-Object {
                CalculateAndPrintFolderSizes -Path $_.FullName -MaxDepth $MaxDepth -CurrentDepth ($CurrentDepth + 1)
            }
    }
}

# Display help menu if requested
if ($PSCmdlet.MyInvocation.BoundParameters.ContainsKey('Help')) {
    Get-Help -Full
    return
}

# Measure the start time
$startTime = Get-Date

# Execute the analysis
Write-Host @"
___  _  _    ____ _  _ ____ _    
|  \ |  | __ |__| |\ | |__| |    
|__/ |__|    |  | | \| |  | |___ 
"@ -ForegroundColor Cyan
Write-Host ""
Write-Host "Analyzing Path: $Path" -ForegroundColor Yellow
Write-Host "Minimum Size Threshold: $MinSize MB" -ForegroundColor DarkGray
Write-Host "" # Add a blank line for spacing

CalculateAndPrintFolderSizes -Path $Path -MaxDepth $Depth

# Measure the end time
$endTime = Get-Date
$executionTime = $endTime - $startTime

# Summary
Write-Host ""
Write-Host "==========================================" -ForegroundColor White
Write-Host "Analysis Complete!" -ForegroundColor Green
Write-Host "Total Folders Analyzed: $($FolderSizes.Keys.Count)" -ForegroundColor DarkGray
Write-Host "Total Size: $(FormatSize -SizeBytes ($FolderSizes[$Path] | Measure-Object -Sum).Sum)" -ForegroundColor DarkGray
Write-Host "Execution Time: $($executionTime.TotalSeconds.ToString('0.##')) seconds" -ForegroundColor DarkGray
Write-Host "==========================================" -ForegroundColor White
