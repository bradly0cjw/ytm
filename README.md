# ytmwh
A shell script to migrate youtube watch history from another account

# Usage
1. put your Google Takeout Json file in the same folder with this script
2. right click `Open in Terminal`
3. simply run `.\script.ps1`

> [!NOTE]
> You should check `$commandTemplate = "yt-dlp --mark-watched --simulate --cookies-from-browser firefox " ` in line 14<br>
> modify yourself to match your enviroment
