#!/usr/bin/env bash
LC_ALL=C && LANG=C

# ENV SETUP
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove --purge -y
sudo add-apt-repository ppa:openjdk-r/ppa -y
sudo apt install git-core p7zip-full rclone pigz -y
curl https://storage.googleapis.com/git-repo-downloads/repo >./repo
sudo mv repo /usr/bin/repo && sudo chmod a+x /usr/bin/repo
PATH=/usr/bin/repo:$PATH
git clone --depth=1 https://github.com/akhilnarang/scripts.git scripts
cd scripts && sudo bash setup/android_build_env.sh && cd .. && rm -rf scripts

# BASHRC
cat <<EOF >> $HOME/.bashrc
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
if [[ \$(pidof soong_ui) ]]; then :; else ccache -z; fi
EOF

ccache -M 30G # OPTIONAL

# ALIAS
echo 'repo sync  --force-sync --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune -j$(nproc --all)' >>$HOME/.bashrc
