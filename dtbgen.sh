#!/bin/bash
# simple bash script for generating dtb image

# root directory of universal7880 kernel git repo (default is this script's location)
RDIR=$(pwd)

# directory containing cross-compile arm64 toolchain
TOOLCHAIN=$ANDROID_BUILD_HOME/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9

# device dependant variables
PAGE_SIZE=2048
DTB_PADDING=0

export ARCH=arm64
export CROSS_COMPILE=$TOOLCHAIN/bin/aarch64-linux-android-

BDIR=$RDIR/build
OUTDIR=$BDIR/arch/$ARCH/boot
DTSDIR=$RDIR/arch/$ARCH/boot/dts
DTBDIR=$OUTDIR/dtb
DTCTOOL=$BDIR/scripts/dtc/dtc
INCDIR=$RDIR/include

ABORT()
{
	[ "$1" ] && echo "Error: $*"
	exit 1
}

[ -x "$DTCTOOL" ] ||
ABORT "You need to run ./build.sh first!"

[ -x "${CROSS_COMPILE}gcc" ] ||
ABORT "Unable to find gcc cross-compiler at location: ${CROSS_COMPILE}gcc"

[ "$1" ] && DEVICE=$1
[ "$2" ] && VARIANT=$2

case $DEVICE in
a5y17lte)
	case $VARIANT in
	xx|can)
		DTSFILES="exynos7880-a5y17lte_can_open_00 exynos7880-a5y17lte_can_open_01
			exynos7880-a5y17lte_can_open_02 exynos7880-a5y17lte_can_open_03
			exynos7880-a5y17lte_can_open_05 exynos7880-a5y17lte_can_open_07
			exynos7880-a5y17lte_can_open_08"
		;;
	eur)
		DTSFILES="exynos7880-a5y17lte_eur_open_00 exynos7880-a5y17lte_eur_open_01
			exynos7880-a5y17lte_eur_open_02 exynos7880-a5y17lte_eur_open_03
			exynos7880-a5y17lte_eur_open_05 exynos7880-a5y17lte_eur_open_07
			exynos7880-a5y17lte_eur_open_08"
		;;
	*) ABORT "Unknown variant of $DEVICE: $VARIANT" ;;
	esac
	DTBH_PLATFORM_CODE=0x50a6
	DTBH_SUBTYPE_CODE=0x217584da
	;;
*) ABORT "Unknown device: $DEVICE" ;;
esac

mkdir -p "$OUTDIR" "$DTBDIR"

cd "$DTBDIR" || ABORT "Unable to cd to $DTBDIR!"

rm -f ./*

echo "Processing dts files..."

for dts in $DTSFILES; do
	echo "=> Processing: ${dts}.dts"
	"${CROSS_COMPILE}cpp" -nostdinc -undef -x assembler-with-cpp -I "$INCDIR" "$DTSDIR/${dts}.dts" > "${dts}.dts"
	echo "=> Generating: ${dts}.dtb"
	$DTCTOOL -p $DTB_PADDING -i "$DTSDIR" -O dtb -o "${dts}.dtb" "${dts}.dts"
done

echo "Generating dtb.img..."
#"$RDIR/scripts/dtbTool/dtbTool" -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE --platform $DTBH_PLATFORM_CODE --subtype $DTBH_SUBTYPE_CODE || exit 1
"$RDIR/scripts/dtbTool/dtbTool" -o "$OUTDIR/dtb.img" -d "$DTBDIR/" -s $PAGE_SIZE || exit 1

echo "Done."
