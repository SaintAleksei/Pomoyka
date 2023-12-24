#!/bin/bash

# TODO: Documentation
# TODO: Automatic programm help building

echo_fixed_length="${ECHO_FIXED_LENGTH:-60}"

echo_fixed()
{
  local    msg="$1"
  local length="${#1}"

  if [ "$echo_fixed_length" -lt $length ]
  then
    echo_fixed_length=$length
  fi
  printf "%-${echo_fixed_length}s" "$msg"
}

echo_ok()
{
  echo -e " [ \e[32m  OK \e[0m ]"
}

# $1 - error message
echo_error()
{
  echo -e " [ \e[31mERROR\e[0m ] ($1)"
}

# $1 - error message
echo_result()
{
  local error="$?"
  local   msg="$1"

  if [ $error -eq 0 ]
  then
    echo_ok
  else
    echo_error "$msg"
  fi

  return $error
}

echo_err()
{
  local msg="$1"

  echo -e "[\e[31mERR\e[0m] $msg" 2>/dev/null
}

echo_inf()
{
  local msg="$1"

  echo -e "[\e[32mINF\e[0m] $msg"
}

# $1 Command to execute
# $2 Error message
# $3 Cleanup callback
execute_with_check()
{
  local     cmd="$1"
  local     msg="${2:-"Execution failed"}" 
  local cleanup="$3"

  echo_inf "$cmd"
  if ! eval "$cmd 1>/dev/null"
  then
    echo_err "$msg"
    eval "$cleanup" &>/dev/null
    return 1
  fi

  return 0
}

check_executable()
{
  local executable="${1%% *}"

  echo_inf "Check if executable \"$executable\" exists"
  which "$executable" &>/dev/null || echo_err "Not found" && return 1

  return 0
}

check_root()
{
  echo_inf "Check if root"
  [ "$(id -u 2>/dev/null)" = "0" ] || echo_err "Not root" && return 1

  return 0
}

check_package_installed()
{
  local package="${1%% *}"

  echo_fixed  "Check if package \"$package\" installed"
  dpkg-query --show "$package" || echo_err "Not found" && return 1

  return 0
}

# $1 String with files
get_packages_by_files()
{
  local    files="$1"
  local packages=""
  local   output=""

  check_executable "dpkg" &>/dev/null || return 1

  for file in $files
  do
    # Convert executable to path if it possible
    output=$(which "$file") && file="$output"

    # Convert path to absolute path
    file=$(realpath "$file")

    output=$(dpkg -S "$file" 2>/dev/null || return 1)

    packages="$packages ${output%%: *}"
  done

  echo "$packages"

  return 0
}

# $1 String with packages
get_uninstalled_packages()
{
  local    packages="$1"
  local uninstalled=""

  check_executable "dpkg-query" &>/dev/null || return 1

  for package in $packages
  do
    if ! check_package_installed "$package" &>/dev/null
    then
      uninstalled="$uninstalled $package"
    fi
  done

  echo "$uninstalled"

  return 0;
}

# $1 String with packages to install
install_packages()
{
  local requirements="$1"
  local      failcnt=0
  local       output=""

  check_root                                || return 1

  check_executable      "apt-get"           || return 1
  check_executable      "apt-cache"         || return 1

  execute_with_check    "apt-get update"              \
                        "Failed to update apt cache" || return 1

  for req in $requirements
  do
      echo_inf "Check if pacakge \"$req\" exists"
      if ! apt-cache show "$req" &>/dev/null
      then
        echo_err "Failed to find package"
        failcnt=$((failcnt + 1))
        continue
      fi

      echo_inf "Try to install package \"$req\"..."
      if ! apt-get install -y "$req" 1>/dev/null
      then
        echo_err "Failed to install package" 
        failcnt=$((failcnt + 1))
        continue
      fi
  done

  return $failcnt
} 

# $1 String with packages
install_packages_by_files()
{
  local       files="$1" 
  local    packages=$(get_packages_by_files "$files")
  local uninstalled=$(get_packages_uninstalled "$packages")

  install_packages "$uninstalled"
}
