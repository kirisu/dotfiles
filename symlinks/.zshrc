#!/bin/bash

# pretty theme
BASE16_SHELL=$HOME/.config/base16-shell/
[ -n "$PS1" ] && [ -s $BASE16_SHELL/profile_helper.sh ] && eval "$($BASE16_SHELL/profile_helper.sh)"

# only define LC_CTYPE if undefined
if [[ -z "$LC_CTYPE" && -z "$LC_ALL" ]]; then export LC_CTYPE=${LANG%%:*}; fi

# split paths at forward slashes
WORDCHARS=$WORDCHARS:s:/:

# shortcut to this dotfiles path is $DOTFILES
export DOTFILES=$HOME/.dotfiles

# setup path
export PATH="$HOME/.local/bin:$DOTFILES/bin:$PATH"

# environment variables
for env in ~/.env; do source $env; done;

# set prompt colours
autoload -U colors && colors
if [ $UID -eq 0 ]; then NCOLOR="red"; else NCOLOR="white"; fi
if [[ x$WINDOW != x ]]; then SCREEN_NO="%B$WINDOW%b "; else SCREEN_NO=""; fi

# load in our custom functions/completions
fpath=($DOTFILES/functions $DOTFILES/completions $fpath)

# initialize autocomplete here, otherwise functions won't be loaded
autoload -Uz compinit && compinit -i -C -d $ZSH_VARDIR/comp-$HOST
autoload -U $DOTFILES/functions/*(:t)
autoload -U $DOTFILES/completions/*(:t)
zmodload -i zsh/complist
zmodload -a zsh/stat stat
zmodload -a zsh/zpty zpty
zmodload -ap zsh/mapfile mapfile

# load prompts
autoload -U promptinit && promptinit

# load in config files
typeset -U config_files
config_files=($DOTFILES/config/**/*.zsh)
for file in $config_files; do source $file; done
unset config_files

function curent_user() {
  echo "%{$fg[$NCOLOR]%}%B%n%b%{$reset_color%}"
}

function hostname() {
  echo "%{$fg_bold[red]%}%M%{$reset_color%}"
}

function current_dir() {
  echo "%{$fg[blue]%}%B%c/%b%{$reset_color%}"
}

function git_prompt_info() {
  ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
  ref=$(command git rev-parse --short HEAD 2> /dev/null) || return 0
  echo "%{$fg_bold[blue]%}(%{$fg_no_bold[yellow]%}%B${ref#refs/heads/}$(parse_git_dirty)$(parse_git_staged)$(parse_git_untracked)%b%{$fg_bold[blue]%})%{$reset_color%}$(parse_git_rev_list) "
}

function parse_git_dirty() {
  local STATUS=$(command git diff --name-only --word-diff=porcelain 2> /dev/null | tail -n1)
  if [[ -n $STATUS ]]; then echo "%{$fg_bold[red]%}·%{$reset_color%}"; fi
}

function parse_git_staged() {
  local DIFF=$(command git diff --name-only --staged --word-diff=porcelain 2> /dev/null | tail -n1)
  if [[ -n $DIFF ]]; then echo "%{$fg_bold[green]%}·%{$reset_color%}"; fi
}

function parse_git_untracked() {
  local LS=$(command git ls-files --others --exclude-standard 2> /dev/null | tail -n1)
  if [[ -n $LS ]]; then echo "%{$fg_bold[red]%}+%{$reset_color%}"; fi
}

function parse_git_rev_list() {
  local LEFT_AHEAD=$(command git rev-list --count origin/master..@ 2> /dev/null)
  local RIGHT_AHEAD=$(command git rev-list --count @..origin/master 2> /dev/null)
  if [[ $LEFT_AHEAD > 0 || $RIGHT_AHEAD > 0 ]]; then echo "[$(show_number $RIGHT_AHEAD red)…$(show_number $LEFT_AHEAD green)]"; fi
}

function show_number() {
  if [[ $1 != 0 ]]; then echo %{$fg_bold[$2]%}$1%{$reset_color%}; fi
}

function virtualenv_prompt_info() {
  local VENV=$(command echo $VIRTUAL_ENV 2> /dev/null)
  if [[ $VENV ]]; then echo "%{$fg_bold[yellow]%}[`basename \"$VIRTUAL_ENV\"`]%{$reset_color%} "; fi
}

function set_prompt() {
  PROMPT="$(curent_user)@$(hostname):$(current_dir) $(git_prompt_info)$(virtualenv_prompt_info)%(!.#.$) "
  RPROMPT='[%*]'
}

precmd_functions+=(set_prompt)