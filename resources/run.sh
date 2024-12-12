#!/usr/bin/env bash
set -eu

main() {
  # START GENERATED CODE
  BBIN_ARGS=""
  # END GENERATED CODE

  if command -v uuidgen >/dev/null; then
    SCRIPT_ID=$(uuidgen)
  else
    SCRIPT_ID=$(cat /proc/sys/kernel/random/uuid)
  fi

  CACHE_DIR="${XDG_CACHE_HOME:-"$HOME/.cache"}/clj.sh"
  mkdir -p "$CACHE_DIR"

  export BABASHKA_BBIN_BIN_DIR="$CACHE_DIR/bbin/bin"
  export PATH="$CACHE_DIR/bb:$PATH"

  BB_VERSION="1.12.195"
  BB_CMD="$CACHE_DIR/bb/bb"

  BBIN_VERSION="0.2.4"
  BBIN_CMD="$BABASHKA_BBIN_BIN_DIR/bbin"

  if ! command -v java >/dev/null; then
    export JAVA_HOME="$CACHE_DIR/java"
    export PATH="$CACHE_DIR/java/bin:$PATH"

    if [ "$(uname -s)" = "Darwin" ]; then
      if [ "$(uname -m)" = "arm64" ]; then
        TEMURIN_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_aarch64_mac_hotspot_21.0.5_11.tar.gz"
      else
        TEMURIN_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_x64_mac_hotspot_21.0.5_11.tar.gz"
      fi
    elif [ "$(uname -s)" = "Linux" ]; then
      if [ "$(uname -m)" = "aarch64" ]; then
        TEMURIN_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_aarch64_linux_hotspot_21.0.5_11.tar.gz"
      else
        TEMURIN_URL="https://github.com/adoptium/temurin21-binaries/releases/download/jdk-21.0.5%2B11/OpenJDK21U-jdk_x64_linux_hotspot_21.0.5_11.tar.gz"
      fi
    else
      echo "Unsupported OS or architecture"
      exit 1
    fi

    curl -fsSL -o "$CACHE_DIR/java.tar.gz" "$TEMURIN_URL"
    tar xzf "$CACHE_DIR/java.tar.gz" -C "$CACHE_DIR"
    mv "$CACHE_DIR"/jdk-* "$CACHE_DIR/java"
  fi

  if [ ! -e "$BB_CMD" ]; then
    curl -fsSL -o "$CACHE_DIR/install" https://raw.githubusercontent.com/babashka/babashka/master/install
    chmod +x "$CACHE_DIR/install"
    "$CACHE_DIR/install" --dir "$CACHE_DIR/bb" --version "$BB_VERSION" 1>&2
  fi

  if [ ! -e "$BBIN_CMD" ]; then
    mkdir -p "$BABASHKA_BBIN_BIN_DIR"
    curl -fsSL -o "$BBIN_CMD" "https://raw.githubusercontent.com/babashka/bbin/v$BBIN_VERSION/bbin"
    chmod +x "$BBIN_CMD"
  fi

  $BBIN_CMD $BBIN_ARGS --as "$SCRIPT_ID" 1>&2
  "$BABASHKA_BBIN_BIN_DIR/$SCRIPT_ID" "$@"
}

main "$@"
