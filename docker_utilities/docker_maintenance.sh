#!/bin/bash

# SYNOPSIS
#    Keeps Docker Desktop clean by pruning unused resources, identifying active containers,
#    checking for newer image versions, and optionally auto-updating containers.
#
# NOTES
#    Author: Toby’s Copilot (Ported to Bash)
#    Requires: Docker CLI

# Default values
AUTO_UPDATE=false
PRUNE_ALL=false

# Colors
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
DARK_YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Parse arguments
for arg in "$@"
do
    case $arg in
        --auto-update)
        AUTO_UPDATE=true
        shift
        ;;
        --prune-all)
        PRUNE_ALL=true
        shift
        ;;
    esac
done

echo -e "${CYAN}\n=== Docker Maintenance Script Starting ===\n${NC}"

# Ensure Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Docker does not appear to be running. Start Docker and try again.${NC}"
    exit 1
fi

# ------------------------------------------------------------
# 1. List all containers
# ------------------------------------------------------------
echo -e "${YELLOW}Fetching container list...${NC}"

# Get containers in format: ID Image Name
CONTAINERS=$(docker ps -a --format "{{.ID}} {{.Image}} {{.Names}}")

if [ -z "$CONTAINERS" ]; then
    echo -e "${DARK_YELLOW}No containers found.${NC}"
else
    echo -e "${GREEN}\nActive & Inactive Containers:${NC}"
    # Print header
    printf "%-15s %-30s %-30s\n" "ID" "IMAGE" "NAME"
    echo "$CONTAINERS" | while read -r id image name; do
        printf "%-15s %-30s %-30s\n" "$id" "$image" "$name"
    done
fi

# ------------------------------------------------------------
# 2. Prune unused Docker resources
# ------------------------------------------------------------
echo -e "${YELLOW}\nRunning basic prune (containers, networks, build cache)...${NC}"
docker system prune -f

if [ "$PRUNE_ALL" = true ]; then
    echo -e "${YELLOW}Running aggressive prune (unused images, volumes)...${NC}"
    docker system prune -a --volumes -f
fi

# ------------------------------------------------------------
# 3. Check for newer image versions
# ------------------------------------------------------------
echo -e "${YELLOW}\nChecking for updated images...${NC}"

# Get unique images
if [ -n "$CONTAINERS" ]; then
    UNIQUE_IMAGES=$(echo "$CONTAINERS" | awk '{print $2}' | sort | uniq)
else
    UNIQUE_IMAGES=""
fi

UPDATE_LIST=()

if [ -n "$UNIQUE_IMAGES" ]; then
    for img in $UNIQUE_IMAGES; do
        echo -e "${CYAN}Checking: $img${NC}"
        
        # Pull latest version and capture output
        PULL_RESULT=$(docker pull "$img" 2>&1)
        
        if [[ "$PULL_RESULT" == *"Image is up to date"* ]]; then
            echo -e "${GREEN} → Already up to date.${NC}"
        else
            echo -e "${GREEN} → Newer version available!${NC}"
            UPDATE_LIST+=("$img")
        fi
    done
fi

# ------------------------------------------------------------
# 4. Auto-update containers (optional)
# ------------------------------------------------------------
if [ "$AUTO_UPDATE" = true ] && [ ${#UPDATE_LIST[@]} -gt 0 ]; then
    echo -e "${YELLOW}\nAuto-update enabled. Updating containers...${NC}"

    for img in "${UPDATE_LIST[@]}"; do
        # Iterate through containers to find matches
        echo "$CONTAINERS" | while read -r id c_image c_name; do
            if [ "$c_image" == "$img" ]; then
                echo -e "${CYAN}\nUpdating container: $c_name${NC}"
                
                # Stop and remove old container
                docker stop "$c_name" > /dev/null
                docker rm "$c_name" > /dev/null
                
                # Recreate container using same name and image
                # NOTE: This assumes default run options — customize as needed
                docker run -d --name "$c_name" "$img" > /dev/null
                
                echo -e "${GREEN} → Updated and restarted.${NC}"
            fi
        done
    done

elif [ ${#UPDATE_LIST[@]} -gt 0 ]; then
    echo -e "${DARK_YELLOW}\nUpdates available, but AutoUpdate is OFF.${NC}"
    echo -e "${GREEN}Images needing update:${NC}"
    for img in "${UPDATE_LIST[@]}"; do
        echo " - $img"
    done
fi

echo -e "${CYAN}\n=== Docker Maintenance Complete ===\n${NC}"
