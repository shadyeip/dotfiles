# File: ~/.zsh/completions.zsh

# Completion system is initialized by Oh My Zsh (compinit).
# This file configures completion styles only.

# Cache completion to speed things up
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Completion menu settings
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''

# Case-insensitive (all), partial-word and substring completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'

# Fuzzy match mistyped completions
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Increase the number of errors allowed based on the length of the typed word
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Ignore completion functions for commands you don't have
zstyle ':completion:*:functions' ignored-patterns '_*'

# Array completion element sorting
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Directories
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# Environmental Variables
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

# Populate hostname completion
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'

# Don't complete uninteresting users
zstyle ':completion:*:*:*:users' ignored-patterns \
  adm amanda apache avahi beaglidx bin cacti canna clamav daemon \
  dbus distcache dovecot fax ftp games gdm gkrellmd gopher \
  hacluster haldaemon halt hsqldb ident junkbust ldap lp mail \
  mailman mailnull mldonkey mysql nagios \
  named netdump news nfsnobody nobody nscd ntp nut nx openvpn \
  operator pcap postfix postgres privoxy pulse pvm quagga radvd \
  rpc rpcuser rpm shutdown squid sshd sync uucp vcsa xfs '_*'

# ... unless we really want to.
zstyle '*' single-ignored show

# Ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,comm -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# SSH/SCP/RSYNC
zstyle ':completion:*:(ssh|scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# File: ~/.zsh/go_python_completions.zsh

# Go (Golang) Completions
if (( $+commands[go] )); then
    # Enable go command completion
    compdef _go go

    # Custom completions for common go commands
    _go_custom() {
        local -a commands
        commands=(
            'build:compile packages and dependencies'
            'run:compile and run Go program'
            'test:test packages'
            'get:add dependencies to current module and install them'
            'install:compile and install packages and dependencies'
            'fmt:gofmt (reformat) package sources'
            'vet:report likely mistakes in packages'
            'mod:module maintenance'
        )
        _describe -t commands 'go command' commands
    }
    compdef _go_custom go

    # Completion for go mod
    _go_mod() {
        local -a subcommands
        subcommands=(
            'init:initialize new module in current directory'
            'tidy:add missing and remove unused modules'
            'vendor:make vendored copy of dependencies'
            'verify:verify dependencies have expected content'
            'download:download modules to local cache'
        )
        _describe -t subcommands 'go mod subcommand' subcommands
    }
    compdef _go_mod 'go mod'
fi

# Python Completions
if (( $+commands[python] )); then
    # Enable python command completion
    compdef _python python

    # Custom completions for common python commands
    _python_custom() {
        local -a commands
        commands=(
            '-m:run library module as a script'
            '-c:program passed in as string'
            '-V:print the Python version number and exit'
        )
        _describe -t commands 'python command' commands
    }
    compdef _python_custom python

    # pip completions (lazy — avoid eval on every shell start)
    if (( $+commands[pip] )); then
        compdef _pip_completion pip
    fi

    # virtualenv completions
    if (( $+commands[virtualenv] )); then
        compdef _virtualenv virtualenv
    fi

    # pytest completions
    if (( $+commands[pytest] )); then
        _pytest() {
            local -a commands
            commands=(
                '-v:increase verbosity'
                '-q:decrease verbosity'
                '-k:only run tests which match the given substring expression'
                '-m:only run tests matching given mark expression'
                '--pdb:start the interactive Python debugger on errors'
            )
            _describe -t commands 'pytest command' commands
        }
        compdef _pytest pytest
    fi
fi

# Django completions (if django-admin is installed)
if (( $+commands[django-admin] )); then
    _django_completion() {
        local -a commands
        commands=(
            'runserver:start the development server'
            'migrate:apply database migrations'
            'makemigrations:create new migrations based on models changes'
            'shell:start the interactive Python shell'
            'test:run tests'
            'createsuperuser:create a superuser'
            'collectstatic:collect static files'
        )
        _describe -t commands 'django-admin command' commands
    }
    compdef _django_completion django-admin manage.py
fi
