#!/bin/bash
# Script to sync syllabus files from Canvas to Google Drive using rclone
# Set path for fcron
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# --- 1. Load Environment ---
# Finn mappen der skriptet faktisk er lagret
DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

if [ -f $DIR/.env ]; then
    set -a
    # Absolute path for fcron compatibility
    source "$DIR/.env"
    set +a
else
    echo "Error: .env file not found in $DIR."
    exit 1
fi
# Make sure the local dir stays in same folder as script
LOCAL_DIR=$DIR/$LOCAL_DIR

echo "--- Starting Canvas Syllabus Sync: $(date) ---"

# --- 2. Fetch Syllabus Data ---
# Target the Course endpoint with the syllabus_body inclusion
SYLLABUS_JSON=$(curl -s -H "Authorization: Bearer $CANVAS_TOKEN" \
    "$CANVAS_URL/api/v1/courses/$COURSE_ID?include[]=syllabus_body")

# Extract the HTML content from the JSON
HTML_CONTENT=$(echo "$SYLLABUS_JSON" | jq -r '.syllabus_body')

if [[ "$HTML_CONTENT" == "null" ]]; then
    echo "Error: Could not find syllabus_body. check your Course ID and Token."
    exit 1
fi

# --- 3. Process and Download ---
# Function to download files based on a keyword filter
download_category() {
    local category=$1
    local keyword=$2
    local target_dir="$LOCAL_DIR/"
    mkdir -p "$target_dir"

    echo "Scanning for $category..."
    
    # Regex captures both OsloMet URLs and Canvas internal file paths
    echo "$HTML_CONTENT" | grep -iE "$keyword" | grep -oP '(https://www.cs.oslomet.no/[^" ]+\.pdf|/courses/'$COURSE_ID'/files/[0-9]+/download)' | sort -u | while read -r link; do
        
        if [[ "$link" == http* ]]; then
            # --- EXTERNAL OSLOMET DOWNLOAD ---
            filename=$(basename "$link")
            if [ ! -f "$target_dir/$filename" ]; then
                echo "  + New External File: $filename"
                curl -s -L -o "$target_dir/$filename" "$link"
            fi
        else
            # --- INTERNAL CANVAS DOWNLOAD ---
            full_url="${CANVAS_URL}${link}"
            
            # Step A: Get the real filename from the server headers without downloading the whole file
            # We look for the 'filename=' part of the Content-Disposition header
            real_name=$(curl -s -I -H "Authorization: Bearer $CANVAS_TOKEN" "$full_url" | grep -oP 'filename="?\K[^"\r\n]+' | head -1)
            
            if [[ -z "$real_name" ]]; then
                # Fallback if header parsing fails
                real_name="canvas_file_$(echo $link | grep -oP '[0-9]+').pdf"
            fi

            # Step B: Check if we already have it
            if [ ! -f "$target_dir/$real_name" ]; then
                echo "  + New Canvas File Found: $real_name"
                curl -s -L -H "Authorization: Bearer $CANVAS_TOKEN" -o "$target_dir/$real_name" "$full_url"
            else
                # Optional: Uncomment the next line for verbose debugging
                # echo "  - Skipping (already exists): $real_name"
                :
            fi
        fi
    done
}

# Run the downloads
download_category "Slides" "slides"
download_category "Seminar" "seminar|oppgaver"

# --- 4. Sync to Google Drive ---
echo "Syncing to Google Drive..."
rclone copy "$LOCAL_DIR" "$REMOTE_NAME:$REMOTE_PATH" --update --progress
# rm -rf "$LOCAL_DIR"

echo "--- Sync Complete ---"
