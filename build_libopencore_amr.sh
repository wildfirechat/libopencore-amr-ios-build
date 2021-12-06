#!/bin/sh
set -e
stty -echo

VERSION="0.1.5"

CURRENTPATH=`pwd`
rm -rf "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/src"
tar zxf opencore-amr-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/opencore-amr-${VERSION}"

DEVELOPER=`xcode-select -print-path`
DEST="${CURRENTPATH}/opencore-amr-iphone"
rm -rf "${DEST}"
mkdir -p "${DEST}"

TARGETS="arm64 x86_64 arm64_sim"
LIBS="opencore-amrnb opencore-amrwb"

./configure
for target in $TARGETS; do
    make clean
    case $target in
    arm64)
        arch=arm64
        IOSMV=" -miphoneos-version-min=7.0"
        echo ""
        echo ""
        echo ""
        echo "******** Building opencore-amr for iPhoneOS $arch ********"
        PATH=`xcodebuild -version -sdk iphoneos PlatformPath`"/Developer/usr/bin:$PATH" \
        SDK=`xcodebuild -version -sdk iphoneos Path` \
        CXX="xcrun --sdk iphoneos clang++ -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include -fembed-bitcode" \
        LDFLAGS="-Wl" \
        ./configure \
        --host=arm-apple-darwin \
        --prefix=$DEST \
        --disable-shared
        ;;
    arm64_sim)
        arch=arm64
        IOSMV=" -mios-simulator-version-min=7.0"
        echo ""
        echo ""
        echo ""
        echo "******** Building opencore-amr for iPhoneSimulator $arch ********"
        PATH=`xcodebuild -version -sdk iphonesimulator PlatformPath`"/Developer/usr/bin:$PATH" \
        SDK=`xcodebuild -version -sdk iphonesimulator Path` \
        CXX="xcrun --sdk iphonesimulator clang++ -arch $arch $IOSMV --sysroot=$SDK -isystem $SDK/usr/include -fembed-bitcode" \
        LDFLAGS="-Wl" \
        ./configure \
        --host=arm-apple-darwin \
        --prefix=$DEST \
        --disable-shared
        ;;
    *)
        arch=x86_64
        IOSMV=" -mios-simulator-version-min=7.0"
        echo ""
        echo ""
        echo ""
        echo "******** Building opencore-amr for iPhoneSimulator $arch ********"
        PATH=`xcodebuild -version -sdk iphonesimulator PlatformPath`"/Developer/usr/bin:$PATH" \
        CXX="xcrun --sdk iphonesimulator clang++ -arch $arch $IOSMV -fembed-bitcode" \
        ./configure \
        --host=$arch \
        --prefix=$DEST \
        --disable-shared
        ;;
    esac
    make -j10
    make install
    mkdir -p $DEST/lib/$target/
    for i in $LIBS; do
        mv $DEST/lib/lib$i.a $DEST/lib/$target/
    done
done

echo ""
echo ""
echo ""
echo "******** Create xcframework.********"

mkdir -p $DEST/lib/universal_sim
mkdir -p $DEST/output

for i in $LIBS; do
lipo -create -output $DEST/lib/universal_sim/lib$i.a $DEST/lib/x86_64/lib$i.a $DEST/lib/arm64_sim/lib$i.a
input="-library $DEST/lib/arm64/lib$i.a -headers $DEST/include/$i -library $DEST/lib/universal_sim/lib$i.a -headers $DEST/include/$i"
  xcodebuild -create-xcframework $input -output $DEST/output/$i.xcframework
open $DEST/output
done
