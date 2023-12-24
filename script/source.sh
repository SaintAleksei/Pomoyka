#!/bin/bash

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
  echo -e "[ \e[32m  OK \e[0m ]"
}

# $1 - error message
echo_error()
{
  echo -e "[ \e[31mERROR\e[0m ] ($1)"
}

# $1 - error message
echo_result()
{
  local error=$?
  local   msg=$1

  if [ $error -eq 0 ]
  then
    echo_ok
  else
    echo_error "$msg"
  fi

  return $error
}

# $1 Command to execute
execute_with_check()
{
  local output=""

  echo_fixed       "Executing \"$1\"..."
  output=$($1 2>&1)
  if ! echo_result "Execution failed"
  then
    printf "$output"
    return 1
  fi

  return 0
}

check_executable()
{
  local executable="${1%% *}"

  echo_fixed  "Checking if executable \"$executable\" exists..."
  which "$executable" &>/dev/null
  echo_result "Not found" || return 1

  return 0
}

check_root()
{
  echo_fixed  "Checking id for root..."
  [ "$(id -u 2>/dev/null)" = "0" ]
  echo_result "Not root"  || return 1

  return 0
}

check_package_installed()
{
  local package="${1%% *}"

  echo_fixed  "Checking if package \"$package\" installed"
  dpkg-query --show "$package"
  echo_result "Not found" || return 1

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

  execute_with_check    "apt-get update"    || return 1

  for req in $requirements
  do
      echo_fixed        "Checking if pacakge \"$req\" exists..."
      apt-cache show "$req" &>/dev/null
      if ! echo_result  "Not found"
      then
        failcnt=$((failcnt + 1))
        continue
      fi

      echo_fixed        "Trying to install package \"$req\"..."
      output=$(apt-get install -y "$req")
      if ! echo_result  "Installation failed"
      then
        printf "$output"
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

echo "This are some functions usefull for source: "
echo "   echo_fixed                - echo string with fixed spaces filling"
echo "   echo_ok                   - echo OK message"
echo "   echo_error                - echo ERROR message"
echo "   echo_result               - echo message depending on the last command result"
echo "   execute_with_check        - execute command with result checking"
echo "   check_executable          - check if executable exist"
echo "   check_root                - check if current user is root"
echo "   check_package_installed   - check if package is installed"
echo "   get_packages_by_files     - get list of packages from list of files"
echo "   get_packages_uninstalled  - get list of uninstalled packages"
echo "   install_packages          - install packages"
echo "   install_packages_by_files - install packages by files belonging them"
echo "Look at file you just executed for details"
