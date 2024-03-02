# How to build the GDAL for Android and iOS
## Android
- LinuxまたはWindowsのwsl2で実行。Android用のPDFiumのビルドはlinuxでしかサポートしてないため。
  
### PDFiumのビルド(Optional)
- PDFが必要な場合は、以下のコードをとってきて、``build_android.sh``を実行。install以下にPDFiumのlibとincludeが作成される。
- https://github.com/tmizu23/pdfium_build_gdal_3_8/tree/android_ios

### Proj,SQLite3のビルド
- ``build_externallib_android.sh``内のコメントアウトしてあるビルドに必要なツールを手動でインストールする。
- ``build_externallib_android.sh``を実行。work/install以下にlibとincludeが作成される。
- PDFiumを使う場合はスクリプト内のPDFiumのパスを設定してwork/install以下にlibとincludeを移動させる。

### GDALのビルド
- ``build_android.sh``を実行。work/install以下にgdalのlibとincludeが作成される。
- デフォルトでは、サポートするドライバは最小限＋PDF+PNG+SWIGとなっている。必要に応じてcmakeのオプションでドライバを追加する。
- オプションは以下を参考
https://gdal.org/development/building_from_source.html


### React Nativeでの利用方法
- React Native用のライブラリのテンプレートを以下のコマンドで作成
- npx create-react-native-library@latest react-native-gdalwarp --reactNativeVersion 0.72.4 --local
- modules/react-native-gdalwarp/android にlibsを作成
- libs直下にgdal-3.9.0.jarを入れる
- libs直下にarm64-v8aフォルダを作成
- arm64-v8aに作成したlibgdalalljni.so,libgdal.so,libproj.so,libsqlite3.so,libpdfium.aを入れる
- android/src/main にassetsフォルダを追加
- shareのgdaとprojフォルダをassetsにコピー
- build.gradleを修正
  - 追加 sourceSets {main {jniLibs.srcDir 'libs'}}
  - dependenciesに追加 implementation fileTree(dir: 'libs/', include: ['*.aar', '*.jar'], exclude: [])

- GdalwarpModule.javaのコードの中でassetsの中身をコピーするコードを追加

```
 AssetManager assetManager = reactContext.getAssets();
       String[] files = assetManager.list("proj");
       File projDir = new File(reactContext.getFilesDir(), "proj");
       if (!projDir.exists()) {
         projDir.mkdirs();
       }
       for (String filename : files) {
         Log.d(TAG, "PdfToImageModule: copy_proj_files: filename: " + filename);
         InputStream is = assetManager.open("proj/" + filename);
         OutputStream os = new FileOutputStream(new File(projDir, filename));
         byte[] buffer = new byte[1024];
         int length;
         while ((length = is.read(buffer)) > 0) {
           os.write(buffer, 0, length);
         }
         is.close();
         os.close();
       }
       gdal.SetConfigOption("PROJ_LIB", projDir.getAbsolutePath());
       Log.d(
         TAG,
         "PdfToImageModule: copy_proj_files: PROJ_LIB: " +
         projDir.getAbsolutePath()
       );
```

## iOS

### PDFiumのビルド(Optional)
- PDFが必要な場合は、以下のコードをとってきて、``build_ios.sh``を実行。install以下にPDFiumのlibとincludeが作成される。
- https://github.com/tmizu23/pdfium_build_gdal_3_8/tree/android_ios

### Proj,SQLite3のビルド
- ``build_externallib_ios.sh``内のコメントアウトしてあるビルドに必要なツールを手動でインストールする。
- ``build_externallib_ios.sh``を実行。work/install以下にlibとincludeが作成される。
- PDFiumを使う場合はスクリプト内のPDFiumのパスを設定してwork/install以下にlibとincludeを移動させる。

### GDALのビルド
- ``build_ios.sh``を実行。work/install以下にgdalのlibとincludeが作成される。
- デフォルトでは、サポートするドライバは最小限＋PDF+PNGとなっている。必要に応じてcmakeのオプションでドライバを追加する。
- オプションは以下を参考
https://gdal.org/development/building_from_source.html


### Frameworkの作成
- ``build_xcf_ios.sh``を実行。work/install/xcf以下にgdal,proj,sqlite3,pdfiumのxcframewrokが作成される。


### React Nativeでの利用方法
- React Native用のライブラリのテンプレートを以下のコマンドで作成
- npx create-react-native-library@latest react-native-gdalwarp --reactNativeVersion 0.72.4 --local
- ios内にFrameworksを作成して、gdal,proj,sqlite3,pdfiumのxcframeworksをコピー
- ios内にshareをコピー
- react-native-gdalwarp.podspecに以下を追加して ``ios/pod install``
```
s.vendored_frameworks = "ios/Frameworks/gdal.xcframework", "ios/Frameworks/proj.xcframework", "ios/Frameworks/sqlite3.xcframework", "ios/Frameworks/pdfium.xcframework"
```
```
  s.resources = "ios/share/**/*"
```  

- firebaseと共存させるには、利用するプロジェクトのPodfileのstatic_frameworkに'react-native-gdalwarp'を追加する。


## 参考
* https://github.com/paulocoutinhox/pdfium-lib
* https://gis.stackexchange.com/questions/434514/build-gdal-3-x-for-ios
* https://github.com/rouault/pdfium_build_gdal_3_8
* https://gdal.org/development/building_from_source.html
* https://chromium.googlesource.com/libyuv/libyuv/+/HEAD/docs/getting_started.md
  

 