# Sync canvas files to Google drive
This automation scrapes a canvas page for files hosted externilly and syncs them with google drive.  

## Prerequisites
1. Required Software  
    `curl`: For API communication and file downloads.  
    `jq`: For parsing JSON data from the Canvas API.  
    `rclone`: For syncing files to the cloud.  

2. Configuration & Access  
   **Canvas API Token**: Generate a manual integration token from your Canvas "Settings" page.  
   
   **Rclone Remote**: You must have a pre-configured remote in rclone (e.g., named gdrive).    
   Run `rclone config` to set this up before using the script.  

   **Course ID**: You need the numerical ID of the Canvas course (found in the course URL).  

## Installation
Rename .env.template to .env and fill in canvas api keys and urls. 
For convenience, create a symlink to the script in a $PATH folder to make it executable from wherever:  
```bash
# Syntax: ln -s /absolute/path/to/script /usr/local/bin/shortcut-name
sudo ln -s "$(pwd)/sync-canvas.sh" /usr/local/bin/sync-canvas

# Without sudo access
ln -s "$(pwd)/sync-canvas.sh" $HOME/bin/sync-canvas

```

## How it works
The script is designed to be location-independent, meaning it can be executed from any directory or via a symlink in your $PATH.

1. Dynamic Path Discovery: Upon execution, the script uses
   readlink -f to resolve its own physical location.
   This allows it to find the .env file and the canvas_docs folder
   even if you are calling the script from a different directory.

2. Syllabus Parsing: It queries the Canvas API for a specific Course ID,
   extracts the HTML from the syllabus_body, and uses grep and jq to identify
   file download links.

3. Smart Downloads: The script distinguishes between internal Canvas files and external OsloMet links.
   It checks for existing files in the local canvas_docs folder to avoid redundant downloads.

4. Rclone Sync: Finally, it triggers rclone to mirror the local folder
   to your specified Google Drive path, ensuring your cloud storage is
   always up to date with the latest course material.
