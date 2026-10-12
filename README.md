# deploy_agent

## How to run
Run ./deploy_agent.sh and pick from the menu: 1) Deploy, 2) Run, 3) Archive logs, 4) Exit.

## Feature 1: Deploy
Checks python3 and zip, asks for a directory name, creates attendance_tracker_{input}/ with Helpers/ and reports/, copies files from templates/, builds the roster (Option A: copy N rows from the template. Option B: generate a fresh roster), sets permissions (chmod +x on the checker, chmod 600 on config.json), optionally updates thresholds, then runs the app to verify.

## Threshold update
You can set warning (default 75) and failure (default 50). sed edits only those two lines in Helpers/config.json without reformatting the file.

## total_sessions
Option A (4 prior sessions in the roster) uses total_sessions 5. Option B (fresh roster) uses total_sessions 1. It is always one more than the prior sessions in the roster.

## Feature 2: Run
Runs python3 attendance_checker.py inside an already deployed project.

## Feature 3: Archive logs
Moves reports/attendance.log to archives/attendance/attendance_YYYYMMDD_HHMMSS.log and reports/absent.log to archives/absent/absent_YYYYMMDD_HHMMSS.log. If a log does not exist, the script reports it and continues.

## Testing Ctrl+C / Ctrl+Z
Press Ctrl+C or Ctrl+Z during deployment. The script prints an interrupted message, zips the partial project into attendance_tracker_{input}_archive.zip (it contains whatever was created so far), removes the half-made folder, and exits cleanly.

## How the deployed structure was tested
Deploy ends by running attendance_checker.py. A successful startup proves the structure, roster and config work together.

## Notes for Git Bash on Windows
chmod 600 is not enforced on Windows file systems, but works on Linux/Mac. If zip is missing, a small Python-based zip command can be placed in ~/bin. Make sure the real Python is first in PATH, not the Microsoft Store stub.

## Run-through video
https://youtu.be/S_92UXQ9gkE

## Usage

Run the script from the project folder:

    chmod +x deploy_agent.sh
    ./deploy_agent.sh

Then pick an option from the menu:

1. Deploy: creates attendance_tracker_NAME from the templates
2. Run: runs the attendance checker
3. Archive logs: moves logs into archives/
4. Exit

## Prerequisites

Before running the script, make sure you have:

- Bash (Git Bash on Windows, or any Linux/macOS terminal)
- python3 installed
- zip installed
- The templates folder next to deploy_agent.sh

## Troubleshooting

- "ERROR: python3 is not installed" or "zip is not installed": install the missing tool, then run the script again.
- "ERROR: use only letters, numbers, - and _": the directory name had spaces or special characters. Enter a simpler name.
- "ERROR: template ... missing": the templates folder is not next to deploy_agent.sh. Check that it exists and has attendance_checker.py and config.json.
- "already exists. Overwrite?": a project with that name exists. Type y to replace it, or anything else to abort.

## Project Structure

    deploy_agent.sh    main script with the menu
    templates/         files copied into each new project
    README.md          this file
    .gitignore         files Git should ignore

## Author

Ndangamira Rwema Dylan (dndangamir-byte), African Leadership University
