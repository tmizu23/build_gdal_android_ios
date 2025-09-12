#!/bin/sh

WORK_DIR=$PWD/work
cd $WORK_DIR

#
rm -rf xcf_temp
mkdir -p xcf_temp/iphoneos/lib xcf_temp/iphonesimulator/lib

lipo -create -output xcf_temp/iphoneos/lib/libsqlite3.a install/iphoneos_arm64/lib/libsqlite3.a
lipo -create -output xcf_temp/iphonesimulator/lib/libsqlite3.a install/iphonesimulator_arm64/lib/libsqlite3.a install/iphonesimulator_x86_64/lib/libsqlite3.a
lipo -create -output xcf_temp/iphoneos/lib/libproj.a install/iphoneos_arm64/lib/libproj.a
lipo -create -output xcf_temp/iphonesimulator/lib/libproj.a install/iphonesimulator_arm64/lib/libproj.a install/iphonesimulator_x86_64/lib/libproj.a
lipo -create -output xcf_temp/iphoneos/lib/libgdal.a install/iphoneos_arm64/lib/libgdal.a
lipo -create -output xcf_temp/iphonesimulator/lib/libgdal.a install/iphonesimulator_arm64/lib/libgdal.a install/iphonesimulator_x86_64/lib/libgdal.a
lipo -create -output xcf_temp/iphoneos/lib/libpdfium.a install/iphoneos_arm64/lib/libpdfium.a
lipo -create -output xcf_temp/iphonesimulator/lib/libpdfium.a install/iphonesimulator_arm64/lib/libpdfium.a install/iphonesimulator_x86_64/lib/libpdfium.a

mkdir -p xcf_temp/include_sqlite3 xcf_temp/include_proj xcf_temp/include_gdal xcf_temp/include_pdfium
cp -r install/iphoneos_arm64/include/* xcf_temp/include_gdal/
mv xcf_temp/include_gdal/sqlite3* xcf_temp/include_sqlite3/
mv xcf_temp/include_gdal/proj* xcf_temp/include_proj/
mv xcf_temp/include_gdal/pdfium xcf_temp/include_pdfium/

# ライブラリとプラットフォームの配列を定義
libraries=("sqlite3" "proj" "gdal" "pdfium")
platforms=("iphoneos" "iphonesimulator")

# フレームワークの作成とxcframeworkの作成を自動化
for lib in "${libraries[@]}"; do
  for platform in "${platforms[@]}"; do
    FRAMEPATH="xcf_temp/${platform}/${lib}.framework"
    mkdir -p "${FRAMEPATH}/Versions/A/Headers"
    ln -sfh "A" "${FRAMEPATH}/Versions/Current"
    ln -shf "Versions/Current/Headers" "${FRAMEPATH}/Headers"
    ln -sfh "Versions/Current/${lib}" "${FRAMEPATH}/${lib}"
    cp -a "xcf_temp/include_${lib}/" "${FRAMEPATH}/Versions/A/Headers"
    cp -a "xcf_temp/${platform}/lib/lib${lib}.a" "${FRAMEPATH}/Versions/A/${lib}"
  done

  # XCFrameworkの作成
  mkdir -p install/xcf
  xcodebuild -create-xcframework \
  -framework "xcf_temp/iphoneos/${lib}.framework" \
  -framework "xcf_temp/iphonesimulator/${lib}.framework" \
  -output "install/xcf/${lib}.xcframework"
done

