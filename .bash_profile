#!/usr/bin/bash

if [ -z "$GXT_" ]; then
export GXT_=1

export EDITOR=/usr/bin/vim

alias l="LC_COLLATE=C /bin/ls -CFal --color=always"

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
cd "$PWD"

cf_db_file="/var/.cf_db_$logname_"
init_cf() {
  if [ ! -e "$cf_db_file" ]; then
    touch "$cf_db_file"
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
  printf "# %s: %s: %s(%s)@%s%s\n# " \
    "\$?" "\$cd_pwd" $logname_ $whoami_ $(hostname)
)


fi # -z "$GXT_"
