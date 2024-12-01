#!/usr/bin/env bash

set -e

# Check for sudo and install if not present
if ! command -v sudo &> /dev/null; then
  echo "sudo not found. Installing sudo..."
  apt-get update
  apt-get install -y sudo
fi

# Function to add apt repositories
add_apt_repositories() {
  sudo apt-get update
  sudo apt-get install -y apt-transport-https curl gnupg
  # Add the Helm repository
  curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

  # Add the Docker repository
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  # Add the kubectl repository
  # If the folder `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
  # sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg # allow unprivileged APT programs to read this keyring
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list

  apt-get update
}

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
      sudo apt-get install -y $tool
    else
      echo "$tool is already installed."
    fi
  fi
}

# macos specific
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Check for Homebrew and install if not present (macOS only)
  if ! command -v brew &> /dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Install macos specific required tools
  # Check for Docker and install if not present
  if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
    install_tool docker --cask
  fi

  # Install Hubble CLI
  if ! brew list hubble &> /dev/null; then
    echo "Installing Hubble CLI using Homebrew..."
    brew install hubble
  else
    echo "Hubble CLI is already installed."
  fi

  # Install Cilium CLI
  install_tool cilium-cli

  # install kind
  install_tool kind
fi

# linux specific
if [[ "$OSTYPE" == "linux-gnu" ]]; then
  add_apt_repositories

  # Install linux specific required tools
  # Check for Docker and install if not present
  if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  # install cilium cli
  CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
  CLI_ARCH=amd64
  if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
  curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
  sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
  sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
  rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

  # install hubble cli
  echo "Installing Hubble CLI..."
  HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
  HUBBLE_ARCH=amd64
  if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
  curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
  sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
  sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
  rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}

  # install kind
  # For AMD64 / x86_64
  [ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-amd64
  # For ARM64
  [ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.25.0/kind-linux-arm64
  chmod +x ./kind
  sudo mv ./kind /usr/local/bin/kind
fi

install_tool helm
install_tool kubectl

echo "All tools are installed and ready to use."