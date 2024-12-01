#!/usr/bin/env bash

set -e

# Check for Homebrew and install if not present (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
fi

# Function to install a tool using Homebrew or apt-get
install_tool() {
  local tool=$1
  local options=$2
  if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! brew list $tool &> /dev/null; then
      echo "Installing $tool using Homebrew..."
      brew install $options $tool
    else
      echo "$tool is already installed."
    fi
  else
    if ! dpkg -l | grep -q $tool; then
      echo "Installing $tool using apt-get..."
      sudo apt-get update
      sudo apt-get install -y $tool
    else
      echo "$tool is already installed."
    fi
  fi
}

# Install required tools
if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
  install_tool docker --cask
fi
install_tool helm
install_tool kubectl
install_tool kind
install_tool cilium-cli

# Install Hubble CLI
if [[ "$OSTYPE" == "darwin"* ]]; then
  if ! brew list hubble &> /dev/null; then
    echo "Installing Hubble CLI using Homebrew..."
    brew install hubble
  else
    echo "Hubble CLI is already installed."
  fi
else
  if ! dpkg -l | grep -q hubble; then
    echo "Installing Hubble CLI..."
    HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
    HUBBLE_ARCH=amd64
    if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
    curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
    sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
    sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
    rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
  else
    echo "Hubble CLI is already installed."
  fi
fi

echo "All tools are installed and ready to use."