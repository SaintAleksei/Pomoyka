#!/bin/bash

# TODO: Check requirements

source "../script/source.sh"

msg_size="${MSG_SIZE:-80}"
echo "Using msg_size    \"$msg_size\""
log="${LOG:-.umount_storage.sh_log.txt}"
echo "Using log         \"$log\""
local_path=$(realpath "${LOCAL_PATH:-$HOME/storage}")
echo "Using local_path  \"$local_path\""

echo_fixed_size "Unmounting decrtypted storage \"${local_path}/decrypted..."
fusermount -u "${local_path}/decrypted" 1>/dev/null 2>$log
check_error 0

echo_fixed_size "Unmounting remote storage     \"${local_path}/encrypted..."
fusermount -u "${local_path}/encrypted" 1>/dev/null 2>$log
check_error 0
