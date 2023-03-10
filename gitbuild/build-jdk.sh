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
if [[ "$2" =~ "jdk" ]];then
	JDKV="open${2}"
	JDKNUM="$( echo ${JDKV} | sed 's|openjdk||g')"
else
	echo "JDK version is not set!... Exiting..."
	exit 1
fi

URL="http://dl-cdn.alpinelinux.org/alpine/v${VERSION}/community"
REVS="$(echo $(curl -sL ${URL}/aarch64/ | grep ${JDKV}-doc | awk -F ${JDKV}-doc- '{print$2}' | sed 's|.apk.*||g'))"
export REVS
if [[ ${JDKV} =~ "openjdk" ]]; then
	ARCH="aarch64 armhf armv7 ppc64le s390x x86 x86_64"
	PACKAGES="${JDKV} ${JDKV}-jdk ${JDKV}-jmods ${JDKV}-jre ${JDKV}-jre-lib ${JDKV}-jre-base ${JDKV}-jre-headless"
fi

mkdir ${JDKV}-build
jdk_dir="${JDKV}-buildopenwrt"
export jdk_dir

echo -e "
============
INGFOOOOOO
============
VERSION::$VERSION
JDKV::$JDKV
JDKNUM::$JDKNUM
URL::$URL
REVS::$REVS
ARCH::$ARCH
PACKAGES::$PACKAGES
TMPDIR::$jdk_dir
============
"

# trap "rm -rf $jdk_dir" EXIT

cd "${jdk_dir}"

#execute cmds
for arch in $ARCH;do
	#create dir for every archs
	JDKVARCH="${JDKV}-${arch}"
	[ ! -d "${JDKVARCH}" ] && mkdir "${JDKVARCH}"
	#download, extract, repack packages
	for pkg in $PACKAGES; do
		#download packages
		PKGREVARCH="${pkg}-${REVS}_${arch}.apk"
		echo -e "helmilog:: downloading ${PKGREVARCH}..."
		if curl --output /dev/null --silent --head --fail "${URL}/${arch}/${pkg}-${REVS}.apk"; then
			echo "URL exists: $url"
			curl -o "${PKGREVARCH}" "${URL}/${arch}/${pkg}-${REVS}.apk"
			echo -e "helmilog:: ${PKGREVARCH} downloaded! extracting..."
		else
			echo "URL does not exist! skipping..."
		fi
		#extract apks to corresponding arch dir
		if [[ -f "${PKGREVARCH}" ]]; then
			tar xzf "${PKGREVARCH}" -C "${JDKVARCH}"
			rm -f "${PKGREVARCH}"
			echo -e "helmilog:: ${PKGREVARCH} extracted and removed..."
			#repacking all libs to tar them up
			JDKDIR="${JDKVARCH}/usr/lib/jvm"
			if [[ -d "${JDKDIR}/java-1.8-openjdk" ]]; then
				JDKSRCDIR="${JDKDIR}/java-1.8-openjdk"
			elif [[ -d "${JDKDIR}/java-${JDKNUM}-openjdk" ]]; then
				JDKSRCDIR="${JDKDIR}/java-${JDKNUM}-openjdk"
			else
				echo "EROOORORORORORORORO REPAXKXKIANC"
			fi
			[[ -n ${JDKSRCDIR} ]] && tar czf "${JDKVARCH}.tar.gz" -C "${JDKSRCDIR}/" .
		fi
	done
done
