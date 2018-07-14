#!/bin/sh

. /root/functions.sh

while
i="1"
do

dialog --title "GhostBSD Configuration Menu" --menu "Please select from the following options:" 20 55 15 xorg "Start Desktop (Auto Video Configuration) " vesa "Start Desktop (VESA)" scfb "Start Desktop (SCFB)" intel "Start Desktop (Legacy Intel)" amd "Start Desktop (Radeon)" shell "Drop to emergency shell" reboot "Reboot the system" 2>/tmp/answer

ANS="`cat /tmp/answer`"

case $ANS in
    xorg) echo "Starting Desktop (AutoDetect).. Please wait.."
      start_xorg ;;
    vesa) echo "Starting Desktop (VESA).. Please wait.."
      cp /root/cardDetect/XF86Config.compat /etc/X11/xorg.conf
      startx 2>/tmp/Xerrors ;;
    scfb) echo "Starting Desktop (SCFB).. Please wait.."
      cp /root/cardDetect/XF86Config.scfb /etc/X11/xorg.conf
      startx 2>/tmp/Xerrors ;;
    intel) echo "Starting Desktop (Legacy Intel).. Please wait.."
      cp /root/cardDetect/XF86Config.intel /etc/X11/xorg.conf
      startx 2>/tmp/Xerrors ;;
    amd) echo "Starting Desktop (Radeon).. Please wait.."
      kldload radeonkms
      startx 2>/tmp/Xerrors ;;
    shell) clear ; echo "# GhostBSD Emergency Shell
#
# Please type 'exit' to return to the menu
#############################################################"
      /bin/csh ;;
    reboot)  reboot -q ;;
    *) ;;
esac

done
