# Check for an interactive session
[ -z "$PS1" ] && return

alias ls='ls --color=auto'
PS1='\[\e[0;32m\][\u-home:\W]\$\[\e[0m\] '

export EDITOR='vim'
export GREP_COLOR='1;32'
export GREP_OPTIONS='--exclude-dir=\.svn --color=auto -I -n -r'
# LLVM Tools
export PATH=$PATH:/usr/local/bin
export LD_LIBRARY_PATH=/usr/local/jacket/engine:/usr/local/jacket/engine/cuda/lib64:/usr/lib:$LD_LIBRARY_PATH

alias diff='colordiff'
alias mkdir='mkdir -p -v'
alias df='df -h'
alias du='du -c -h'
alias ping='ping -c 3'

alias pg='ps -Af | grep $1'

if [ $UID -ne 0 ]; then
	alias sudo='sudo '
	alias root='sudo su'
	alias reboot='sudo reboot'
	alias sbb='sudo bauerbill --blindly-trust-everything-when-building-packages-despite-the-inherent-danger --aur'
	alias up='sbb -Syu --aur'
	alias sc='sudo clyde'
	alias pacman='sudo pacman'
	alias pacman-optimize='sudo pacman-optimize'
	alias shutdown='sudo shutdown -t 0 now'
fi

alias home='cd ~'
alias back='cd $OLDPWD'
alias cd..='cd ..'
alias ..='cd ..'

alias ls='ls -hF --color=auto'
alias lr='ls -R'
alias ll='ls -l'
alias la='ll -A'
alias lm='la | more'

if [[ `tty` == /dev/tty* ]];  then
        setleds +num
fi

complete -cf sudo

function mkcd {
  mkdir $1
  cd $1
}
