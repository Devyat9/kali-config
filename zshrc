# Zshrc config

setopt interactivecomments # allow comments in interactive mode
setopt magicequalsubst     # enable filename expansion for arguments of the form ‘anything=expression’
setopt nonomatch           # hide error message if there is no match for the pattern
setopt notify              # report the status of background jobs immediately
setopt numericglobsort     # sort filenames numerically when it makes sense
setopt promptsubst         # enable command substitution in prompt

# configure key keybindings
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # do history expansion on space
bindkey '^U' backward-kill-line                   # ctrl + U
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[3~' delete-char                       # delete
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[H' beginning-of-line                  # home
bindkey '^[[F' end-of-line                        # end
bindkey '^[[Z' undo                               # shift + tab undo last action


source ~/.bash_aliases
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
export GOBIN=/opt/go

# Configuración de historial
HISTFILE=~/.zsh_history
export HISTSIZE=10000000
export SAVEHIST=10000000
setopt APPEND_HISTORY
setopt EXTENDED_HISTORY

# Configuración del prompt
#PROMPT='%F{31}┌──[%F{red}$(ip -4 addr | grep -v "127.0.0.1" | grep -v "secondary" | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | sed -z "s/\n/|/g;s/|\$/\n/" | rev | cut -c 2- | rev)%F{blue}@%f%F{blue}%m%f%F{31}]:%f%F{yellow}[%~]%f
#%F{31}└──╼[%F{white}%D{%F %T}%F{31}]%f> '


if ip link show eth0 > /dev/null 2>&1; then
    if ip link show tun0 > /dev/null 2>&1; then
        PROMPT='%F{31}┌──[%F{red}$(ip -4 addr | grep -v "127.0.0.1" | grep -v "secondary" | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | sed -z "s/\n/|/g;s/|\$/\n/")%F{blue}@%f%F{blue}%m%f%F{31}]:%f%F{yellow}[%~]%f
%F{31}└──╼[%F{white}%D{%F %T}%F{31}]%f> '
        precmd() { echo }
    else
        PROMPT='%F{31}┌──[%F{red}$(ip -4 addr | grep -v "127.0.0.1" | grep -v "secondary" | grep -oP "(?<=inet\s)\d+(\.\d+){3}" | sed -z "s/\n/|/g;s/|\$/\n/" | rev | cut -c 2- | rev)%F{blue}@%f%F{blue}%m%f%F{31}]:%f%F{yellow}[%~]%f
%F{31}└──╼[%F{white}%D{%F %T}%F{31}]%f> '
        precmd() { echo }
    fi
fi

case $- in *i*)
    [ -z "$TMUX" ] && exec tmux
esac

export PAYLOADS="/usr/share/payloads"
export AUTOWORDLISTS="$PAYLOADS/Auto_Wordlists"
export FUZZDB="$PAYLOADS/FuzzDB"
export PAYLOADSALLTHETHINGS="$PAYLOADS/PayloadsAllTheThings"
export SECLISTS="$PAYLOADS/SecLists"
export SECURITYWORDLIST="$PAYLOADS/Security-Wordlist"
export MIMIKATZ="/usr/share/windows/mimikatz"
export POWERSPLOIT="/usr/share/windows/powersploit"
export DIRBIG="$SECLISTS/Discovery/Web-Content/directory-list-2.3-big.txt"
export DIRMEDIUM="$SECLISTS/Discovery/Web-Content/directory-list-2.3-medium.txt"
export DIRSMALL="$SECLISTS/Discovery/Web-Content/directory-list-2.3-small.txt"
export ROCKYOU="$SECLISTS/Passwords/Leaked-Databases/rockyou.txt"
export WEBAPI_COMMON="$SECLISTS/Discovery/Web-Content/api/api-endpoints.txt"
export WEBAPI_MAZEN="$SECLISTS/Discovery/Web-Content/common-api-endpoints-mazen160.txt"
export WEBCOMMON="$SECLISTS/Discovery/Web-Content/common.txt"
export WEBPARAM="$SECLISTS/Discovery/Web-Content/burp-parameter-names.txt"

# Created by `pipx`
export PATH="$PATH:/home/kali/.local/bin:/opt/go"

# Warning! Tmux break this!
# Log everything! 0=off 1=on files store on /var/log/session/session.$USER.$$.$timestamp
#log_mode=0
#if [ "$log_mode" -eq 1 ] && [ -z "$SESSION_RECORDING" ]; then
#    export SESSION_RECORDING=1
#    timestamp=$(date "+%d-%m-%Y-%H_%M_%S")
#    output="/var/log/session/session.$USER.$$.$timestamp"
#    script -t -f -q 2>"${output}.timing" "$output"
#fi

setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
unsetopt EXTENDED_HISTORY
