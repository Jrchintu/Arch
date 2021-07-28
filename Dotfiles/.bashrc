#!/bin/bash
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

#Editor
export EDITOR='nano'

# History Stuff
export LESSHISTFILE=-
export HISTFILESIZE=500000
export HISTSIZE=100000
export HISTCONTROL="erasedups:ignoreboth"

# PS1
export PS1='[\u@\h \W]\$ '

# Enable Byobu Automatically
#env TERM=xterm-256color byobu

# Shopt
shopt -s cdspell autocd cmdhist

# iX Paster
#     ix hello.txt              # paste file (name/ext will be set).
#     echo Hello world. | ix    # read from STDIN (won't set name/ext).
#     ix -n 1 self_destruct.txt # paste will be deleted after one read.
#     ix -i ID hello.txt        # replace ID, if you have permission.
#     ix -d ID
ix() {
    local opts
    local OPTIND
    [ -f "$HOME/.netrc" ] && opts='-n'
    while getopts ":hd:i:n:" x; do
        case $x in
            h) echo "ix [-d ID] [-i ID] [-n N] [opts]"; return;;
            d) echo curl $opts -X DELETE ix.io/"$OPTARG"; return;;
            i) opts="$opts -X PUT"; local id="$OPTARG";;
            n) opts="$opts -F read:1=$OPTARG";;
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
    for (( i = 0; i < ${#1}; i++ )); do
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
	/auto-reconnect -glyph-cache /cert-ignore /network:modem  \
	/audio-mode:1 
}

# Alias
alias thor='ls -thor'
alias ls='ls -Ah --color=auto'
alias speed='curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python -'
alias packages='for i in {a..z} ; do echo -e $(pacman -Qq | grep ^${i}) >>/tmp/packages.txt ; echo >>/tmp/packages.txt ; done ; fmt -w $(tput cols) /tmp/packages.txt'
