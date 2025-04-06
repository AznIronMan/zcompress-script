#!/bin/bash
set -e
set -o pipefail
progress_pid=""
show_progress() {
    kill_progress
    local msg="$1"
    echo -n "$msg " >&2
    while true; do
        echo -n "." >&2
        sleep 0.5
    done
}
kill_progress() {
    if [ -n "$progress_pid" ]; then
        kill "$progress_pid" 2>/dev/null || true
        wait "$progress_pid" 2>/dev/null || true
        echo >&2
        progress_pid=""
    fi
}
error_exit() {
    kill_progress
    echo "❌ [ERROR] $1"
    exit 1
}
warn() {
    kill_progress
    echo "⚠️  [WARNING] $1"
    show_progress "$2" &
    progress_pid=$!
}
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS_NAME=$ID
            OS_VERSION=$VERSION_ID
            OS_TYPE="Linux"
        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            OS_NAME=$DISTRIB_ID
            OS_VERSION=$DISTRIB_RELEASE
            OS_TYPE="Linux"
        else
            OS_NAME="unknown-linux"
            OS_TYPE="Linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_NAME="macos"
        OS_TYPE="macOS"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        OS_NAME="windows"
        OS_TYPE="Windows"
    else
        OS_NAME="unknown"
        OS_TYPE="Unknown"
    fi
}
check_and_install_zopfli() {
    if command -v zopfli >/dev/null 2>&1; then
        return 0
    fi
    echo "❓ zopfli is not installed."
    case $OS_TYPE in
    "Linux")
        case $OS_NAME in
        "ubuntu" | "debian")
            echo "Would you like to install it using apt? (y/n)"
            read -r response
            [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] && sudo apt-get update && sudo apt-get install -y zopfli || error_exit "zopfli is required but not installed."
            ;;
        "fedora")
            echo "Would you like to install it using dnf? (y/n)"
            read -r response
            [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] && sudo dnf install -y zopfli || error_exit "zopfli is required but not installed."
            ;;
        "centos" | "rhel")
            echo "Would you like to install it using yum? (y/n)"
            read -r response
            [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] && sudo yum install -y zopfli || error_exit "zopfli is required but not installed."
            ;;
        "arch" | "manjaro")
            echo "Would you like to install it using pacman? (y/n)"
            read -r response
            [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]] && sudo pacman -Sy zopfli || error_exit "zopfli is required but not installed."
            ;;
        *)
            error_exit "zopfli is required. Please install it using your package manager."
            ;;
        esac
        ;;
    "macOS")
        echo "Would you like to install it using Homebrew? (y/n)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            command -v brew >/dev/null 2>&1 || error_exit "Homebrew is not installed. Please install it first: https://brew.sh/"
            brew install zopfli
        else
            error_exit "zopfli is required but not installed."
        fi
        ;;
    "Windows")
        echo "zopfli can be installed on Windows via:"
        echo "1. Windows Subsystem for Linux (WSL)"
        echo "2. MSYS2/MinGW (pacman -Sy zopfli)"
        echo "3. Compiling from source: https://github.com/google/zopfli"
        error_exit "Please install zopfli and try again."
        ;;
    *)
        error_exit "Unsupported operating system. Please install zopfli manually."
        ;;
    esac
    command -v zopfli >/dev/null 2>&1 || error_exit "zopfli installation failed. Please install it manually."
}
detect_os
check_and_install_zopfli
OUTPUT_DIR="."
COMPRESSION_LEVEL=15
PRESERVE_PERMISSIONS=false
while getopts ":o:c:p" opt; do
    case ${opt} in
    o)
        OUTPUT_DIR="$OPTARG"
        ;;
    c)
        if ! [[ "$OPTARG" =~ ^[0-9]+$ ]] || [ "$OPTARG" -lt 1 ] || [ "$OPTARG" -gt 100 ]; then
            error_exit "Compression level must be a number between 1 and 100."
        fi
        COMPRESSION_LEVEL="$OPTARG"
        ;;
    p)
        PRESERVE_PERMISSIONS=true
        ;;
    \?)
        error_exit "Invalid option: -$OPTARG. Usage: $0 [-o output_dir] [-c compression_level] [-p] archive_name target1 [target2 ... targetN]"
        ;;
    :)
        error_exit "Option -$OPTARG requires an argument."
        ;;
    esac
done
shift $((OPTIND - 1))
if [ "$#" -lt 2 ]; then
    error_exit "Insufficient arguments. Usage: $0 [-o output_dir] [-c compression_level] [-p] archive_name target1 [target2 ... targetN]"
fi
ARCHIVE_NAME="$1"
shift
TARGETS=("$@")
if [ ! -d "$OUTPUT_DIR" ]; then
    error_exit "Output directory '$OUTPUT_DIR' does not exist."
fi
TMPDIR=$(mktemp -d)
TAR_PATH="$OUTPUT_DIR/${ARCHIVE_NAME}.tar"
GZ_PATH="$TAR_PATH.gz"
trap 'kill_progress; rm -rf "$TMPDIR"; rm -f "$TAR_PATH" 2>/dev/null' EXIT INT TERM
echo "Starting compression process..."
show_progress "Copying files" &
progress_pid=$!
for target in "${TARGETS[@]}"; do
    if [ ! -e "$target" ]; then
        warn "$target does not exist. Skipping." "Copying files"
        continue
    fi
    BASENAME=$(basename "$target")
    cp -a "$target" "$TMPDIR/$BASENAME" || error_exit "Failed to copy $target."
    if ! $PRESERVE_PERMISSIONS; then
        chmod -R u+rw,go-w "$TMPDIR/$BASENAME" || error_exit "Failed to set permissions for $target."
    fi
done
kill_progress
show_progress "Creating archive" &
progress_pid=$!
tar -cf "$TAR_PATH" -C "$TMPDIR" . || error_exit "Failed to create tar archive."
kill_progress
show_progress "Compressing with zopfli (this may take a while)" &
progress_pid=$!
zopfli --i$COMPRESSION_LEVEL "$TAR_PATH" || error_exit "Failed to compress with zopfli."
kill_progress
show_progress "Verifying archive" &
progress_pid=$!
gzip -t "$GZ_PATH" || error_exit "Archive verification failed."
kill_progress
rm -f "$TAR_PATH" || warn "Failed to remove temporary tar file." "Finalizing"
kill_progress
ORIGINAL_SIZE=$(du -sh "$TMPDIR" | awk '{print $1}')
COMPRESSED_SIZE=$(du -h "$GZ_PATH" | awk '{print $1}')
echo "✅ [SUCCESS] Done: $GZ_PATH"
echo "  📦 Original size: $ORIGINAL_SIZE"
echo "  🗜️  Compressed size: $COMPRESSED_SIZE"
