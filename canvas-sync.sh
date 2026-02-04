#!/bin/bash

# --- 1. Load Environment ---
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found."
    exit 1
fi

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
    local category_name=$1
    local filter_pattern=$2
    local target_dir="$LOCAL_DIR/$category_name"

    mkdir -p "$target_dir"

    # Search the HTML for the pattern and extract following PDF links
    echo "Processing $category_name..."
    
    # This complex grep finds lines containing your keyword (Slides/Seminar) 
    # and extracts the URL within that same context block.
    echo "$HTML_CONTENT" | grep -iE "$filter_pattern" | grep -oP 'https://www.cs.oslomet.no/[^" ]+\.pdf' | sort -u | while read -r url; do
        filename=$(basename "$url")
        if [ ! -f "$target_dir/$filename" ]; then
            echo "  + New $category_name found: $filename"
            curl -s -L -o "$target_dir/$filename" "$url"
        fi
    done
}

# Run the downloads
download_category "Slides" "slides"
download_category "Seminar" "seminar|oppgaver"

# --- 4. Sync to Google Drive ---
echo "Syncing to Google Drive..."
rclone copy "$LOCAL_DIR" "$REMOTE_NAME:$REMOTE_PATH" --update --progress

echo "--- Sync Complete ---"