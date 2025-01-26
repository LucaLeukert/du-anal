# Disk Usage Analysis (du-anal)

A PowerShell script to analyze disk usage by calculating and displaying folder and file sizes in a directory tree. Supports filtering by size, recursive analysis, and customizable depth.

## Features

- Analyze folder sizes in a directory tree.
- Filter results by minimum size (default: 20 MB).
- Optionally include individual file sizes in the output.
- Customize recursion depth for analysis.
- Color-coded output based on folder size.

## Usage

Run the script with the following parameters:

```powershell
.\DiskUsage.ps1 -Path <DirectoryPath> -Depth <MaxDepth> -MinSize <SizeInMB> -PrintFiles
