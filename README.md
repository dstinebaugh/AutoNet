# AutoNet - Scheduled Net Automation for ASL3

A clean, production-oriented method for automatically connecting an AllStarLink 3 hub to a scheduled net (example: Nightcrawlers on 458800), complete with pre-net announcements, link management, and easy enable/disable control.

## Overview

- Uses system cron for reliable timing
- Uses a simple flag file to enable or disable the entire sequence
- Plays custom announcements before joining the net
- Disconnects existing links, joins the net, then restores previous links afterward
- Includes helper scripts for audio conversion and enable/disable control

## Prerequisites

- AllStarLink 3 (ASL3) node
- `sox` (for converting audio files to the required `.ul` format)
  ```bash
  sudo apt update
  sudo apt install sox
  ```
- Root / sudo access to edit `rpt.conf` and system crontab
- Custom announcement audio files (MP3 or WAV) that you will convert

## How it works

1. **Flag file** controls whether the sequence runs:  
   `/etc/asterisk/custom/autonet.enabled`

2. **Hub crontab** (adjust times to your local timezone) performs:
   - 10-minute warning announcement
   - 5-minute warning announcement
   - "Now joining" announcement -> disconnect all links -> connect to the target net
   - After the net: leave the net and restore previously connected links

3. Enable / disable from the shell with simple aliases:
   ```bash
   autonet-on
   autonet-off
   ```

## Required sound files

Place these (or your own equivalents) in `/usr/local/share/asterisk/sounds/`  
and ensure they are owned by the `asterisk` user:

| File example              | Purpose                          |
|---------------------------|----------------------------------|
| herzog-10m.ul             | 10-minute warning                |
| herzog-5m.ul    | 5-minute warning                 |
| herzog-now.ul             | Pre-net announcement             |
| herzog-enabled.ul         | Confirmation when enabling       |
| herzog-disabled.ul        | Confirmation when disabling      |

Convert MP3 files with the included helper:

```bash
./scripts/audio-convert announcement.mp3 herzog-now.ul
```

## File layout

- **README.md** - this documentation
- **scripts/**
  - `audio-convert` - MP3 -> .ul helper
  - `autonet.sh` - enable/disable toggle script
- **configs/**
  - `hub-crontab` - example crontab for the hub
  - `spoke-crontab` - optional rejoin after the net
  - `rpt-functions-snippet.conf` - functions to add to rpt.conf
  - `rpt-macro-snippet.conf` - macros to add to rpt.conf
  - `bash-aliases` - shell aliases for quick enable/disable

## Installation (hub)

1. **Toggle script**
   ```bash
   sudo cp scripts/autonet.sh /etc/asterisk/scripts/autonet.sh
   sudo chown asterisk:asterisk /etc/asterisk/scripts/autonet.sh
   sudo chmod 755 /etc/asterisk/scripts/autonet.sh
   ```

2. **Functions** - add the contents of `configs/rpt-functions-snippet.conf`  
   into the active functions stanza of `rpt.conf` (usually `[functions-main]`).

3. **Macros** - add the contents of `configs/rpt-macro-snippet.conf`  
   into the `[macro]` stanza.

4. **Crontab** - install the hub crontab (edit node numbers and times as needed):
   ```bash
   sudo crontab -e
   ```

5. **Bash aliases** - add the lines from `configs/bash-aliases` to `~/.bashrc`, then:
   ```bash
   source ~/.bashrc
   ```

6. **Enable the sequence** (once):
   ```bash
   sudo -u asterisk touch /etc/asterisk/custom/autonet.enabled
   ```

7. **Timezone** - confirm the system is set to the correct local zone:
   ```bash
   timedatectl
   ```

## Manual test commands

Replace `YOURNODE` with your hub node number and `NETNODE` with the target net:

```bash
# 10-minute warning
sudo /usr/sbin/asterisk -rx "rpt fun YOURNODE *901"

# 5-minute warning
sudo /usr/sbin/asterisk -rx "rpt fun YOURNODE *902"

# Full join sequence
sudo /usr/sbin/asterisk -rx "rpt fun YOURNODE *903"
# wait for the announcement to finish
sudo /usr/sbin/asterisk -rx "rpt fun YOURNODE *806"
sleep 2
sudo /usr/sbin/asterisk -rx "rpt fun YOURNODE *3NETNODE"

# Leave net and restore previous links
sudo /usr/sbin/asterisk -rx "rpt fun YOURNODE *1NETNODE"
sleep 2
sudo /usr/sbin/asterisk -rx "rpt fun YOURNODE *816"
```

## Notes

- Adjust all times in the crontab to match your local timezone and the net schedule.
- The sleep after the "now" announcement should be slightly longer than the audio length.
- `*806` remembers the currently connected links; `*816` restores them after the net.
- Keep configuration clean - remove any temporary test macros or experimental lines once everything is verified.
