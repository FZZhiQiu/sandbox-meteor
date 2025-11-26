#!/data/data/com.termux/files/usr/bin/bash
# SandboxRadar 自动创建工程脚本
# 适用于 Termux
# 作者: FZQ
# 使用方法: 保存为 create_sandboxradar.sh -> chmod +x create_sandboxradar.sh -> ./create_sandboxradar.sh

# 工程根目录
PROJECT_DIR=~/SandboxRadarApp

# 删除已有工程
rm -rf "$PROJECT_DIR"

# 创建目录结构
mkdir -p "$PROJECT_DIR/app/src/main/java/com/fzq/sandboxradar"
mkdir -p "$PROJECT_DIR/app/src/main/assets"
mkdir -p "$PROJECT_DIR/app/src/main/res/layout"
mkdir -p "$PROJECT_DIR/app/src/main/res/values"

# 1. MainActivity.java
cat > "$PROJECT_DIR/app/src/main/java/com/fzq/sandboxradar/MainActivity.java" <<EOF
package com.fzq.sandboxradar;

import android.os.Bundle;
import android.webkit.WebView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    WebView webView;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        webView = findViewById(R.id.webview);
        webView.getSettings().setJavaScriptEnabled(true);
        webView.loadUrl("file:///android_asset/sandbox_radar.html");
    }
}
EOF

# 2. activity_main.xml
cat > "$PROJECT_DIR/app/src/main/res/layout/activity_main.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<RelativeLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <WebView
        android:id="@+id/webview"
        android:layout_width="match_parent"
        android:layout_height="match_parent"/>
</RelativeLayout>
EOF

# 3. styles.xml
cat > "$PROJECT_DIR/app/src/main/res/values/styles.xml" <<EOF
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.Light.NoActionBar">
    </style>
</resources>
EOF

# 4. AndroidManifest.xml
cat > "$PROJECT_DIR/app/src/main/AndroidManifest.xml" <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.fzq.sandboxradar">

    <application
        android:allowBackup="true"
        android:label="SandboxRadar"
        android:icon="@mipmap/ic_launcher"
        android:theme="@style/AppTheme">
        <activity android:name=".MainActivity"
            android:screenOrientation="landscape"
            android:configChanges="orientation|screenSize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

# 5. build.gradle (Module)
cat > "$PROJECT_DIR/app/build.gradle" <<EOF
apply plugin: 'com.android.application'

android {
    compileSdkVersion 29
    defaultConfig {
        applicationId "com.fzq.sandboxradar"
        minSdkVersion 21
        targetSdkVersion 29
        versionCode 1
        versionName "1.0"
    }
    buildTypes {
        release {
            minifyEnabled false
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.3.1'
}
EOF

# 6. settings.gradle
cat > "$PROJECT_DIR/settings.gradle" <<EOF
include ':app'
EOF

# 7. sandbox_radar.html (占位示例)
cat > "$PROJECT_DIR/app/src/main/assets/sandbox_radar.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>沙盒气象雷达模拟器</title>
</head>
<body>
<h1>沙盒气象雷达模拟器 - 示例 HTML</h1>
<p>请替换为你的完整雷达 HTML 内容</p>
</body>
</html>
EOF

echo "✅ SandboxRadar 工程创建完成: $PROJECT_DIR"
echo "你可以在 AIDE 中打开此文件夹，或用 Gradle 终端编译 APK"
