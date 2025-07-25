
# Bash setup

This file has a collection of config snippets for various terminal apps.
All code sections here can be run as-is, without any adjustments.

# Script header

```bash

# from `help set`:
# -e Exit immediately if a command exits with a non-zero status
# -u Treat unset variables as an error when substituting
set -eu

```

Note: the code section above must be the first in the file.
Commands in it are helpful in automated setups that transform this file into `.sh`.

# Required tools

These tools are needed for this setup.

```bash

which unzip curl wget > /dev/null || { sudo apt-get update; sudo apt-get install -y unzip curl wget; }

```

# Add bashrc directory

Enable using `~/.bashrc.d` for adjustments.

```bash

mkdir -p $HOME/.bashrc.d/
 cat << "EOF" > $HOME/.bashrc.d/include
# add support for bashrc.d
if [ -d ~/.bashrc.d ]; then
  for rc in ~/.bashrc.d/*.sh; do
    if [ -f "$rc" ]; then
      . "$rc"
    fi
  done
fi
EOF
grep -Fx '. ~/.bashrc.d/include' $HOME/.bashrc > /dev/null || echo '. ~/.bashrc.d/include' >> $HOME/.bashrc

```

# Bash autocomplete tweaks

```bash

 cat << "EOF" > $HOME/.inputrc
# Respect default shortcuts.
$include /etc/inputrc

# ctrl + Backspace
"\C-H": shell-backward-kill-word
# ctrl + delete
"\e[3;5~": shell-kill-word

# search history by prefix
## arrow up
"\e[A": history-search-backward
## arrow down
"\e[B": history-search-forward

set bell-style none
set completion-ignore-case on
# add / to dirs and * to executables
set visible-stats on
set colored-stats On
set mark-symlinked-directories On
# you don't need to press tab twice to show all options
set show-all-if-ambiguous on
set show-all-if-unmodified On
# avoid repeating prefix when in a folder with many similar files
set completion-prefix-display-length 3
EOF

```

References:
- https://www.ukuug.org/events/linux2003/papers/bash_tips/
- https://man.archlinux.org/man/readline.3
- https://tiswww.cwru.edu/php/chet/readline/readline.html

# Bash prompt

This is an opinionated convenient prompt:
- Username and host at the beginning
- Full path with the last directory highlighted
- Current date and time
- Timer for previous command
- Number of background jobs if any
- Exit code if not zero
- Command on a separate line, so you don't depend on the length of current path

Example: `user@host:/path/to/current/directory # 2000-01-01 15:10:30 # timer: 1.1ms ! jobs: 1  $? == 130 `.

Also, prompt history is saved after every command.

```bash

 cat << "EOF" > $HOME/.bashrc.d/0-prompt.sh

function timer_now {
  date +%s%N
}

function timer_start {
  timer_start=${timer_start:-$(timer_now)}
}

# https://stackoverflow.com/questions/1862510/how-can-the-last-commands-wall-time-be-put-in-the-bash-prompt
function timer_stop {
  local delta_us=$((($(timer_now) - $timer_start) / 1000))
  local us=$((delta_us % 1000))
  local ms=$(((delta_us / 1000) % 1000))
  local s=$(((delta_us / 1000000) % 60))
  local m=$(((delta_us / 60000000) % 60))
  local h=$((delta_us / 3600000000))
  # Goal: always show around 3 digits of accuracy
  if ((h > 0)); then timer_show=${h}h${m}m
  elif ((m > 0)); then timer_show=${m}m${s}s
  elif ((s >= 10)); then timer_show=${s}.$((ms / 100))s
  elif ((s > 0)); then timer_show=${s}.$(printf %03d $ms)s
  elif ((ms >= 100)); then timer_show=${ms}ms
  elif ((ms > 0)); then timer_show=${ms}.$((us / 100))ms
  else timer_show=${us}us
  fi
  unset timer_start
}

term_reset="$(tput sgr0)"
# term_reset='\[\e[0m\]'
term_bold="$(tput bold)"
term_dim="$(tput dim)"
term_underscore="$(tput smul)"
term_red="$(tput setaf 1)"
term_green="$(tput setaf 2)"
term_yellow="$(tput setaf 3)"
term_magenta="$(tput setaf 5)"
term_cyan="$(tput setaf 6)"
term_white="$(tput setaf 7)"
term_standout="$(tput smso)"

function __prompt_command() {
  # $? check needs to be the first command
  local prev_exit="$?"
  timer_stop

  # PS1="$term_reset"
  PS1="\n"
  PS1+="${debian_chroot:+($debian_chroot)}"
  # user
  PS1+="$term_yellow\u$term_reset"
  PS1+="$term_bold@$term_reset"
  # host
  PS1+="$term_magenta\H$term_reset"

  PS1+=":"

  # path
  dir=${PWD/#${HOME//'/'/'\/'}/\~}
  if [ ! "$dir" = "~" ]; then
    PS1+="$term_green${dir%\/*}/$term_reset"
  fi
  PS1+="$term_green$term_bold${dir/*\/}$term_reset"

  # datetime
  PS1+=" $term_yellow# \D{%F %T} #$term_reset"

  PS1+=" timer: $timer_show"

  PS1+='$([ \j -gt 0 ] && echo " $term_cyan$term_bold! jobs: \j$term_reset")'

  if [ $prev_exit != 0 ]; then
    PS1+=" $term_red$term_bold$term_standout \\\$? == $prev_exit $term_reset"
  fi

  PS1+="\n"
  PS1+="\\\$ "
  # alt: make $ yellow and bold
  # PS1+='\[\e[1;33m\]'"\\\$ "'\[\e[0m\]'
}

function before_command() {
  timer_start
  # save history right after command has been sent
  history -a
}

trap 'before_command' DEBUG
PROMPT_COMMAND=__prompt_command
EOF

```

References:
- `tput`: https://web.archive.org/web/20230405000510/https://wiki.bash-hackers.org/scripting/terminalcodes
- `tput`: https://tldp.org/HOWTO/Bash-Prompt-HOWTO/x405.html
- ps1 escape letters: https://tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html
- If you want to see what `tput` actually uses: `tput setaf 3 | cat -v`
- - https://unix.stackexchange.com/questions/274453/is-there-any-objective-benefit-to-escape-sequences-over-tput

# Better `ls`

```bash

# use more and better colors for ls
curl -fsSL "https://github.com/trapd00r/LS_COLORS/raw/refs/heads/master/lscolors.sh" > $HOME/.bashrc.d/0-ls-colors.sh

# add more default args to ls
 cat << "EOF" > $HOME/.bashrc.d/0-better-ls.sh
! alias ls > /dev/null 2> /dev/null || unalias ls
! alias ll > /dev/null 2> /dev/null || unalias ll
! alias l > /dev/null 2> /dev/null || unalias l

if ls --color -d . > /dev/null 2>&1; then  # GNU ls
  export COLUMNS # Remember columns for subprocesses.
  eval "$(dircolors)"
  function ls {
    # -F, --classify: append indicator (one of */=>@|) to entries
    # -h, --human-readable: with -l and -s, print sizes like 1K 234M 2G etc.
    # -v: natural sort of (version) numbers within text
    # --author: with -l, print the author of each file
    # -C: list entries by columns instead of just using lines (conflicts with -l)
    command ls -Fhv --color=always --time-style=long-iso -C "$@"
    # optionally: use less to avoid overflowing the screen while still keeping the color
    # command ls -Fhv --color=always --time-style=long-iso -C "$@" | less -R -X -F
  }
  function ll() {
    # -s: print disk allocation for each file
    echo "Alloc|Perms,Links|Owner|Group|Size| Mod. Date Time |Name"
    ls -las "$@"
  }
  alias l=ll
fi
EOF

```

References:
- https://www.topbug.net/blog/2016/11/28/a-better-ls-command/
- https://github.com/trapd00r/LS_COLORS

# Nano settings

```bash

# syntax highlights for many languages
[ -d $HOME/.nano/ ] || curl https://raw.githubusercontent.com/galenguyer/nano-syntax-highlighting/master/install.sh | bash || rm -rf $HOME/.nano/
# installs into ~/.nano/

 cat << EOF > $HOME/.bashrc.d/0-editor.sh
export EDITOR=nano
EOF

 cat << EOF > $HOME/.nanorc
set tabsize 2
set tabstospaces

set wordbounds
set zap
set linenumbers
set smarthome
set autoindent
set afterends
set wordchars "_"
set atblanks
set constantshow
set indicator
set minibar
set nowrap

# alt+shift+Z to switch word wrap
bind M-z softwrap all

bind ^Z undo all
bind ^Y redo all
bind M-f whereis all
bind F3 findnext all
# F15 is shift+F3
bind F15 findprevious all

# ^H is ctrl + Backspace
bind ^H chopwordleft all
# ^W is "delete word" in bash,
# terminals often map it from ctrl + Backspace
bind ^W chopwordleft all
# since ^W is no longer used for forward search, use ^Q instead
bind ^Q whereis all

bind M-d chopwordright main
bind ^/ comment main
bind ^L linenumbers main
bind M-K copy main
bind M-U paste main

# ctrl+D - duplicate current line
# does not work on nano 6.2 and below, install nano 7.2
bind ^D "{copy}{paste}{up}" main
# Shift + F1, Shift + F2 - move line up/down
# you can set up terminal to send ctrl+UP as F13, ctrl+DOWN as F14
bind F13 "{cut}{up}{paste}{up}" main
bind F14 "{cut}{down}{paste}{up}" main

# unbind justify
unbind ^J all
unbind M-J all
unbind F4 all
# cut from current to the end of file
unbind M-T all

include ~/.nano/*.nanorc
EOF

```

Toggle lines with `ctrl + L` if you want to select multiple lines with mouse.

References:
- https://github.com/galenguyer/nano-syntax-highlighting
- https://github.com/davidhcefx/Modern-Nano-Keybindings
- https://stackoverflow.com/questions/33217564/move-whole-line-up-down-shortcut-in-nano-analogue-to-intellij-or-visual-studio

# Additional colors

```bash

 cat << EOF > $HOME/.bashrc.d/0-color-aliases.sh
alias ip='ip --color=auto'
alias grep='grep --color=auto'

# an alias for sudo allows alias expansion
# when using 'sudo grep' and similar commands
alias sudo='sudo '
EOF

```

# Unlimited history

```bash

sed -i -E -e 's/^(.*)HISTSIZE/# \1HISTSIZE/' -e 's/^(.*)HISTFILESIZE/# \1HISTFILESIZE/' $HOME/.bashrc

 cat << EOF > $HOME/.bashrc.d/0-bash-history.sh
# Eternal bash history.
# ---------------------
# Undocumented feature which sets the size to "unlimited".
# http://stackoverflow.com/questions/9457233/unlimited-bash-history
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
# Change the file location because certain bash sessions truncate .bash_history file upon close.
# http://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
export HISTFILE=~/.bash_eternal_history
EOF

```

References:
- https://stackoverflow.com/questions/9457233/unlimited-bash-history

# Better ZFS autocompletion

By default ZFS prints all datasets matching prefix.
For example, if you type `ta<TAB>`, ZFS autocompletion
will suggest `tank`, `tank/data`, `tank/data/child`, etc.
If you have a lot of datasets, this will cover your whole screen
and request you to close the `less` terminal before you continue.

Additionally, for each `tank/data` option ZFS suggests `tank/data@`, cluttering the output.

This script changes the behavior the following way:
- Only a single level of detail is printed
- If exact match for completion exists, suggest `@` and `/`
- If only a single option exists, suggest `@` and `/`

```bash

cat << "EOF" > $HOME/.bashrc.d/10-zfs-completion-patch.sh
# skip the script if ZFS is not installed
if [ -f /usr/share/bash-completion/completions/zfs ]; then

# source the original file to load it into bash
# otherwise bash will overwrite __zfs_match_snapshot
# when it loads this file on first ZFS completion
. /usr/share/bash-completion/completions/zfs

__zfs_match_snapshot()
{
  local base_dataset="${cur%@*}"
  if [[ "$base_dataset" != "$cur" ]]
  then
    $__ZFS_CMD list -H -o name -s name -t snapshot -d 1 "$base_dataset"
    return 0
  fi
  # Check if exact dataset match exists.
  # We can't skip this:
  #   If both "$cur" and "$cur-suffix" exist
  #   without this check nothing would ever show @ and / for $cur without suffix
  if [[ "$cur" != "" ]] && __zfs_list_datasets "$cur" &> /dev/null
  then
    # suggest snapshot suffix
    echo "$cur"@
    local num_children
    # zfs list includes the named dataset in addition to its children
    num_children=$(__zfs_list_datasets -d 1 "${cur%/}" 2> /dev/null | wc -l)
    if [[ $num_children != 1 ]]; then
      # suggest child datasets
      echo "$cur"/
    fi
  fi

  local parent_dataset="${base_dataset%/*}"
  if [[ ! "$base_dataset" == *"/"* ]]; then
    parent_dataset=""
  fi
  local datasets
  if [[ "$parent_dataset" == "" ]]; then
    datasets="$(__zfs_list_datasets -d 0)"
  else
    # filter on prefix to be able to correctly count results
    datasets="$(__zfs_list_datasets "$parent_dataset" -d 1 | grep "$cur")"
  fi
  echo "$datasets"
  local num_result
  num_result=$(echo "$datasets" | wc -l)
  # if there is only a single result, suggest more options
  # to stop bash from ending the completion
  if [[ $num_result == 1 ]]; then
    # suggest snapshot suffix
    echo "$datasets" | awk '{print $1 "@"}'
    local num_children
    # zfs list includes the named dataset in addition to its children
    num_children=$(__zfs_list_datasets -d 1 "$datasets" 2> /dev/null | wc -l)
    if [[ $num_children != 1 ]]; then
      # suggest child datasets
      echo "$datasets"/
    fi
  fi
}

fi
EOF

```

# Install useful tools

```bash

which jq > /dev/null || { sudo apt-get update; sudo apt-get install -y jq; }

# yq in the main debian repository seems unusable
which yq > /dev/null || { sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && sudo chmod +x /usr/bin/yq; }

which yamlfmt > /dev/null || {
  tmp=$(mktemp -d)
  (
    cd $tmp;
    wget https://github.com/google/yamlfmt/releases/download/v0.17.2/yamlfmt_0.17.2_Linux_x86_64.tar.gz -O ./yamlfmt.tar.gz
    tar -xvzf ./yamlfmt.tar.gz
    chmod +x ./yamlfmt
    sudo mv ./yamlfmt /usr/bin/yamlfmt
    cd /
    rm -r $tmp
  )
}

```
