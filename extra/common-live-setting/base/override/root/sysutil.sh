#!/bin/sh

ECHO="/bin/echo" ; export ECHO

# Source our functions
. /root/functions.sh

while
i="1"
do

# Display Utility Menu
dialog --title " GhostBSD Utility Menu" --menu "Please select from the following options:" 20 55 15 shell "Drop to emergency shell" fixgrub "Restamp GRUB on disk" exit "Exit Utilities" 2>/tmp/UtilAnswer

ANS="`cat /tmp/UtilAnswer`"

case $ANS in
      shell) clear ; echo "# GhostBSD Emergency Shell
#
# Please type 'exit' to return to the menu
#############################################################"

        /bin/csh ;;
    fixgrub) restamp_grub_install ;;
    exit) break ; exit 0 ;;
    *) ;;
esac

done

