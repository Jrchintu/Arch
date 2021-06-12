#!/bin/bash

# FUNCTIONS
function man() {
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
function up() {
    for LOOP in $1
      do curl -T "$LOOP" https://transfer.sh/"$(basename "$LOOP")"
      echo
    done
}
function TG() {
    TGTEXT="$1"
    MID=$(curl -s "https://api.telegram.org/bot${BOTAPI}/sendmessage" \
        -d "text=$1&chat_id=${ID}" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" | jq .result.message_id) 1>/dev/null
}
function TGDOC() {
    curl -F chat_id="${ID}" \
        -F document=@"$1" \
        -F caption="$2" https://api.telegram.org/bot"${BOTAPI}"/sendDocument >/dev/null
}
function DEL() {
    RESULT=$(curl -sf --data-binary @"${1:--}" https://del.dog/documents) || {
        echo "DEL-ERROR" >&2
        return 1
    }
    KEY=$(printf "%s\n" "${RESULT}" | cut -d '"' -f6)
    echo "https://del.dog/${KEY}"
}

# COMMON ALIAS
alias ls='ls --color=auto --time-style long-iso'
alias la='ls --color=auto -a --time-style long-iso'
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

# GIT ALIAS
#echo "https://jrchintu:$password@github.com" > ~/.git-credentials
#git config --global credential.helper store
alias gc="git clone"
alias gcb="git clone --bare"
alias gc1="git clone --depth=1"
alias ga="git add -A"
alias gcs="git commit -s"
alias gp="git push"
alias gcp="git add -A && git commit -s && git push"
