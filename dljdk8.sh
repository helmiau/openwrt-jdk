#!/bin/bash
#--------------------------------------------------------
# OpenJDK for OpenWrt (18.06 and newer) Script Manager (Installer, Updater and Uninstaller)
#--------------------------------------------------------
# Sources: <https://dev.to/reinhart1010/apparently-yes-you-can-install-openjdk-java-jre-and-yacy-on-openwrt-1e33>
# Base script: <https://github.com/josedelinux/openwrt-jdk>
# Improved script by Helmi Amirudin <helmiau.com>
#--------------------------------------------------------
# If you use some codes frome here, please give credit to www.helmiau.com
#--------------------------------------------------------

set -o errexit
set -o nounset
#set -o pipefail
set -x

#functions check packages
chkIPK () {
	unset PkgX
	PkgX=$( opkg list-installed | grep -c "^curl -\|^libstdcpp6 -\|^libjpeg-turbo -\|^libjpeg-turbo-utils -\|^libnss -" )
	# Checking if packages installed
	if [[ $PkgX -lt 4 ]]; then
		echo -e "All/some required packages is not installed correctly or something wrong...."
		echo -e "Updating package repositories..."
		opkg update
	fi
}

oIns="opkg install"
insIPK () {
	if [[ $(opkg list-installed | grep -c "^$1 -") == "0" ]]; then $oIns $1; fi
}

# Checking if packages installed
chkIPK

# Try install git, git-http, bc, screen is not installed
if [[ $PkgX -lt 4 ]]; then
	echo -e "Try to install curl, libstdcpp6, libjpeg-turbo, libjpeg-turbo-utils, libnss if not installed..." 
	insIPK curl
	insIPK libstdcpp6
	insIPK libjpeg-turbo
	insIPK libjpeg-turbo-utils
	insIPK libnss
else
	echo -e "Packages: curl, libstdcpp6, libjpeg-turbo, libjpeg-turbo-utils, libnss already installed." 
fi

VERSION="3.17"
REVISION="$(curl -sL http://dl-cdn.alpinelinux.org/alpine/v${VERSION}/community/aarch64/ | grep 'openjdk8-src' | awk -F '-src-' '{print$2}' | sed 's|.apk.*||g')"
URL="http://dl-cdn.alpinelinux.org/alpine/v${VERSION}/community"
ARCH="aarch64 armhf armv7 ppc64le s390x x86 x86_64"
PACKAGES="openjdk8 openjdk8-jre openjdk8-jre-lib openjdk8-jre-base"

old_pwd=$(pwd)
tmp_dir=$(mktemp -d -t openjdk8-XXXXXXXXXX)
trap "rm -rf $tmp_dir" EXIT

cd "${tmp_dir}"

#download packages
for arch in $ARCH;do
	for package in $PACKAGES; do
		curl -o "${package}-${REVISION}_${arch}.apk" "${URL}/${arch}/${package}-${REVISION}.apk"
	done
done 

#mkdir
for arch in $ARCH;do
	mkdir "openjdk8-${arch}"
done

#extract apks to corresponding arch dir
for arch in $ARCH;do
	for package in $PACKAGES; do
		#tar xzf "${package}-${REVISION}.apk"
		tar xzf "${package}-${REVISION}_${arch}.apk" -C "openjdk8-${arch}"
	done
done

for arch in $ARCH;do
	chmod +x "openjdk8-${arch}/usr/lib/jvm/java-1.8-openjdk/bin/" 
done

#tar them up agains
for arch in $ARCH;do
	tar czf "openjdk-8_${arch}.tar.gz" -C "openjdk8-${arch}/usr/lib/jvm/java-1.8-openjdk/" .
done

cd "${old_pwd}"

for arch in $ARCH;do
	cp "$tmp_dir/openjdk-8_${arch}.tar.gz" "./"
done

