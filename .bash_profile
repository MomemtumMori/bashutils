#!/usr/bin/bash

if [ -z "$GXT_" ] || [ -n "$TMUX" ]; then
export GXT_=1

export EDITOR=/usr/bin/vim
export LC_ALL=en_US.utf8
export LANG=$LC_ALL
export LANGUAGE=$LC_ALL
export PATH=$PATH:$HOME/p/bin:$HOME/local/bin

platform=unknown
uname_=$(which uname)
if [ -x "$uname_" ]; then
  uname_str=$(uname)
  if [ "$uname_str" == "Linux" ]; then
    platform=linux
  fi
  if [ "$uname_str" == "MSYS_NT-6.1" ]; then
    platform=windows
  fi
fi

if [ "$platform" == "linux" ]; then
  if [ -x "$(which gsettings)" ]; then
    # set unity workspace size
    gsettings set org.compiz.core:/org/compiz/profiles/unity/plugins/core/ hsize 4
    gsettings set org.compiz.core:/org/compiz/profiles/unity/plugins/core/ vsize 4
  fi
fi

alias l="LC_COLLATE=C /bin/ls -CFal --color=auto"

init_logname_() {
  logname_=$SUDO_USER
  whoami_=$(whoami)
  if [ -z "$logname_" ]; then
    logname_="$whoami_"
  fi
  if [ "$logname_" == "$whoami_" ]; then
    whoami_='.'
  fi
}
init_logname_

# http://stackoverflow.com/a/29310477
expand_path() {
  local defaultPath='~/' 
  local path
  local -a pathElements resultPathElements
  IFS=':' read -r -a pathElements <<<"${1:-$defaultPath}"
  : "${pathElements[@]}"
  for path in "${pathElements[@]}"; do
    : "$path"
    case $path in
      "~+"/*)
        path=$PWD/${path#"~+/"}
        ;;
      "~-"/*)
        path=$OLDPWD/${path#"~-/"}
        ;;
      "~"/*)
        path=$HOME/${path#"~/"}
        ;;
      "~"*)
        username=${path%%/*}
        username=${username#"~"}
        IFS=: read _ _ _ _ _ homedir _ < <(getent passwd "$username")
        if [[ $path = */* ]]; then
          path=${homedir}/${path#*/}
        else
          path=$homedir
        fi
        ;;
    esac
    resultPathElements+=( "$path" )
  done
  local result
  printf -v result '%s:' "${resultPathElements[@]}"
  printf '%s\n' "${result%:}"
}

cd_() {
  command cd "$(expand_path $1)"
  cd_pwd=${PWD##$HOME}
  if [ "$cd_pwd" != "$PWD" ]; then
    cd_pwd="~$cd_pwd"
  fi
}
alias cd="cd_"
cd_ "$PWD"

cf_db_file="/var/.cf_db_$logname_"
cf_db_file_fallback="$HOME/.cf_db_$logname_"
init_cf() {
  if [ ! -e "$cf_db_file" ]; then
    touch "$cf_db_file" >/dev/null 2>&1
  fi
  if [ ! -e "$cf_db_file" ] && [ ! -e "$cf_db_file_fallback" ]; then
    touch "$cf_db_file_fallback"
  fi
  if [ -e "$cf_db_file_fallback" ]; then
    tmp_="$cf_db_file"
    cf_db_file="$cf_db_file_fallback"
    cf_db_file_fallback="$tmp"
  fi
}
init_cf


cf() {
  local fav_path="$1"
  if [ "$fav_path" == "." ]; then
    local fav_id="$2"
    if [ -z "$fav_id" ]; then
      echo "need id of new favorite" 1>&2
      return 1
    fi

    echo "$fav_id:$cd_pwd" >>"$cf_db_file"
  else
    local fav_id="${fav_path%%/*}"
    local real_path="$(cat "$cf_db_file" | \
      awk -F ':' -v "fav_id=$fav_id" '{if ($1 == fav_id) print $2}' | \
      tail -n 1)"
    if [ -z "$real_path" ]; then
      echo "can't find favorite $fav_id in $cf_db_file" 1>&2
      return 1
    fi

    local crumbs="${fav_path#*/}"
    if [ "$crumbs" == "$fav_path" ]; then
      crumbs=''
    fi

    local full_path="$real_path/$crumbs"
    cd "$full_path"
  fi
}


PS1=$(
  printf "# \e[36m%s\e[0m: \e[36m%s\e[0m: \e[36m%s(%s)@%s%s\n\e[0m# " \
    "\$?" "\$cd_pwd" $logname_ $whoami_ $(hostname)
)


sshx () {
  scp ~/git/bashutils/.bash_profile $1:/tmp/.gxtp
  ssh $1 
}

fi # -z "$GXT_"

if command -v tmux>/dev/null; then
  [[ ! $TERM =~ screen ]] && [ -z $TMUX ] && exec tmux
fi
