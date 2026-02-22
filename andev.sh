#!/bin/bash

# Configuration
IMAGE_NAME="localhost/android-dev-env"
PROJECT_DIR=$(pwd)

# Ensure local cache folder exists
mkdir -p "$PROJECT_DIR/.cache/gradle"

case "$1" in
  build-env)
    echo "🚀 Building Podman environment..."
    podman build -t $IMAGE_NAME .
    ;;

  init)
    # --- Interactive Inputs ---
    read -p "📦 Enter Package Name [com.example.myapp]: " INPUT_PACKAGE
    PACKAGE_NAME=${INPUT_PACKAGE:-"com.example.myapp"}

    read -p "💻 Choose Language (java/kotlin) [kotlin]: " INPUT_LANG
    LANG=${INPUT_LANG:-"kotlin"}
    
    APP_NAME="MyIsolatedApp"
    PACKAGE_PATH=${PACKAGE_NAME//./\/}

    echo "🏗️  Phase 1: Generating Android Boilerplate ($LANG)..."
    
    # 1. Create Folder Structure
    mkdir -p "app/src/main/res/layout"
    mkdir -p "app/src/main/res/values"

    # 2. Language Specific Logic
    if [ "$LANG" == "kotlin" ]; then
        SRC_DIR="app/src/main/java/$PACKAGE_PATH"
        mkdir -p "$SRC_DIR"
        EXT="kt"
        
        # Kotlin MainActivity
        cat <<EOF > "$SRC_DIR/MainActivity.kt"
package $PACKAGE_NAME
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import android.widget.TextView

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this)
        tv.text = "Hello from Kotlin!"
        setContentView(tv)
    }
}
EOF
        # Kotlin Plugins
        PLUGINS_BLOCK="id(\"com.android.application\")\n    id(\"org.jetbrains.kotlin.android\")"
        ROOT_PLUGINS="id(\"com.android.application\") version \"8.2.2\" apply false\n    id(\"org.jetbrains.kotlin.android\") version \"1.9.22\" apply false"
    else
        SRC_DIR="app/src/main/java/$PACKAGE_PATH"
        mkdir -p "$SRC_DIR"
        EXT="java"

        # Java MainActivity
        cat <<EOF > "$SRC_DIR/MainActivity.java"
package $PACKAGE_NAME;
import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        TextView tv = new TextView(this);
        tv.setText("Hello from Java!");
        setContentView(tv);
    }
}
EOF
        # Java only Plugins
        PLUGINS_BLOCK="id(\"com.android.application\")"
        ROOT_PLUGINS="id(\"com.android.application\") version \"8.2.2\" apply false"
    fi

    # 3. Create common config files
    cat <<EOF > gradle.properties
android.useAndroidX=true
android.nonTransitiveRClass=true
org.gradle.jvmargs=-Xmx2048m
EOF

    cat <<EOF > settings.gradle.kts
pluginManagement {
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories { google(); mavenCentral() }
}
rootProject.name = "$APP_NAME"
include(":app")
EOF

    cat <<EOF > build.gradle.kts
plugins {
    $(echo -e "$ROOT_PLUGINS")
}
EOF

    cat <<EOF > app/build.gradle.kts
plugins {
    $(echo -e "$PLUGINS_BLOCK")
}

android {
    namespace = "$PACKAGE_NAME"
    compileSdk = 34
    defaultConfig {
        applicationId = "$PACKAGE_NAME"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    $( [ "$LANG" == "kotlin" ] && echo -e "kotlinOptions {\n        jvmTarget = \"17\"\n    }" )
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.11.0")
}
EOF

    cat <<EOF > app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" package="$PACKAGE_NAME">
    <application android:label="$APP_NAME" android:theme="@style/Theme.AppCompat.Light.DarkActionBar">
        <activity android:name=".MainActivity" android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

    echo "🏗️  Phase 2: Generating Gradle Wrapper..."
    podman run --rm \
      --userns=host \
      -v "$PROJECT_DIR":/workspace:z \
      --workdir /workspace \
      -e GRADLE_USER_HOME=/workspace/.cache/gradle \
      $IMAGE_NAME gradle wrapper --no-daemon
    
    chmod +x gradlew 2>/dev/null
    echo "✅ Project initialized for $LANG ($PACKAGE_NAME)!"
    ;;

  compile)
    echo "⚙️  Compiling APK..."
    podman run --rm -it \
      --userns=host \
      -v "$PROJECT_DIR":/workspace:z \
      --workdir /workspace \
      -e GRADLE_USER_HOME=/workspace/.cache/gradle \
      $IMAGE_NAME ./gradlew assembleDebug --no-daemon --console=plain --no-watch-fs
    
    echo "🚀 Build Finished! Check app/build/outputs/apk/debug/"
    ;;

  clean)
    echo "🧹 Cleaning..."
    rm -rf .gradle .cache/gradle app build build.gradle.kts settings.gradle.kts gradle.properties gradlew gradlew.bat gradle/
    ;;

  *)
    echo "Usage: $0 {build-env|init|compile|clean}"
    ;;
esac
