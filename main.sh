#!/data/data/com.termux/files/usr/bin/sh

JAVA_PATH="${PREFIX}/lib/jvm/java-21-openjdk"
ANDROID_SDK_DIR="$HOME/android-sdk"
SDK_ZIP_URL="https://github.com/mikailamin-master/android_sdk_termux/releases/download/android_sdk_with_cmdline/android-sdk.zip"
SDK_ZIP_FILE="$HOME/android-sdk.zip"
TMP_DIR="$HOME/.android_sdk_tmp"
BASHRC_FILE="$HOME/.bashrc"

# ---- auto yes flag ----
auto_yes=0
if [ "$1" = "-y" ]; then
    auto_yes=1
fi

# ---- confirm helper ----
confirm() {
    if [ "$auto_yes" = "1" ]; then
        return 0
    fi

    printf "%s (y/n): " "$1"
    read ans
    case "$ans" in
        y|Y) return 0 ;;
        *) return 1 ;;
    esac
}

# ---- java check ----
if ! command -v java >/dev/null 2>&1
then
    echo "[W] | java not installed!"

    if confirm "install openjdk 21?"
    then
        apt update -y || exit 1
        apt install openjdk-21 -y || exit 1
    else
        echo "[ABORT] | java required!"
        exit 1
    fi
fi

echo "[S] | java installed!"

# ---- android sdk check ----
if [ ! -d "$ANDROID_SDK_DIR" ]
then
    echo "[W] | android-sdk not found!"

    if confirm "download android-sdk?"
    then
        apt install wget unzip -y || exit 1

        rm -rf "$TMP_DIR"
        mkdir -p "$TMP_DIR"

        wget -O "$SDK_ZIP_FILE" "$SDK_ZIP_URL" || exit 1
        unzip "$SDK_ZIP_FILE" -d "$TMP_DIR" || exit 1

        mv "$TMP_DIR" "$ANDROID_SDK_DIR" || exit 1

        rm -rf "$TMP_DIR"
        rm -f "$SDK_ZIP_FILE"
    else
        echo "[ABORT] | android-sdk required!"
        exit 1
    fi
fi

echo "[S] | android-sdk ready!"

# ---- bashrc helper ----
add_line() {
    if ! grep -q "$1" "$BASHRC_FILE" 2>/dev/null
    then
        echo "$1" >> "$BASHRC_FILE"
    fi
}

# ---- bashrc exports ----
add_line "export JAVA_HOME=${JAVA_PATH}"
add_line "export PATH=${JAVA_PATH}/bin:\$PATH"
add_line "export ANDROID_SDK_ROOT=${ANDROID_SDK_DIR}"
add_line "export ANDROID_HOME=${ANDROID_SDK_DIR}"
add_line "export PATH=\${ANDROID_HOME}/cmdline-tools/latest/bin:\${ANDROID_HOME}/platform-tools:\$PATH"

# ---- current session ----
export JAVA_HOME="${JAVA_PATH}"
export PATH="${JAVA_PATH}/bin:${PATH}"
export ANDROID_SDK_ROOT="${ANDROID_SDK_DIR}"
export ANDROID_HOME="${ANDROID_SDK_DIR}"
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools:${PATH}"

# ---- chmod cmdline-tools ----
if [ -d "${ANDROID_HOME}/cmdline-tools/latest/bin" ]; then
    for file in "${ANDROID_HOME}/cmdline-tools/latest/bin/"*; do
        chmod +x "$file"
    done
fi

# ---- sdkmanager install ----
if command -v sdkmanager >/dev/null 2>&1
then
    echo "[S] | sdkmanager found!"

    if confirm "accept sdk licenses?"
    then
        yes | sdkmanager --licenses || exit 1
    fi

    echo "[I] | installing platform and build-tools"
    sdkmanager "platforms;android-34" || exit 1
    sdkmanager "build-tools;35.0.0" || exit 1

    # chmod platform-tools + build-tools
    for dir in "${ANDROID_HOME}/platform-tools" "${ANDROID_HOME}/build-tools/35.0.0"; do
        if [ -d "$dir" ]; then
            for file in "$dir"/*; do
                chmod +x "$file"
            done
        fi
    done

else
    echo "[W] | sdkmanager not found!"
fi

# ---- aapt2 fix ----
AAPT2_PATH="${ANDROID_HOME}/build-tools/34.0.4/aapt2"

if [ -f "$AAPT2_PATH" ]; then
    chmod +x "$AAPT2_PATH"

    mkdir -p "$HOME/.gradle"
    GRADLE_FILE="$HOME/.gradle/gradle.properties"

    touch "$GRADLE_FILE"

    if ! grep -q "android.aapt2FromMavenOverride" "$GRADLE_FILE"; then
        echo "android.aapt2FromMavenOverride=$AAPT2_PATH" >> "$GRADLE_FILE"
    fi
fi

echo "[SUCCESS] | java + android sdk fully configured!"
echo "run: source ~/.bashrc"
        fi
    done

else
    echo "[W] | sdkmanager not found!"
fi

chmod +x /data/data/com.termux/files/home/android-sdk/build-tools/34.0.4/aapt2

mkdir .gradle
touch .gradle/gradle.properties
echo "android.aapt2FromMavenOverride=/data/data/com.termux/files/home/android-sdk/build-tools/34.0.4/aapt2" >> .gradle/gradle.properties

echo "[SUCCESS] | java + android sdk fully configured!"
echo "run: source ~/.bashrc"
