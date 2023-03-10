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

# Build Version from http://dl-cdn.alpinelinux.org/alpine/
if [[ -n "$1" ]];then
	VERSION="$1"
else
	echo "Build version is not set, using default script setting!."
	VERSION="3.17"
fi

# JDK8 or JDK11
if [[ "$2" == "jdk8" ]];then
	JDKV="open${2}"
else
	echo "JDK version is not set!... Exiting..."
	exit 1
fi

URL="http://dl-cdn.alpinelinux.org/alpine/v${VERSION}/community"
curl -sL ${URL}/aarch64/ | grep ${JDKV}-doc | awk -F ${JDKV}-doc- '{print$2}' | sed 's|.apk.*||g' > JDKREV
REVISION="$(cat JDKREV && rm JDKREV)"
export REVISION
if [[ ${JDKV} == "openjdk11" ]]; then
	ARCH="aarch64 ppc64le s390x x86_64"
	PACKAGES="${JDKV} ${JDKV}-jdk ${JDKV}-jre ${JDKV}-jre-headless"
else
	ARCH="aarch64 armhf armv7 ppc64le s390x x86 x86_64"
	PACKAGES="${JDKV} ${JDKV}-jre ${JDKV}-jre-lib ${JDKV}-jre-base"
fi
old_pwd=$(pwd)
jdk_tmp_dir=$(mktemp -d -t ${JDKV}-XXXXXXXXXX)
export jdk_tmp_dir

echo -e "
============
INGFOOOOOO
============
VERSION::$VERSION
JDKV::$JDKV
URL::$URL
REVISION::$REVISION
ARCH::$ARCH
PACKAGES::$PACKAGES
TMPDIR::$jdk_tmp_dir
============
"

# trap "rm -rf $jdk_tmp_dir" EXIT

cd "${jdk_tmp_dir}"

#execute cmds
for arch in $ARCH;do
	#create dir for every archs
	JDKVARCH="${JDKV}-${arch}"
	[ ! -d "${JDKVARCH}" ] && mkdir "${JDKVARCH}"
	#download, extract, repack packages
	for pkg in $PACKAGES; do
		#download packages
		PKGREVARCH="${pkg}-${REVISION}_${arch}.apk"
		echo -e "helmilog:: downloading ${PKGREVARCH}..."
		curl -o "${PKGREVARCH}" "${URL}/${arch}/${pkg}-${REVISION}.apk"
		echo -e "helmilog:: ${PKGREVARCH} downloaded! extracting..."
		#extract apks to corresponding arch dir
		if [[ -f "${PKGREVARCH}" ]]; then
			tar xzf "${PKGREVARCH}" -C "${JDKVARCH}"
			rm -f "${PKGREVARCH}"
			echo -e "helmilog:: ${PKGREVARCH} extracted and removed..."
			#repacking all libs to tar them up
			JDKTMPDIR="${JDKVARCH}/usr/lib/jvm"
			if [[ -d "${JDKTMPDIR}/java-1.8-openjdk" ]]; then
				JDKSRCDIR="${JDKTMPDIR}/java-1.8-openjdk"
			elif [[ -d "${JDKTMPDIR}/java-11-openjdk" ]]; then
				JDKSRCDIR="${JDKTMPDIR}/java-11-openjdk"
			else
				echo "EROOORORORORORORORO REPAXKXKIANC"
			fi
			[[ -n ${JDKSRCDIR} ]] && tar czf "rep4ck_${JDKVARCH}.tar.gz" -C "${JDKSRCDIR}/" .
		fi
	done
done
