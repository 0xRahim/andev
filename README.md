# Android Isolated Dev Env (Podman)

A lightweight, containerized Android development environment that allows you to initialize, write, and compile Android applications (Java or Kotlin) without installing the Android SDK, Java, or Gradle on your host machine.

## 🛠️ Prerequisites

* **Podman** installed and configured.
* **Internet Connection** (only for the first build and first compilation to download dependencies).

---

## Getting Started

### 1. Setup the Environment

First, build the container image that contains the Android SDK and Gradle.

```bash
chmod +x andev.sh
./andev.sh build-env

```

### 2. Initialize a Project

Create a fresh Android project boilerplate. The script will interactively ask for your **Package Name** and preferred **Language** (Java or Kotlin).

```bash
./andev.sh init

```

### 3. Compile the APK

Build your debug APK. All build caches are stored in a hidden `.cache` folder in your project directory to keep your host system clean while ensuring subsequent builds are fast.

```bash
./andev.sh compile

```

**Output Location:** `app/build/outputs/apk/debug/app-debug.apk`

---

## 📂 Project Structure

* `andev.sh`: The main control script.
* `Dockerfile`: Defines the build environment (Fedora-based).
* `.cache/gradle`: Local cache for Android SDK dependencies and Gradle.
* `app/src/main/`: Your application source code.

---

## ⚙️ Script Commands

| Command | Description |
| --- | --- |
| `build-env` | Builds the `localhost/android-dev-env` container image. |
| `init` | **Interactive.** Sets up package name, language, and folder structure. |
| `compile` | Runs the Gradle build process inside the container. |
| `clean` | Wipes build artifacts, Gradle wrappers, and local caches. |

---

## Troubleshooting

### "Stuck" on Compiling

The script uses `--userns=host` and `--no-watch-fs` to prevent Podman from hanging while mapping thousands of Android SDK files. If the build feels slow during the first run, it is likely downloading the Android libraries into your `.cache` folder.

### Permission Denied

If you cannot execute the generated `gradlew` file, the script attempts to fix this automatically, but you can manualy run:

```bash
chmod +x gradlew

```

### File System Warnings

You may see warnings regarding "File system watching." These are expected and safely ignored, as Gradle cannot "watch" files across a container mount point efficiently.

---

## License

This project is open-source. Feel free to modify the `andev.sh` script to suit your specific build needs!


