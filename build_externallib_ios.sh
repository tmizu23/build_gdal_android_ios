#!/bin/sh
WORK_DIR=$PWD/work
mkdir -p $WORK_DIR
cd $WORK_DIR

# get cmake toolchain for ios
git clone https://github.com/leetal/ios-cmake.git

###### download library ######
# sqlite
git clone https://github.com/azadkuh/sqlite-amalgamation.git
# proj
wget -q https://download.osgeo.org/proj/proj-9.0.0.tar.gz
tar xzf proj-9.0.0.tar.gz

#pdfium
# 別途ビルドして、installディレクトリのパスを指定
# https://github.com/tmizu23/pdfium_build_gdal_3_8/blob/android_ios/build_ios.sh

PDFium_DIR=/Users/mizutani/prg/pdfium_build_gdal_3_8/install

CMTOOLCHAIN=$WORK_DIR/ios-cmake/ios.toolchain.cmake

CONFIGURATIONS="iphoneos_arm64 iphonesimulator_arm64 iphonesimulator_x86_64"
for CONFIG in $CONFIGURATIONS; do
    echo "#############################"
    echo "CONFIG: $CONFIG"
    echo "#############################"
    if [ "$CONFIG" = "iphoneos_arm64" ]; then
        PREFIX="$WORK_DIR/install/$CONFIG"
        SDKPATH=$(xcrun --sdk iphoneos --show-sdk-path)
        OS="OS64"
        PDFium_PALTFORM="device"
    elif [ "$CONFIG" = "iphonesimulator_arm64" ]; then
        PREFIX="$WORK_DIR/install/$CONFIG"
        SDKPATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
        OS="SIMULATORARM64"
        PDFium_PALTFORM="simulator"
    elif [ "$CONFIG" = "iphonesimulator_x86_64" ]; then
        PREFIX="$WORK_DIR/install/$CONFIG"
        SDKPATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
        OS="SIMULATOR64"
        PDFium_PALTFORM="simulator"
    fi

    # # build sqlite3
    cd $WORK_DIR/sqlite-amalgamation
    rm -r build_$OS; mkdir build_$OS; cd build_$OS
    cmake -DCMAKE_TOOLCHAIN_FILE=$CMTOOLCHAIN \
        -DPLATFORM=$OS \
        -DENABLE_BITCODE=OFF \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DBUILD_SHARED_LIBS=OFF \
        -DSQLITE_ENABLE_RTREE=ON \
        -DSQLITE_ENABLE_COLUMN_METADATA=ON \
        -DSQLITE_OMIT_DECLTYPE=OFF \
        ..
    cmake --build . -j$(sysctl -n hw.ncpu)
    cmake --build . --target install

    # build proj
    cd $WORK_DIR/proj-9.0.0
    rm -r build_$OS; mkdir build_$OS; cd build_$OS
    cmake -DCMAKE_TOOLCHAIN_FILE=$CMTOOLCHAIN \
        -DPLATFORM=$OS \
        -DENABLE_BITCODE=OFF \
        -DBUILD_SHARED_LIBS=OFF \
        -DCMAKE_INSTALL_PREFIX=$PREFIX \
        -DENABLE_TIFF=OFF -DENABLE_CURL=OFF \
        -DBUILD_PROJSYNC=OFF \
        -DSQLITE3_INCLUDE_DIR=$PREFIX/include \
        -DSQLITE3_LIBRARY=$PREFIX/lib/libsqlite3.a \
        ..
    cmake --build . -j$(sysctl -n hw.ncpu)
    cmake --build . --target install
    
    # #copy pdfium
    cp $PDFium_DIR/${CONFIG}/lib/libpdfium.a $PREFIX/lib/libpdfium.a
    cp -r $PDFium_DIR/${CONFIG}/include/pdfium $PREFIX/include/pdfium

done

cd $WORK_DIR




