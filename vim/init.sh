#!/bin/bash

log_file=error.txt
echo -n "" > $log_file

check_result()
{
  if [ $? -eq 0 ]
  then
    echo -e " \e[32m[OK]\e[0m"
  else
    echo -e " \e[31m[ERROR]\e[0m (see $log_file)"
    exit 1
  fi
}

echo -n "Looking for vim executable..."
vim --version 1>/dev/null 2>$log_file
check_result

echo -n "Installing vim-plug...       "
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
     https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim 1>/dev/null 2>$log_file
check_result

echo -n "Installing .vimrc file...    "
cp .vimrc ~/.vimrc 1>/dev/null 2>$log_file
check_result
