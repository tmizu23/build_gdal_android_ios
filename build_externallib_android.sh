#!/bin/sh

set -e

####################################
# you need execute it manually with sudo on wsl2

# apt-get update -y

# pkg-config sqlite3 for proj compilation
# DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
#     wget unzip ccache curl ca-certificates \
#     pkg-config make binutils sqlite3 swig openjdk-17-jdk ant \
#     automake
####################################

export WORK_DIR=$PWD/work
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

if test -f "$WORK_DIR/ccache.tar.gz"; then
    echo "Restoring ccache..."
    (cd $HOME && tar xzf "$WORK_DIR/ccache.tar.gz")
fi

# We need a recent cmake for recent NDK versions
# 
wget -q https://github.com/Kitware/CMake/releases/download/v3.28.3/cmake-3.28.3-linux-x86_64.tar.gz
tar xzf cmake-3.28.3-linux-x86_64.tar.gz
export PATH=$WORK_DIR/cmake-3.28.3-linux-x86_64/bin:$PATH

# Download Android NDK
wget -q https://dl.google.com/android/repository/android-ndk-r26b-linux.zip
unzip -q android-ndk-r26b-linux.zip

export ANDROID_NDK=$WORK_DIR/android-ndk-r26b
export NDK_TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64
PREFIX=$WORK_DIR/install/android_arm64

ccache -M 1G
ccache -s

# sqlite3
wget -q https://sqlite.org/2022/sqlite-autoconf-3370200.tar.gz
tar xzf sqlite-autoconf-3370200.tar.gz
cd sqlite-autoconf-3370200
CC="ccache $NDK_TOOLCHAIN/bin/aarch64-linux-android24-clang" ./configure \
  --prefix=$PREFIX --host=aarch64-linux-android24
make -j$(nproc)
make install
cd ..

# proj
wget -q https://download.osgeo.org/proj/proj-9.0.0.tar.gz
tar xzf proj-9.0.0.tar.gz
cd proj-9.0.0
mkdir build
cd build
# See later comment in GDAL build section about MAKE_FIND_ROOT_PATH_MODE_INCLUDE, CMAKE_FIND_ROOT_PATH_MODE_LIBRARY
cmake .. \
  -DUSE_CCACHE=ON \
  -DENABLE_TIFF=OFF -DENABLE_CURL=OFF -DBUILD_APPS=OFF -DBUILD_TESTING=OFF \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_SYSTEM_NAME=Android \
  -DCMAKE_ANDROID_NDK=$ANDROID_NDK \
  -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
  -DCMAKE_SYSTEM_VERSION=24 \
  "-DCMAKE_PREFIX_PATH=$PREFIX;$NDK_TOOLCHAIN/sysroot/usr/" \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=NEVER \
  -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=NEVER \
  -DEXE_SQLITE3=/usr/bin/sqlite3
make -j$(nproc)
make install
cd ../../..

#Pdfium
# 別途ビルドして、installディレクトリのパスを指定
# https://github.com/tmizu23/pdfium_build_gdal_3_8/blob/android_ios/build_android.sh

PDFium_DIR=$WORK_DIR/../../pdfium_build_gdal_3_8/install

cp $PDFium_DIR/arm64/lib/libpdfium.a $PREFIX/lib/libpdfium.a
cp -r $PDFium_DIR/arm64/include/pdfium $PREFIX/include/pdfium

ccache -s

echo "Saving ccache..."
rm -f "$WORK_DIR/ccache.tar.gz"
(cd $HOME && tar czf "$WORK_DIR/ccache.tar.gz" .ccache)


