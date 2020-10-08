#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

SSB_USER="ddcsl4msc176"
SSB_HOST="bassed.ca"
alias ls='ls -l --color=auto'
alias emacs='emacs -nw'              # Disable emacs window
alias rm='rm -i'                     # Promt before removing files
alias mv='mv -i'                     # Prompt if a move causes an override
alias cp='cp -i'                     # Prompt if a copy causes an override
alias ssb="ssh $SSB_USER@$SSB_HOST"  # Bassed.ca SSH Connection
alias uc="ssh 'juanpablo.lozanosarm@linuxlab.cpsc.ucalgary.ca'"
alias pacman='pacman --color auto'
alias sudo='sudo '
#Set the config directory
XDG_CONFIG_HOME=$HOME/.config
#Set up user bin
PATH=$PATH:/home/jp/bin
PATH=$PATH:/home/jp/.gem/ruby/2.7.0/bin

XDG_CACHE_DIR=/home/jp/.cache
XDG_DATA_DIR=/home/jp/.data
XDG_CONFIG_DIR=/home/jp/.config


export XDG_CONFIG_HOME
export PATH
export TERM=xterm-256color
export XDG_CACHE_DIR
export XDG_DATA_DIR

#COLOR definitions

GREEN="\[$(tput setaf 2)\]"
RED="\[$(tput setaf 1)\]"
BLUE="\[$(tput setaf 20)\]"
PURPLE="\[$(tput setaf 165)\]"
MAG="\[$(tput setaf 207)\]"
RESET="\[$(tput sgr0)\]"

#
# Custom prompt
#
# Using Font Awesome to display icons
number_of_jobs(){
    jobs_total=$(jobs | wc -l)
    if [ $jobs_total -gt 0 ]; then
	    echo -ne "\uf110" #Loading dots for background jobs
    else
	    echo -ne "\uf1db" #Regular circle for no background jobs
    fi

}

error_handle(){
    case $1 in
	0)
	    echo -ne "${GREEN}$(number_of_jobs)${RESET}"
	    ;;
	126|127)
	    echo -ne "${RED}$(number_of_jobs)${RESET}"
	    ;;
	128)
	    echo -ne "${BLUE}$(number_of_jobs)${RESET}"
	    ;;
	130)
	    echo -ne "${PURPLE}$(number_of_jobs)${RESET}"
	    ;;
	148)
	    echo -ne "${MAG}$(number_of_jobs)${RESET}"
	    ;;
	*)
	    echo -ne "$(number_of_jobs)"
	    ;;
    esac

}
set_bash_prompt(){
    commOutput=`echo $?`
    ARROW=$(echo -ne "\uf101")
    FOLDER=$(echo -ne "\uf114")
    PS1="\n$FOLDER \W \n$(error_handle $commOutput) $ARROW "
}

cp_jp(){
    file_to_copy=$(echo $1)
    name_of_file=$(basename $file_to_copy)
    home_path="public_html/clicknsnip/"
    if [ -z "$2" ]; then
	path=$home_path
    else
	path=$home_path$2
    fi
    scp $1 ddcsl4msc176@bassed.ca:$path/
}

cp_to_uc(){
    if [ -n $1 ]; then
	file_to_copy=$(echo $1)
	name_of_file=$(basename $file_to_copy)
	home_path="~/"
	if [ -n $2 ]; then
	    path=$home_path$2
	else
	    path=$home_path
	fi
	scp $1 juanpablo.lozanosarm@linuxlab.cpsc.ucalgary.ca:$path
    else
	echo "[cp_uc] Usage: cp_uc FILE_TO_COPY [PATH]"
    fi
}

cp_from_uc(){
    if [ -n $2 ]; then
	file_to_copy=$(echo $1)
	name_of_file=$(basename $file_to_copy)
	home_path="~/"
	if [ -n $2 ]; then
	    path=$home_path$2
	else
	    path=$home_path
	fi
	scp juanpablo.lozanosarm@linuxlab.cpsc.ucalgary.ca:$1 $2 
    else
	echo "[cp_uc] Usage: cp_uc FILE_TO_COPY [PATH]"
    fi
}

PROMPT_COMMAND=set_bash_prompt
set_bash_prompt
