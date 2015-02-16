#!/bin/bash
#Exit on error
set -e
set -x

PPA=mhero

#Don't edit below

HOME=`pwd`
AWK=/usr/bin/awk
HEAD=/usr/bin/head
GIT=/usr/bin/git
SORT=/usr/bin/sort
DCH=/usr/bin/dch
PR=/usr/bin/pr 
SED=/bin/sed
FMT=/usr/bin/fmt
PR=/usr/bin/pr
XARGS=/usr/bin/xargs

cd $HOME/targets
TARGETS=(*)
echo $TARGETS
cd $HOME




LASTVERS=`$GIT tag -l '1.*.*' | $SORT -rV | $HEAD -1`
VERS="${LASTVERS%.*}.$((${LASTVERS##*.}+1))"
echo Current tagged verison is $LASTVERS.  
$GIT status
echo Should we update changelogs, commit under packacing everything and increment to $VERS? [y/n]
read INCVERS 

if [[ "$INCVERS" == "y" || "$INCVERS" == "Y" ]];  then
    COMMITMSG="Release Version $VERS"
    WIDTH=68
    URL="https://github.com/openhie/openinfoman-ilr/commit/"



    LOGLINES=$($GIT log --oneline $LASTVERS.. | $AWK '{printf " -%s\n --'$URL'%s\n" , $0, $1}')

    FULLCOMMITMSG=$(echo "$COMMITMSG 
$LOGLINES" |  $XARGS -0 | $AWK '{printf "%-'"$WIDTH.$WIDTH"'s\n" , $0}')


    for TARGET in "${TARGETS[@]}"
    do
	cd $HOME/targets/$TARGET
	$DCH -Mv "${VERS}~$TARGET" --distribution "${TARGET}" "${FULLCOMMITMSG}"
    done
    cd $HOME

    $GIT  --no-pager diff
    $GIT add .

    echo "Incrementing version"
    $GIT commit ./ -m "\"${COMMITMSG}\""
    $GIT tag $VERS
elif  [[ "$INCVERS" == "n" || "$INCVERS" == "N" ]];  then
    echo "Not incremementing version"
else
    echo "Don't know what' to do"
    exit 1
fi



if [ -n "$LAUNCHPADPPALOGIN" ]; then
  echo Using $LAUNCHPADPPALOGIN for Launchpad PPA login
  echo "To Change You can do: export LAUNCHPADPPALOGIN=$LAUNCHPADPPALOGIN"
else 
  echo -n "Enter your launchpad login for the ppa and press [ENTER]: "
  read LAUNCHPADPPALOGIN
  echo "You can do: export LAUNCHPADPPALOGIN=$LAUNCHPADPPALOGIN to avoid this step in the future"
fi

KEY=

if [ -n "${DEB_SIGN_KEYID}" ]; then
  echo Using ${DEB_SIGN_KEYID} for Launchpad PPA login
  echo "To Change You can do: export DEB_SIGN_KEYID=${DEB_SIGN_KEYID}"
  echo "For unsigned you can do: export DEB_SIGN_KEYID="
  KEY="-k${DEB_SIGN_KEYID}"
else 
  echo "No DEB_SIGN_KEYID key has been set.  Will create an unsigned"
  echo "To set a key for signing do: export DEB_SIGN_KEYID=<KEYID>"
  echo "Use gpg --list-keys to see the available keys"
  KEY="-uc -us"
fi


BUILD=$HOME/builds

for TARGET in "${TARGETS[@]}"
do
    TARGETDIR=$HOME/targets/$TARGET
    echo "$HEAD -1 $TARGETDIR/debian/changelog | $AWK '{print $2}' | $AWK -F~ '{print $1}' | $AWK -F\( '{print $2}'"
    RLS=`$HEAD -1 $TARGETDIR/debian/changelog | $AWK '{print $2}' | $AWK -F~ '{print $1}' | $AWK -F\( '{print $2}'`
    PKG=`$HEAD -1 $TARGETDIR/debian/changelog | $AWK '{print $1}'`
    PKGDIR=${BUILD}/${PKG}-${RLS}~${TARGET}
    CHANGES=${BUILD}/${PKG}_${RLS}~${TARGET}_source.changes

    echo  "echo Building Package $PKG  on Release $RLS for Target $TARGET"

    rm -fr $PKGDIR
    mkdir -p $PKGDIR/var/lib
    cd $PKGDIR/var/lib && git clone https://github.com/openhie/$PKG openinfoman
    rm -fr $PKGDIR/var/lib/openinfoman/.git
    rm -f $PKGDIR/var/lib/openinfoman/.gitignore
    rm -fr $PKGDIR/var/lib/openinfoman/packaging
    mkdir -p $PKGDIR/var/lib/openinfoman/repo
    mv $PKGDIR/var/lib/openinfoman/repo $PKGDIR/var/lib/openinfoman/repo-src 
    cp  -R $TARGETDIR/* $PKGDIR

    cd $PKGDIR  
    #CMD="dpkg-buildpackage $KEY  -S -sa "
    DPKGCMD="dpkg-buildpackage $KEY  -S -sa "
    $DPKGCMD


    cd ~/
    echo `pwd`
    if [[ -n "${DEB_SIGN_KEYID}" && -n "{$LAUNCHPADLOGIN}" ]]; then
	DPUTCMD="dput ppa:$LAUNCHPADPPALOGIN/$PPA  $CHANGES"
	$DPUTCMD
        #cd $PKGDIR && dpkg-buildpackage -uc -us
        #cd $PKGDIR && dpkg-buildpackage -k${DEB_SIGN_KEYID} -S -sa 
        #
    else
	echo "Not uploaded to launchpad"
    fi
done


cd $HOME

git push
git push --tags