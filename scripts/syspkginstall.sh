#!/bin/sh 

PLOGFILE=".log_pkginstall"
pkgfile="conf/packages"
pkgaddcmd="pkg install -y"

# Search main file package for include dependecies
# and build an depends file ( depends )
awk '/^deps/,/^"""/' packages/mate | grep -v '"""' | grep -v '#' > packages/depends

# Add to EXTRA plugins the needed plugin readed from settings section
# Readed plugin is added only if it isn't already in conf file
add_extra=$(cat packages/mate | grep -iF1 settings= | grep -v '"""')

# If exist an old .packages file removes it
if [ -f conf/packages ] ; then
  rm -f conf/packages
fi

# Reads packages from packages profile
awk '/^packages/,/^"""/' packages/mate > conf/package

# Reads depends file and search for packages entries in each file from depends
# list, then append all packages found in packages file
while read pkgs ; do
  awk '/^packages/,/^"""/' packages/packages.d/$pkgs  >> conf/package
done < packages/depends 

# Removes """ and # from temporary package file
cat conf/package | grep -v '"""' | grep -v '#' > conf/packages

# Removes temporary files
if [ -f conf/package ] ; then
  rm -f conf/package
  rm -f packages/depends
fi

echo "#!/bin/sh" > conf/ports
echo "portinstall -c" | tr "\n" " " >> script/ports.sh
cat tool/packages | tr "\n" " " >> script/ports.sh

# Installing pkg
while read pkgc; do
  if [ -n "${pkgc}" ] ; then
  $pkgaddcmd $pkgc 
  fi
done < $pkgfile

#installing remaining pkg from ports.
sh script/ports.sh

#!/bin/sh

# Remove Gnome and Mate in .desktop.

GhostBSD=`ls /usr/local/share/applications/`

for desktop in $GhostBSD
do
  chmod 755 /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=Gnome;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/GNOME;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/MATE;//g' /usr/local/share/applications/$desktop
  sed -i "" -e 's/OnlyShowIn=//g' /usr/local/share/applications/$desktop
  chmod 555 /usr/local/share/applications/$desktop
done

# Creating pkg for GhostBSD. 
if [ "$(uname -p)" = "amd64" ] ; then
  PLATFORM=${PLATFORM:-"amd64"}
else
  PLATFORM=${PLATFORM:-"i386"}
fi

mkdir -p /usr/obj/packages/${PLATFORM} 
for e in `pkg info | awk '{print $1}'`; do
  este=`ls -l /usr/obj/packages/${PLATFORM} | awk '{print $9}'| grep $e`
  echo $este
  if [ "${este}" = "${e}.txz" ] ; then
    echo "Package "$e" is allready in /usr/obj/packages/${PLATFORM}"
  else
    echo "Creating backup package(s) "$e" /usr/obj/packages/${PLATFORM}"
    cd /usr/obj/packages/${PLATFORM} && pkg create $e
    echo "Package "$e" was created..."
  fi
done
