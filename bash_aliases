### ALIASES ###

target () {
        echo "target=\"$1\"" > ~/.target
}

#tmux
alias tmux='tmux -u'

# Alias's for multiple directory listing commands

# ls = lsd
alias ls='lsd --color=auto'
alias la='lsd -a'
alias lx='lsd -lXh' # sort by extension
alias lk='lsd -lSrh' # sort by size
alias lr='lsd -lRh' # recursive ls
alias lt='lsd -ltrh' # sort by date
alias lm='lsd -alh | more' # pipe through 'more'
alias ll='lsd -alFh' # long listing format
alias lf="lsd -l | grep -E -v '^d'" # files only
alias ldir="lsd -l | grep -E '^d' --color=never" # directories only
alias l='lsd'
alias l.="lsd -A | grep -E '^\.' --color=never"

# Normal ls
#alias ls='ls --color=auto'
#alias la='ls -a'
#alias lx='ls -lhs extension' # sort by extension
#alias lk='ls -lhs size' # sort by size
#alias lc='ls -lhs changed' # sort by change time
#alias lu='ls -lhs accessed' # sort by access time
#alias lr='ls -lRh' # recursive ls
#alias lt='ls -lhs modified' # sort by modification date
#alias lz='ls -lhs created' # sort by creation date
#alias lm='ls -alh | more' # pipe through 'more'
#alias lw='ls -xGah' # wide listing format
#alias ll='ls -alFh' # long listing format
#alias labc='ls -lhs name' #alphabetical sort
#alias lf="ls -l | grep -E -v '^d'" # files only
#alias ldir="ls -l | grep -E '^d' --color=never" # directories only
#alias l='ls'
#alias l.="ls -a | grep -E '^\.' --color=never"

# alias to show the date
alias da='date "+%Y-%m-%d %A %T %Z"'

# alias to copy file content to clipboard
alias cpc='xclip < '

## Colorize the grep command output for ease of use (good for log files)##
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

# Alias's to modified commands
#alias cp='cp -i'
#alias mv='mv -i'
#alias rm='rm -iv'
alias mkdir='mkdir -p'
alias ping='ping -c 4'
alias less='less -R'
alias cls='clear'
alias apt-get='sudo apt-get'
alias vi='vim'
alias svi='sudo vim'
alias vis='vim "+set si"'

#python
alias pyserver='python3 -m http.server'

#continue download
alias wget="wget -c"

alias nhosts="sudo nano /etc/hosts"

#shutdown or reboot
alias ssn="sudo shutdown now"
alias ssr="sudo reboot"


# Show open ports
alias openports='netstat -nape --inet'

# Alias's for safe and forced reboots
alias rebootsafe='sudo shutdown -r now'
alias rebootforce='sudo shutdown -r -n now'

# Alias's to show disk space and space used in a folder
alias diskspace="du -S | sort -n -r |more"
alias folders='du -h --max-depth=1'
alias folderssort='find . -maxdepth 1 -type d -print0 | xargs -0 du -sk | sort -rn'
alias tree='tree -CAhF --dirsfirst'
alias treed='tree -CAFd'
alias mountedinfo='df -hT'


#amass config alias
alias Amass='amass enum -config ~/.config/amass/config.ini -d $1'


alias reloadzsh='source ~/.zshrc'
#alias reloadprofile='source ~/.profile'

alias cat='batcat --paging=never --style=plain --theme OneHalfDark'

alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"

#fix obvious typo's
alias cd..='cd ..'
alias pdw='pwd'
alias upate='sudo apt update'

# mount share folder on Vmware
alias vmware_share="sudo mount -t fuse.vmhgfs-fuse .host:/ /mnt/ -o allow_other"


# Extract ports and IP for Nmap
function portsGrep(){
    if [ $# -eq 0 ]; then
        echo "Uso: extractPorts <archivo_grepeable_nmap>"
        return 1
    fi

    IP=$(grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' "$1" | sort -u)
    PORTS=$(grep '/open/' "$1" | grep -oP '\d+(?=/open)' | tr '\n' ',' | sed 's/,$//')
    
    if [[ -z "$IP" || -z "$PORTS" ]]; then
        echo "No se pudieron extraer IP o puertos del archivo."
        return 1
    fi

    OUTPUT="nmap -sCV -p$PORTS $IP -n -Pn --open --min-rate 5000 -oN service -vvv"
    echo -n "$OUTPUT" | xclip -sel clip
    echo "Copiado al portapapeles: $OUTPUT"
}

alias feroxbuster='/usr/bin/feroxbuster --no-state -D -s $(seq 200 299),301,302,307,401,403,405,500'


# History
#alias history='history 0'

# Anothers
alias zshrc='nano ~/.zshrc'
#alias v='/usr/bin/nvim'
#alias vi='/usr/bin/nvim'
#alias vim='/usr/bin/nvim'
alias n='/usr/bin/nano'
alias c='/usr/bin/clear'

# Search for word on files
fstr() {
    grep -Rnw "." -e "$1" 2>/dev/null
}

# Easy extract
function extract {
 if [ $# -eq 0 ]; then
    # display usage if no parameters given
    echo "Usage: extract <path/file_name>.<zip|rar|bz2|gz|tar|tbz2|tgz|Z|7z|xz|ex|tar.bz2|tar.gz|tar.xz|.zlib|.cso|.zst>"
    echo "       extract <path/file_name_1.ext> [path/file_name_2.ext] [path/file_name_3.ext]"
 fi
    for n in "$@"; do
        if [ ! -f "$n" ]; then
            echo "'$n' - file doesn't exist"
            return 1
        fi

        case "${n%,}" in
          *.cbt|*.tar.bz2|*.tar.gz|*.tar.xz|*.tbz2|*.tgz|*.txz|*.tar)
                       tar zxvf "$n"       ;;
          *.lzma)      unlzma ./"$n"      ;;
          *.bz2)       bunzip2 ./"$n"     ;;
          *.cbr|*.rar) unrar x -ad ./"$n" ;;
          *.gz)        gunzip ./"$n"      ;;
          *.cbz|*.epub|*.zip) unzip ./"$n"   ;;
          *.z)         uncompress ./"$n"  ;;
          *.7z|*.apk|*.arj|*.cab|*.cb7|*.chm|*.deb|*.iso|*.lzh|*.msi|*.pkg|*.rpm|*.udf|*.wim|*.xar|*.vhd)
                       7z x ./"$n"        ;;
          *.xz)        unxz ./"$n"        ;;
          *.exe)       cabextract ./"$n"  ;;
          *.cpio)      cpio -id < ./"$n"  ;;
          *.cba|*.ace) unace x ./"$n"     ;;
          *.zpaq)      zpaq x ./"$n"      ;;
          *.arc)       arc e ./"$n"       ;;
          *.cso)       ciso 0 ./"$n" ./"$n.iso" && \
                            extract "$n.iso" && \rm -f "$n" ;;
          *.zlib)      zlib-flate -uncompress < ./"$n" > ./"$n.tmp" && \
                            mv ./"$n.tmp" ./"${n%.*zlib}" && rm -f "$n"   ;;
          *.dmg)
                      hdiutil mount ./"$n" -mountpoint "./$n.mounted" ;;
          *.tar.zst)  tar -I zstd -xvf ./"$n"  ;;
          *.zst)      zstd -d ./"$n"  ;;
          *)
                      echo "extract: '$n' - unknown archive method"
                      return 1
                      ;;
        esac
    done
}
