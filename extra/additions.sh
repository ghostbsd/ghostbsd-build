
cat > ${release}/usr/local/share/xsessions/xinitrc.desktop << 'EOF'
[Desktop Entry]
Encoding=UTF-8
Type=XSession
Exec=/usr/local/share/sddm/scripts/xinit-session
TryExec=/usr/local/share/sddm/scripts/xinit-session
Name=User Session
EOF

#sed -i '' -e 's/kern.corefile=/var/coredumps/%U/%N.core/g' ${release}/etc/sysctl.conf

rc()
{
  chroot ${release} sysrc dumpdev="AUTO"
  chroot ${release} sysrc dumpdir="/var/crash"
  chroot ${release} sysrc savecore_enable="YES"

}
