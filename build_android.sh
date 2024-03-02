#!/bin/sh

set -e

export WORK_DIR=$PWD/work
export PATH=$WORK_DIR/cmake-3.28.3-linux-x86_64/bin:$PATH
export ANDROID_NDK=$WORK_DIR/android-ndk-r26b
export NDK_TOOLCHAIN=$ANDROID_NDK/toolchains/llvm/prebuilt/linux-x86_64

PATCH="$PWD/build_android.patch"

cd $WORK_DIR
# gdal
# for build gdal 3.8 with pdfium,
# commit e0db75a9034891a24e5fb2d0fbc83fbbc8cde7ed
git clone https://github.com/OSGeo/gdal.git

cd $WORK_DIR/gdal
git checkout e0db75a9034891a24e5fb2d0fbc83fbbc8cde7ed
git apply $PATCH

if test -f "$WORK_DIR/ccache.tar.gz"; then
    echo "Restoring ccache..."
    (cd $HOME && tar xzf "$WORK_DIR/ccache.tar.gz")
fi

ccache -M 1G
ccache -s


# Build GDAL
PREFIX=$WORK_DIR/install/android_arm64
GDAL_BUILD_DIR="$WORK_DIR/gdal/build_arm64"

mkdir -p $GDAL_BUILD_DIR
cd $GDAL_BUILD_DIR

# PKG_CONFIG_LIBDIR, CMAKE_FIND_ROOT_PATH_MODE_INCLUDE, CMAKE_FIND_ROOT_PATH_MODE_LIBRARY, CMAKE_FIND_USE_CMAKE_SYSTEM_PATH
# are needed because we don't install dependencies (PROJ, SQLite3) in the NDK sysroot
# This is definitely not the most idiomatic way of proceeding...
PKG_CONFIG_LIBDIR=$PREFIX/lib/pkgconfig cmake --fresh .. \
 -DUSE_CCACHE=ON \
 -DCMAKE_INSTALL_PREFIX=$PREFIX \
 -DCMAKE_SYSTEM_NAME=Android \
 -DCMAKE_ANDROID_NDK=$ANDROID_NDK \
 -DCMAKE_ANDROID_ARCH_ABI=arm64-v8a \
 -DCMAKE_SYSTEM_VERSION=24 \
 "-DCMAKE_PREFIX_PATH=$PREFIX;$NDK_TOOLCHAIN/sysroot/usr/" \
 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=NEVER \
 -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=NEVER \
 -DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=NO \
 -DSFCGAL_CONFIG=disabled \
 -DHDF5_C_COMPILER_EXECUTABLE=disabled \
 -DHDF5_CXX_COMPILER_EXECUTABLE=disabled \
 -DBUILD_JAVA_BINDINGS=ON \
 -DGDAL_JAVA_INSTALL_DIR=$PREFIX/java \
 -DGDAL_JAVA_JNI_INSTALL_DIR=$PREFIX/lib/jni \
 -DBUILD_APPS=OFF \
 -DBUILD_PYTHON_BINDINGS=OFF \
 -DBUILD_TESTING=OFF \
 -DGDAL_BUILD_OPTIONAL_DRIVERS=OFF \
 -DOGR_BUILD_OPTIONAL_DRIVERS=OFF \
 -DGDAL_USE_EXTERNAL_LIBS=OFF \
 -DGDAL_USE_ZLIB=OFF \
 -DGDAL_USE_LIBKML=OFF \
 -DGDAL_USE_PDFIUM=ON 

make -j$(nproc)
make install
cd ..

ccache -s

echo "Saving ccache..."
rm -f "$WORK_DIR/ccache.tar.gz"
(cd $HOME && tar czf "$WORK_DIR/ccache.tar.gz" .ccache)
