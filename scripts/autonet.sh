#!/bin/bash
# autonet.sh — Toggle AutoNet enable/disable flag
# Intended to be run as the asterisk user
# Recommended location: /etc/asterisk/scripts/autonet.sh
#
# Replace YOURNODE with your hub node number

FLAG="/etc/asterisk/custom/autonet.enabled"
NODE=YOURNODE

if [ -f "$FLAG" ]; then
    rm -f "$FLAG"
    /usr/sbin/asterisk -rx "rpt playback $NODE /usr/local/share/asterisk/sounds/herzog-disabled"
    echo "AutoNet DISABLED"
else
    touch "$FLAG"
    /usr/sbin/asterisk -rx "rpt playback $NODE /usr/local/share/asterisk/sounds/herzog-enabled"
    echo "AutoNet ENABLED"
fi
