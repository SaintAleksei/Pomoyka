msg_size=${MSG_SIZE:-80}
log=${LOG:-.log.txt}

echo_fixed_size()
{
  local length="${#1}"
  if [ "$msg_size" -lt $length ]
  then
    msg_size=$length
  fi
  printf "%-${msg_size}s" "$1"
}

check_error()
{
  if [ $1 -eq 0 ]
  then
    echo -e "\e[32m[OK]\e[0m"
  else
    echo -e "\e[31m[ERROR]\e[0m (see file \"$log\")"
    if type cleanup &>/dev/null
    then
      cleanup
    fi
    exit 1
  fi
}

create_dir()
{
  echo_fixed_size "Creating directory $1..."
  if [ ! -d $1 ]
  then
    mkdir -p $(realpath $1) 1>/dev/null 2>$log
  fi
  check_error $?
}

do_with_check()
{
  local msg=$2
  if [ -z "$msg" ]
  then
    msg="Executing \"$1\"..."
  fi

  echo_fixed_size "$msg"
  $1 1>/dev/null 2>$log
  check_error $?
}
