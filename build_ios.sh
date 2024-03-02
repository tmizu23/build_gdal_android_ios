#!/bin/sh
WORK_DIR=$PWD/work
PATCH="$PWD/build_ios.patch"

cd $WORK_DIR

# gdal
# for build gdal 3.8 with pdfium,
# commit e0db75a9034891a24e5fb2d0fbc83fbbc8cde7ed
git clone https://github.com/OSGeo/gdal.git


cd $WORK_DIR/gdal
git checkout e0db75a9034891a24e5fb2d0fbc83fbbc8cde7ed
git apply $PATCH


CMTOOLCHAIN=$WORK_DIR/ios-cmake/ios.toolchain.cmake

CONFIGURATIONS="iphoneos_arm64 iphonesimulator_arm64"
for CONFIG in $CONFIGURATIONS; do
    echo "#############################"
    echo "CONFIG: $CONFIG"
    echo "#############################"
    if [ "$CONFIG" = "iphoneos_arm64" ]; then
        PREFIX="$WORK_DIR/install/$CONFIG"
        SDKPATH=$(xcrun --sdk iphoneos --show-sdk-path)
        OS="OS64"
        GDAL_BUILD_DIR="$WORK_DIR/gdal/build_${CONFIG}"
    elif [ "$CONFIG" = "iphonesimulator_arm64" ]; then
        PREFIX="$WORK_DIR/install/$CONFIG"
        SDKPATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
        OS="SIMULATORARM64"
        GDAL_BUILD_DIR="$WORK_DIR/gdal/build_${CONFIG}"
    fi

    rm -rf $GDAL_BUILD_DIR
    mkdir -p $GDAL_BUILD_DIR
    cd $GDAL_BUILD_DIR

    # CMakeによるビルド処理
    cmake --fresh -DCMAKE_TOOLCHAIN_FILE=$CMTOOLCHAIN \
        -DPLATFORM=$OS \
        -DENABLE_BITCODE=OFF \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_APPS=OFF \
        -DBUILD_PYTHON_BINDINGS=OFF \
        -DBUILD_TESTING=OFF \
        -DPROJ_ROOT=$PREFIX \
        -DSQLITE3_INCLUDE_DIR=$PREFIX/include \
        -DSQLITE3_LIBRARY=$PREFIX/lib/libsqlite3.a \
        -DIconv_INCLUDE_DIR=$SDKPATH/usr \
        -DIconv_LIBRARY=$SDKPATH/usr/lib/libiconv.tbd \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_DISABLE_FIND_PACKAGE_Arrow=ON \
        -DGDAL_BUILD_OPTIONAL_DRIVERS=OFF \
        -DOGR_BUILD_OPTIONAL_DRIVERS=OFF \
        -DGDAL_USE_EXTERNAL_LIBS=OFF \
        -DGDAL_USE_ZLIB=OFF \
        -DGDAL_USE_LIBKML=OFF \
        -DGDAL_ENABLE_DRIVER_PDF=ON \
        -DGDAL_USE_PDFIUM=ON \
        -DPDFIUM_INCLUDE_DIR=$PREFIX/include/pdfium \
        -DPDFIUM_LIBRARY=$PREFIX/lib/libpdfium.a \
        ..

    # ビルドとインストール
    cmake --build . -j$(sysctl -n hw.ncpu)
    cmake --build . --target install

    # 元のディレクトリに戻る
    cd ..
done
