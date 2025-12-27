<#
.SYNOPSIS
    Keeps Docker Desktop clean by pruning unused resources, identifying active containers,
    checking for newer image versions, and optionally auto-updating containers.

.NOTES
    Author: Toby’s Copilot
    Requires: Docker CLI, PowerShell 7+
#>

param(
    [switch]$AutoUpdate,          # If set, containers will be recreated using the latest image
    [switch]$PruneAll             # If set, performs aggressive pruning (images, volumes, networks)
)

Write-Host "`n=== Docker Maintenance Script Starting ===`n" -ForegroundColor Cyan

# Ensure Docker is running
try {
    docker info | Out-Null
} catch {
    Write-Host "Docker does not appear to be running. Start Docker Desktop and try again." -ForegroundColor Red
    exit 1
}

# ------------------------------------------------------------
# 1. List all containers
# ------------------------------------------------------------
Write-Host "Fetching container list..." -ForegroundColor Yellow
$containers = docker ps -a --format "{{.ID}} {{.Image}} {{.Names}}" | ForEach-Object {
    $parts = $_.Split(" ")
    [PSCustomObject]@{
        ID    = $parts[0]
        Image = $parts[1]
        Name  = $parts[2]
    }
}

if ($containers.Count -eq 0) {
    Write-Host "No containers found." -ForegroundColor DarkYellow
} else {
    Write-Host "`nActive & Inactive Containers:" -ForegroundColor Green
    $containers | Format-Table
}

# ------------------------------------------------------------
# 2. Prune unused Docker resources
# ------------------------------------------------------------
Write-Host "`nRunning basic prune (containers, networks, build cache)..." -ForegroundColor Yellow
docker system prune -f

if ($PruneAll) {
    Write-Host "Running aggressive prune (unused images, volumes)..." -ForegroundColor Yellow
    docker system prune -a --volumes -f
}

# ------------------------------------------------------------
# 3. Check for newer image versions
# ------------------------------------------------------------
Write-Host "`nChecking for updated images..." -ForegroundColor Yellow

$uniqueImages = $containers.Image | Sort-Object -Unique

$updateList = @()

foreach ($img in $uniqueImages) {
    Write-Host "Checking: $img" -ForegroundColor Cyan

    # Pull latest version
    $pullResult = docker pull $img 2>&1

    if ($pullResult -match "Image is up to date") {
        Write-Host " → Already up to date." -ForegroundColor DarkGreen
    } else {
        Write-Host " → Newer version available!" -ForegroundColor Green
        $updateList += $img
    }
}

# ------------------------------------------------------------
# 4. Auto-update containers (optional)
# ------------------------------------------------------------
if ($AutoUpdate -and $updateList.Count -gt 0) {
    Write-Host "`nAuto-update enabled. Updating containers..." -ForegroundColor Yellow

    foreach ($img in $updateList) {
        $affected = $containers | Where-Object { $_.Image -eq $img }

        foreach ($c in $affected) {
            Write-Host "`nUpdating container: $($c.Name)" -ForegroundColor Cyan

            # Stop and remove old container
            docker stop $c.Name | Out-Null
            docker rm $c.Name | Out-Null

            # Recreate container using same name and image
            # NOTE: This assumes default run options — customize as needed
            docker run -d --name $c.Name $img | Out-Null

            Write-Host " → Updated and restarted." -ForegroundColor Green
        }
    }
} elseif ($updateList.Count -gt 0) {
    Write-Host "`nUpdates available, but AutoUpdate is OFF." -ForegroundColor DarkYellow
    Write-Host "Images needing update:" -ForegroundColor Green
    $updateList | ForEach-Object { Write-Host " - $_" }
}

Write-Host "`n=== Docker Maintenance Complete ===`n" -ForegroundColor Cyan