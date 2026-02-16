# Sync canvas files to Google drive
This automation scrapes a canvas page for files hosted externilly and syncs them with google drive.  

## Installation
You have to configure rclone to google drive, run `rclone` in the terminal and follow the steps.  
Rename .env.template to .env and fill in canvas api keys and urls. 
For convenience, create a symlink to the script in a $PATH folder to make it executable from wherever:  
```bash
# Syntax: ln -s /absolute/path/to/script /usr/local/bin/shortcut-name
sudo ln -s "$(pwd)/canvas_sync.sh" /usr/local/bin/sync-canvas

# Without sudo access
ln -s "$(pwd)/canvas_sync.sh" $HOME/bin/sync-canvas

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
