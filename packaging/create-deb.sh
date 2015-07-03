#!/bin/bash
# with thanks to litlfred (https://github.com/jembi/openhim-core-js/tree/86d04db6b65a61c389e339b506408c9c39397b2d/packaging)

#Exit on error
set -e


if [ ! `uname -n` = "vagrant-ubuntu-trusty-64" ]; then
    echo
    echo "[WARNING] Not running inside Vagrant"
    echo "[WARNING] If you wish to run this outside of Vagrant, first ensure that all required artifacts are available in '../artifacts'"
    echo
fi

HOME=`pwd`
ARTIFACTS=$HOME/../artifacts
AWK='/usr/bin/env awk'
HEAD='/usr/bin/env head'
WGET='/usr/bin/env wget'
DCH='/usr/bin/env dch'



cd $HOME/targets
TARGETS=(*)
echo "Targets: $TARGETS"
cd $HOME


PKG=openshr
OPENSHR_VERSION=`$HEAD -1 targets/trusty/debian/changelog | $AWK '{print $2}' | $AWK -F~ '{print $1}' | $AWK -F\( '{print $2}' | $AWK -F- '{print $1}'`
if [ -n "$OPENSHR_VERSION" ]; then
    echo "Current OpenSHR Release Version is $OPENSHR_VERSION"
else
    OPENSHR_VERSION=1.0.0
    echo "Looks like this is a first release of the OpenSHR. Setting version to $OPENSHR_VERSION"
fi

echo -n "Would you like to update the version number? [y/N] "
read INCSHRVER
if [[ "$INCSHRVER" == "y" || "$INCSHRVER" == "Y" ]];  then
    echo -n "Enter a new version number: "
    read SHRVER
fi



echo -n "Would you like to upload the build(s) to Launchpad? [y/N] "
read UPLOAD
if [[ "$UPLOAD" == "y" || "$UPLOAD" == "Y" ]];  then
    if [ -n "$LAUNCHPADPPALOGIN" ]; then
      echo Using $LAUNCHPADPPALOGIN for Launchpad PPA login
      echo "To Change You can do: export LAUNCHPADPPALOGIN=$LAUNCHPADPPALOGIN"
    else 
      echo -n "Enter your launchpad login for the ppa and press [ENTER]: "
      read LAUNCHPADPPALOGIN
      echo "You can do: export LAUNCHPADPPALOGIN=$LAUNCHPADPPALOGIN to avoid this step in the future"
    fi



    if [ -n "${DEB_SIGN_KEYID}" ]; then
      echo Using ${DEB_SIGN_KEYID} for Launchpad PPA login
      echo "To Change You can do: export DEB_SIGN_KEYID=${DEB_SIGN_KEYID}"
      echo "For unsigned you can do: export DEB_SIGN_KEYID="
    else 
      echo "No DEB_SIGN_KEYID key has been set.  Will create an unsigned"
      echo "To set a key for signing do: export DEB_SIGN_KEYID=<KEYID>"
      echo "Use gpg --list-keys to see the available keys"
    fi

    echo -n "Enter the name of the PPA: "
    read PPA
fi


BUILDDIR=$HOME/builds


for TARGET in "${TARGETS[@]}"
do
    TARGETDIR=$HOME/targets/$TARGET
    RLS=`$HEAD -1 $TARGETDIR/debian/changelog | $AWK '{print $2}' | $AWK -F~ '{print $1}' | $AWK -F\( '{print $2}'`
    BUILDNO=$((${RLS##*-}+1))

    if [ -z "$BUILDNO" ] || [ "$INCSHRVER" == "y" ] || [ "$INCSHRVER" == "Y" ]; then
        BUILDNO=1
    fi

    BUILD=${PKG}_${OPENSHR_VERSION}-${BUILDNO}~${TARGET}
    echo "Building $BUILD ..."


    PKGDIR=${BUILDDIR}/${BUILD}
    OPENSHRDIR=$PKGDIR/usr/share/openshr

    cd $TARGETDIR
    echo "Updating changelog for build ..."
    $DCH -Mv "${OPENSHR_VERSION}-${BUILDNO}~${TARGET}" --distribution "${TARGET}" "Release Debian Build ${OPENSHR_VERSION}-${BUILDNO}"

    rm -fr $PKGDIR
    mkdir -p $PKGDIR

    cp -R $TARGETDIR/* $PKGDIR

    cp $ARTIFACTS/*.omod $OPENSHRDIR/openmrs/modules/
    cp $ARTIFACTS/openmrs.sql.gz $OPENSHRDIR/
    

    echo "Bundling Tomcat 7 ..."

    TOMCATDIR=$OPENSHRDIR/tomcat
    if [ ! -f $ARTIFACTS/tomcat.tar.gz ]; then 
        $WGET http://www.us.apache.org/dist/tomcat/tomcat-7/v7.0.62/bin/apache-tomcat-7.0.62.tar.gz -O $ARTIFACTS/tomcat.tar.gz
    fi

    tar -C $OPENSHRDIR -zxf $ARTIFACTS/tomcat.tar.gz
    mv $OPENSHRDIR/apache-tomcat-7.0.62 $TOMCATDIR

    # setup webapps
    rm -fR $TOMCATDIR/webapps/docs
    rm -fR $TOMCATDIR/webapps/examples
    rm -fR $TOMCATDIR/webapps/host-manager
    rm -fR $TOMCATDIR/webapps/manager
    cp $ARTIFACTS/openmrs.war $TOMCATDIR/webapps


    cd $PKGDIR
    if [[ "$UPLOAD" == "y" || "$UPLOAD" == "Y" ]] && [[ -n "${DEB_SIGN_KEYID}" && -n "{$LAUNCHPADPPALOGIN}" ]]; then
        echo "Uploading to PPA ${LAUNCHPADPPALOGIN}/${PPA}"

        CHANGES=${BUILDDIR}/${BUILD}_source.changes

        DPKGCMD="dpkg-buildpackage -rfakeroot -k${DEB_SIGN_KEYID}  -S -sa "
        $DPKGCMD
        DPUTCMD="dput ppa:$LAUNCHPADPPALOGIN/$PPA  $CHANGES"
        $DPUTCMD
    else
        echo "Not uploading to launchpad"
        DPKGCMD="dpkg-buildpackage -A -uc -us"
        $DPKGCMD
    fi

    exit 1
done
