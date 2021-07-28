#!/usr/bin/env bash
LC_ALL=C && LANG=C

# ENV SETUP
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove --purge -y
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt install git-core p7zip-full aria2 rclone pigz -y
curl https://storage.googleapis.com/git-repo-downloads/repo >./repo
sudo mv repo /usr/bin/repo && sudo chmod a+x /usr/bin/repo
PATH=/usr/bin/repo:$PATH
git clone --depth=1 https://github.com/akhilnarang/scripts.git scripts
cd scripts && sudo bash setup/android_build_env.sh && cd .. && rm -rf scripts

# BASHRC
cat <<EOF >> "$HOME"/.bashrc
export USE_CCACHE=1
export CCACHE_DIR="$HOME/.ccache"
export CCACHE_EXEC="$(which ccache)"
export CCACHE_COMPILERCHECK=content
ccache -o compression=true
export LC_ALL=C
export BUILD_BROKEN_DUP_RULES=true
export SKIP_ABI_CHECKS=true
export SKIP_API_CHECKS=true
export WITHOUT_CHECK_API=true
export TZ=Asia/Kolkata
if [[ \$(pidof soong_ui) ]]; then :; else ccache -z; fi
EOF

ccache -M 30G # OPTIONAL

# ALIAS
echo '' >>"$HOME"/.bashrc && echo '# ALias' >>"$HOME"/.bashrc
echo 'alias fsync="repo sync  --force-sync --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune -j$(nproc --all)"' >>"$HOME"/.bashrc

# Funct
echo '' >>"$HOME"/.bashrc && echo '# Functions' >>"$HOME"/.bashrc
echo 'mkcd(){
    mkdir $1 && cd $1
}' >>"$HOME"/.bashrc
echo 'br() {
    for ((i = 1; i <= $(tput cols); i++)); do echo -n -; done
}' >>"$HOME"/.bashrc

# Source bashrc
source "$HOME"/.bashrc

# MKDIR
mkdir rom && chmod -R 777 rom
cd rom && mkdir .repo && br
read -rep "What Branch From Local_manifest Repo U wanna clone [Case Sensitive]? " LMBRANCH
git clone https://github.com/Jrchintu/local_manifest --depth 1 -b "$LMBRANCH" .repo/local_manifests

# GIT
git config --global user.email "chintu@gcp.com"
git config --global user.name "Chintu"
