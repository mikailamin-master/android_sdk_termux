#!/data/data/com.termux/files/usr/bin/sh
set -e

JAVA_PATH="${PREFIX}/lib/jvm/java-21-openjdk"
ANDROID_SDK_DIR="$HOME/android-sdk"
ANDROID_HOME="$ANDROID_SDK_DIR"
ANDROID_SDK_ROOT="$ANDROID_SDK_DIR"

SDK_ZIP_URL="https://github.com/mikailamin-master/android_sdk_termux/releases/download/android_sdk_with_cmdline/android-sdk.zip"
SDK_ZIP_FILE="$HOME/android-sdk.zip"

TMP_DIR="$HOME/.android_sdk_tmp"
BASHRC_FILE="$HOME/.bashrc"

ANDROID_PLATFORM="34"
BUILD_TOOLS_VERSION="35.0.0"

auto_yes=0

if [ "$1" = "-y" ]; then
    auto_yes=1
fi

confirm() {
    if [ "$auto_yes" = "1" ]; then
        return 0
    fi

    printf "%s (y/n): " "$1"
    read ans

    case "$ans" in
        y|Y)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

add_line() {
    line="$1"

    if ! grep -Fqx "$line" "$BASHRC_FILE" 2>/dev/null; then
        echo "$line" >> "$BASHRC_FILE"
    fi
}

install_pkg() {
    pkg install -y "$@"
}

if ! command -v java >/dev/null 2>&1; then
    echo "[W] | java not installed!"

    if confirm "install openjdk 21?"; then
        pkg update -y
        install_pkg openjdk-21
    else
        echo "[ABORT] | java required!"
        exit 1
    fi
fi

echo "[S] | java installed!"

install_pkg wget unzip tar

if [ ! -d "$ANDROID_SDK_DIR" ]; then
    echo "[W] | android sdk not found!"

    if confirm "download android sdk?"; then
        rm -rf "$TMP_DIR"
        mkdir -p "$TMP_DIR"

        echo "[I] | downloading android sdk"

        wget -O "$SDK_ZIP_FILE" "$SDK_ZIP_URL"

        echo "[I] | extracting android sdk"

        unzip "$SDK_ZIP_FILE" -d "$TMP_DIR"

        extracted_dir="$(find "$TMP_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)"

        if [ -z "$extracted_dir" ]; then
            echo "[E] | extraction failed!"
            exit 1
        fi

        rm -rf "$ANDROID_SDK_DIR"
        mv "$extracted_dir" "$ANDROID_SDK_DIR"

        rm -rf "$TMP_DIR"
        rm -f "$SDK_ZIP_FILE"
    else
        echo "[ABORT] | android sdk required!"
        exit 1
    fi
fi

echo "[S] | android sdk ready!"

add_line ""
add_line "# android sdk"

add_line "export JAVA_HOME=${JAVA_PATH}"
add_line "export PATH=${JAVA_PATH}/bin:\$PATH"

add_line "export ANDROID_HOME=${ANDROID_HOME}"
add_line "export ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}"

add_line "export PATH=\${ANDROID_HOME}/cmdline-tools/latest/bin:\${ANDROID_HOME}/platform-tools:\$PATH"

export JAVA_HOME="${JAVA_PATH}"
export PATH="${JAVA_PATH}/bin:${PATH}"

export ANDROID_HOME="${ANDROID_HOME}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT}"

export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

CMDLINE_BIN="${ANDROID_HOME}/cmdline-tools/latest/bin"

if [ -d "$CMDLINE_BIN" ]; then
    chmod +x "$CMDLINE_BIN"/* || true
fi

if command -v sdkmanager >/dev/null 2>&1; then
    echo "[S] | sdkmanager found!"

    if confirm "accept sdk licenses?"; then
        yes | sdkmanager --licenses
    fi

    echo "[I] | installing platform"

    sdkmanager \
        --sdk_root="${ANDROID_HOME}" \
        "platforms;android-${ANDROID_PLATFORM}"

    echo "[I] | installing build tools"

    sdkmanager \
        --sdk_root="${ANDROID_HOME}" \
        "build-tools;${BUILD_TOOLS_VERSION}"

    echo "[I] | installing platform tools"

    sdkmanager \
        --sdk_root="${ANDROID_HOME}" \
        "platform-tools"

    for dir in \
        "${ANDROID_HOME}/platform-tools" \
        "${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}"
    do
        if [ -d "$dir" ]; then
            chmod +x "$dir"/* || true
        fi
    done
else
    echo "[W] | sdkmanager not found!"
fi

AAPT2_PATH="${ANDROID_HOME}/build-tools/${BUILD_TOOLS_VERSION}/aapt2"

if [ -f "$AAPT2_PATH" ]; then
    chmod +x "$AAPT2_PATH"

    mkdir -p "$HOME/.gradle"

    GRADLE_FILE="$HOME/.gradle/gradle.properties"

    touch "$GRADLE_FILE"

    if ! grep -Fq "android.aapt2FromMavenOverride" "$GRADLE_FILE"; then
        echo "android.aapt2FromMavenOverride=$AAPT2_PATH" >> "$GRADLE_FILE"
    fi
fi

if command -v adb >/dev/null 2>&1; then
    echo "[S] | adb ready!"
else
    echo "[W] | adb not found in path!"
fi

echo
echo "[SUCCESS] | java + android sdk fully configured!"
echo "run: source ~/.bashrc"
