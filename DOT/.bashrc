#!/bin/bash
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# EXPORT
export EDITOR='nano'
export LESSHISTFILE=-
export HISTSIZE=9999
export HISTCONTROL="erasedups:ignoreboth"

# SHOPT
shopt -s cdspell autocd cmdhist histappend

# PS1
CRESET='\e[0m'
CWHITE='\e[1;37m'
CGREEN='\e[1;32m'
CLRRED='\e[1;31m'
export PS1="\[$CWHITE\]$USER@$HOSTNAME:\w \`if [ \$? = 0 ]; then echo -e '\[$CGREEN\]'; else echo -e '\[$CLRRED\]'; fi\`\\$ \[$CRESET\]"

#     ix hello.txt              # paste file (name/ext will be set).
#     echo Hello world | ix     # read from STDIN (won't set name/ext).
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
    : "${1//+/ }"; printf '%b\n' "${_//%/\\x}"
}
rdp() {
    xfreerdp /v:"$1" /u:"$2" /p:"$3" /dynamic-resolution /bpp:16 /network:auto /clipboard /compression -themes -wallpaper \
             /auto-reconnect -glyph-cache /cert-ignore /network:modem /audio-mode:1
}
man() {
    env LESS_TERMCAP_mb="$(printf "\e[1;31m")" \
        LESS_TERMCAP_md="$(printf "\e[1;31m")" \
        LESS_TERMCAP_me="$(printf "\e[0m")" \
        LESS_TERMCAP_se="$(printf "\e[0m")" \
        LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
        LESS_TERMCAP_ue="$(printf "\e[0m")" \
        LESS_TERMCAP_us="$(printf "\e[1;32m")" man "$@"
}
mkcd(){
    mkdir -pv "$1" && cd "$1" || echo 'ERROR' && exit
}
up() {
    for LOOP in $1; do; curl -T "$LOOP" https://transfer.sh/"$(basename "$LOOP")"; echo; done
}
tgmsg() {
    TGTEXT="$1"
    MID=$(curl -s "https://api.telegram.org/bot${BOTAPI}/sendmessage" -d "text=$1&chat_id=${ID}" \
        -d "disable_web_page_preview=true" -d "parse_mode=html" | jq .result.message_id) 1>/dev/null
}
tgdoc() {
    curl -F chat_id="${ID}" -F document=@"$1" -F caption="$2" \
    https://api.telegram.org/bot"${BOTAPI}"/sendDocument >/dev/null
}

# Alias
alias speed='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
alias vdir='vdir -th --color=auto'
alias ls='ls -th --color=auto --time-style long-iso'
alias la='ls -tA --color=auto --time-style long-iso'
alias lp='ls -tlAh --color=auto --time-style long-iso'
alias cd..='cd ..'
alias ..='cd ..'
alias ...='cd ../../'
alias ....='cd ../../../'
alias .....='cd ../../../../'
alias find='find . -name'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias pacman='pacman --color auto'
alias watch='watch --color'
alias mkdir='mkdir -pv'
alias powerb='sudo x86_energy_perf_policy -v -r powersave'
alias powerp='sudo x86_energy_perf_policy -v -r performance'
alias turbon='sudo x86_energy_perf_policy --turbo-enable 1'
alias turbof='sudo x86_energy_perf_policy --turbo-enable 0'

# GIT
alias gcl="git clone"
alias ga="git add -A"
alias gc="git commit -sa"
alias gp="git push"
alias gcp="git cherry-pick"
alias fsync='repo sync  --force-sync --current-branch --no-tags --no-clone-bundle --optimized-fetch --prune -j$(nproc --all)'
alias dpion='sudo /home/p/Git/DPITunnel-cli/DPITunnel-cli-exec -use-doh -doh-server https://dns.google/dns-query -split-at-sni -ca-bundle-path /home/p/Git/DPITunnel-cli/ca.bundle -desync-attacks split -port 6969 -daemon'
alias dpioff='sudo killall DPITunnel-cli'
alias ytflac='youtube-dl -x -k --audio-format flac -f "bestaudio/best" -ciw -o "%(title)s.%(ext)s" -v --extract-audio --audio-quality 0'
