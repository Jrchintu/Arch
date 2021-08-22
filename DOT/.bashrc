#!/bin/bash
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#Editor
export EDITOR='nano'

# History Stuff
export LESSHISTFILE=-
export HISTSIZE=5000
export HISTFILESIZE=5000
export HISTCONTROL="erasedups:ignoreboth:ignorespace"

# PS1
clrreset='\e[0m'
clrwhite='\e[1;37m'
clrgreen='\e[1;32m'
clrred='\e[1;31m'
export PS1="\[$clrwhite\]$USER@$HOSTNAME:\w \`if [ \$? = 0 ]; then echo -e '\[$clrgreen\]'; else echo -e '\[$clrred\]'; fi\`\\$ \[$clrreset\]"
#export PS1='[\u@\h \W]\$ '

# Enable Byobu Automatically
#env TERM=xterm-256color byobu

# Shopt
shopt -s cdspell autocd cmdhist histappend

# IX PASTER
#     ix hello.txt              # paste file (name/ext will be set).
#     echo Hello world. | ix    # read from STDIN (won't set name/ext).
#     ix -n 1 self_destruct.txt # paste will be deleted after one read.
ix() {
    local opts
    local OPTIND
    [ -f "$HOME/.netrc" ] && opts='-n'
    while getopts ":hd:i:n:" x; do
        case $x in
        h)
            echo "ix [-d ID] [-i ID] [-n N] [opts]"
            return
            ;;
        d)
            echo curl $opts -X DELETE ix.io/"$OPTARG"
            return
            ;;
        i)
            opts="$opts -X PUT"
            local id="$OPTARG"
            ;;
        n)
            opts="$opts -F read:1=$OPTARG"
            ;;
        *) ;;
        esac
    done
    shift $((OPTIND - 1))
    [ -t 0 ] && {
        local filename="$1"
        shift
        [ "$filename" ] && {
            curl "$opts" -F f:1=@"$filename" "$*" ix.io/"$id"
            return
        }
        echo "^C to cancel, ^D to send."
    }
    curl "$opts" -F f:1='<-' "$*" ix.io/"$id"
}
urlencode() {
    local LC_ALL=C
    for ((i = 0; i < ${#1}; i++)); do
        : "${1:i:1}"
        case "$_" in
        [a-zA-Z0-9.~_-])
            printf '%s' "$_"
            ;;

        *)
            printf '%%%02X' "'$_"
            ;;
        esac
    done
    printf '\n'
}
urldecode() {
    : "${1//+/ }"
    printf '%b\n' "${_//%/\\x}"
}
rdp() {
    xfreerdp /v:"$1" /u:"$2" /p:"$3" /dynamic-resolution /bpp:16 \
        /network:auto /clipboard /compression -themes -wallpaper \
        /auto-reconnect -glyph-cache /cert-ignore /network:modem \
        /audio-mode:1
}
man() {
    env \
        LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
        LESS_TERMCAP_md="$(printf "\e[1;31m")" \
        LESS_TERMCAP_me="$(printf "\e[0m")" \
        LESS_TERMCAP_se="$(printf "\e[0m")" \
        LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
        LESS_TERMCAP_ue="$(printf "\e[0m")" \
        LESS_TERMCAP_us="$(printf "\e[1;32m")" \
        man "$@"
}
br() {
    for ((i = 1; i <= $(tput cols); i++)); do echo -n -; done
}
mkcd(){
    mkdir "$1" && cd "$1" || exit
}
up() {
    for LOOP in $1; do
        curl -T "$LOOP" https://transfer.sh/"$(basename "$LOOP")"
        echo
    done
}
tg() {
    TGTEXT="$1"
    MID=$(curl -s "https://api.telegram.org/bot${BOTAPI}/sendmessage" \
        -d "text=$1&chat_id=${ID}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" | jq .result.message_id) 1>/dev/null
}
tgdoc() {
    curl -F chat_id="${ID}" \
        -F document=@"$1" \
        -F caption="$2" https://api.telegram.org/bot"${BOTAPI}"/sendDocument >/dev/null
}
del() {
    RESULT=$(curl -sf --data-binary @"${1:--}" https://del.dog/documents) || {
        echo "DEL-ERROR" >&2
        return 1
    }
    KEY=$(printf "%s\n" "${RESULT}" | cut -d '"' -f6)
    echo "https://del.dog/${KEY}"
}

# Alias
alias speed='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
alias packages='for i in {a..z} ; do echo -e $(pacman -Qq | grep ^${i}) >>/tmp/packages.txt ; echo >>/tmp/packages.txt ; done ; fmt -w $(tput cols) /tmp/packages.txt'
alias thor='ls -thor'
alias ls='ls -h --color=auto --time-style long-iso'
alias la='ls --color=auto -A --time-style long-iso'
alias lp='ls --color=auto -lah --time-style long-iso'
alias l='ls --color=auto -A --time-style long-iso'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias ff='find / -name'
alias f='find . -name'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ip='ip -c'
alias pacman='pacman --color auto'
alias pactree='pactree --color'
alias vdir='vdir --color=auto'
alias watch='watch --color'
alias mkdir='mkdir -pv'
alias batt='x86_energy_perf_policy -v powersave'

# GIT
#echo "https://jrchintu:$password@github.com" > ~/.git-credentials
#git config --global credential.helper store
alias gc="git clone"
alias gcb="git clone --bare"
alias gc1="git clone --depth=1"
alias ga="git add -A"
alias gcs="git commit -s"
alias gp="git push"
alias gcp="git add -A && git commit -s && git push"
alias curls='curl -s --tlsv1.3 --proto =https'
alias fdpi='sudo /home/p/Git/DPITunnel-cli/DPITunnel-cli-exec -use-doh -doh-server https://dns.google/dns-query -split-at-sni -ca-bundle-path /home/p/Git/DPITunnel-cli/ca.bundle -desync-attacks split -port 6969 -daemon'
alias fsync='repo sync  --force-sync --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune -j$(nproc --all)'
alias dpion='sudo /home/p/Git/DPITunnel-cli/DPITunnel-cli-exec -use-doh -doh-server https://dns.google/dns-query -split-at-sni -ca-bundle-path /home/p/Git/DPITunnel-cli/ca.bundle -desync-attacks split -port 6969 -daemon'
alias dpioff='sudo killall DPITunnel-cli'
alias ytflac='youtube-dl -x -k --audio-format flac -f "bestaudio/best" -ciw -o "%(title)s.%(ext)s" -v --extract-audio --audio-quality 0'

# Keyboard mods
xmodmap -e 'keycode 98=' # Disable Up key
