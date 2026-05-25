## 📌 Learning Log & Troubleshooting

A comprehensive log summarizing data organization from SQL Server and Repository restructuring using the Git Command Line.

### 1. Troubleshooting & Error Resolutions

* **Error: `fatal: not a git repository`**
    * *Cause:* Running Git commands outside the active project directory (e.g., accidentally navigating back to the Home `~` directory).
    * *Solution:* Use the `cd` command to navigate into the correct project folder. Ensure the terminal line ends with the active branch status, such as `(main)`, before running any Git commands.
* **Error: `bash: cd: too many arguments`**
    * *Cause:* The folder name contains spaces (e.g., `DATA WITH BRASS`), causing Bash to interpret the path as multiple separate arguments.
    * *Solution:* Wrap the entire absolute or relative path in double quotation marks:
        ```bash
        cd "C:\Users\jucho\OneDrive\Desktop\DATA WITH BRASS\Project"
        ```
* **Error: `[rejected] main -> main (fetch first)`**
    * *Cause:* The remote GitHub repository contains new updates or commits that do not exist on the local machine yet.
    * *Solution:* Fetch and merge the remote changes locally before attempting to push again:
        ```bash
        git pull origin main --no-edit
        git push origin main
        ```
* **Error: `invalid path 'scripts/01_database_exploration.'`**
    * *Cause:* The remote repository contains a file or folder ending with a trailing period `.`. The Windows file system rejects trailing periods, causing the `git pull` process to fail.
    * *Solution:* Rename the file/folder directly on GitHub to remove the trailing dot, and configure Git on Windows to bypass strict NTFS name checking:
        ```bash
        git config core.protectNTFS false
        ```

### 2. Navigating the Vim Editor (During Git Merge conflicts)
When Git opens the text-based Vim interface to automatically generate a merge commit message, use these shortcuts to exit:
* **Save and Exit:** Press `Esc` ➡️ Type `:wq` ➡️ Press `Enter`
* **Exit Without Saving:** Press `Esc` ➡️ Type `:q!` ➡️ Press `Enter
