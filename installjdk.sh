#!/bin/bash
#--------------------------------------------------------
# OpenJDK for OpenWrt (18.06 and newer) Script Manager (Installer, Updater and Uninstaller)
# Script by Helmi Amirudin <helmiau.com>
#--------------------------------------------------------
# Supported OpenJDK Version: jdk8~jdk17
# Supported Architectures  : aarch64, armhf, armv7, ppc64le, s390x, x86 (32bit), x86_64
# Supported Release Version: v3.0~v3.17
#--------------------------------------------------------
# Usage sample:
# -> installjdk.sh aarch64 jdk8
# -> installjdk.sh armhf jdk11 v3.17
#--------------------------------------------------------
# If you use some codes frome here, please give credit to www.helmiau.com
#--------------------------------------------------------
SCNM="$(basename "$0")"

set -o errexit
set -o nounset
#set -o pipefail
set -x

# $1 == Architecture
if [[ -n "$1" ]];then
	ARCH="$1"
else
	echo -e "-----------------------------------------------------"
	echo -e "Usage sample:"
	echo -e "  ${SCNM} aarch64 jdk8      :(install latest release of jdk8 for aarch64)"
	echo -e "  ${SCNM} armv7 jdk11 v3.15 :(install v3.15 release of jdk11 for armv7)"
	echo -e "-----------------------------------------------------"
	echo -e "helmilog:: Error: Architecture is not set!. exiting..."
	exit 1
fi

# $2 == JDK Version
if [[ -n "$2" ]];then
	JDKVER="$2"
else
	echo "helmilog:: JDK Version is not set!, using [jdk8] by default..."
	JDKVER="jdk8"
fi

# $3 == Release Version
if [[ -n "$3" ]];then
	JDKURL="https://github.com/helmiau/openwrt-jdk/releases/download/openjdk-build-${3}/open${2}-${1}.tar.gz"
	LGH="v${3}"
else
	echo "helmilog:: Release Version is not set!, using latest release by default..."
	JDKURL="https://github.com/helmiau/openwrt-jdk/releases/latest/download/open${2}-${1}.tar.gz"
	LGH="latest release"
fi

echo -e "helmilog:: Installing [open${JDKURL}] [${LGH}] for [${1}] architecture..."

#functions check packages
chkIPK () {
	unset PkgX
	PkgX=$( opkg list-installed | grep -c "^curl -\|^libstdcpp6 -\|^libjpeg-turbo -\|^libjpeg-turbo-utils -\|^libnss -" )
	# Checking if packages installed
	if [[ $PkgX -lt 4 ]]; then
		echo -e "helmilog:: All/some required packages is not installed correctly or something wrong...."
		echo -e "helmilog:: Updating package repositories..."
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
	echo -e "helmilog:: Try to install curl, libstdcpp6, libjpeg-turbo, libjpeg-turbo-utils, libnss if not installed..." 
	insIPK curl
	insIPK libstdcpp6
	insIPK libjpeg-turbo
	insIPK libjpeg-turbo-utils
	insIPK libnss
else
	echo -e "helmilog:: Packages: curl, libstdcpp6, libjpeg-turbo, libjpeg-turbo-utils, libnss already installed." 
fi

JDKTMP="/tmp/ojdk-out.tar.gz"
JVMDIR="/usr/lib/jvm"
# Downloading openjdk packages
if curl --output /dev/null --silent --head --fail "${JDKURL}"; then
	echo "URL exists: ${JDKURL}"
	curl -o "${JDKTMP}" "${JDKURL}"
	echo -e "helmilog:: ${PKGREVARCH} downloaded! extracting..."
else
	echo "helmilog:: URL does not exist! exiting..."
	exit 1
fi

# Extract packages to each directories
echo "helmilog:: Extracting packages..."
[ ! -d "${JVMDIR}" ] && mkdir -p "${JVMDIR}"
[ -f "${JDKTMP}" ] && [ -d "${JVMDIR}" ] && tar zxvf "${JDKTMP}" -C "${JVMDIR}" && rm -f "${JDKTMP}"
echo "helmilog:: Extract done!."

# Create java ca-certs
UPDTD="/etc/ca-certificates/update.d"
JSSL="/etc/ssl/certs/java"
echo "helmilog:: Creating Java SSL certificate..."
[ ! -d "${UPDTD}" ] && mkdir -p "${UPDTD}" && echo -e "#!/bin/sh\nexec trust extract --overwrite --format=java-cacerts --filter=ca-anchors 	--purpose server-auth /etc/ssl/certs/java/cacerts\n" > "${UPDTD}/java-cacerts"
[ ! -d "${JSSL}" ] && mkdir -p "${JSSL}"
# wget https://raw.githubusercontent.com/adoptium/temurin-build/master/security/mk-ca-bundle.pl
# wget https://raw.githubusercontent.com/adoptium/temurin-build/master/security/mk-cacerts.sh
# chmod +x /root/mk-ca-bundle.pl
# chmod +x /root/mk-cacerts.sh
# Download cacert.pem from https://curl.se/docs/caextract.html
# wget  https://curl.se/ca/cacert.pem
echo "helmilog:: Java SSL Certificate created! done!."

# Symlink /usr/lib/jvm/bin contents to /usr/bin
UBN="/usr/bin"
echo "helmilog:: Symlinking java binary to OpenWrt binary..."
[ -d "${JVMDIR}/bin" ] && [ -d "${UBN}" ] && [ ! -f "${JVMDIR}/bin/java" ] && [ ! -f "${UBN}/java" ] && ln -s "${JVMDIR}/bin/*" "${UBN}/"
echo "helmilog:: Symlink done!."
