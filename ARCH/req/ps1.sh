#!/bin/bash
clrreset='\e[0m'
clrwhite='\e[1;37m'
clrgreen='\e[1;32m'
clrred='\e[1;31m'
export PS1="\[$clrwhite\]$USER@$HOSTNAME:\w \`if [ \$? = 0 ]; then echo -e '\[$clrgreen\]'; else echo -e '\[$clrred\]'; fi\`\\$ \[$clrreset\]"
