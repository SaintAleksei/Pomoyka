#!/bin/bash

# TODO: Check requirements

source "../script/source.sh"

msg_size="${MSG_SIZE:-100}"
echo "Using msg_size    \"$msg_size\""
log="${LOG:-.mount_storage.sh_log.txt}"
echo "Using log         \"$log\""
login="${LOGIN:-$(whoami)}"
echo "Using login       \"$login\""
host="${HOST:-localhost}"
echo "Using host        \"$host\""
local_path=$(realpath "${LOCAL_PATH:-$HOME/storage}")
echo "Using local_path  \"$local_path\""
remote_path=$(realpath "${REMOTE_PATH:-/home/$login/storage}")
echo "Using remote_path \"$remote_path\""

cleanup()
{
  fusermount -u $local_path/decrypted &>/dev/null
  fusermount -u $local_path/encrypted &>/dev/null
}

cleanup

create_dir $local_path
create_dir $local_path/encrypted

do_with_check "sshfs $login@$host:$remote_path $local_path/encrypted" \
              "Mounting remote $remote_path to $local_path/encrypted..."

create_dir $local_path/decrypted

read -s -p "$(echo_fixed_size 'Enter password for decryption: ')" passwd
check_error $?

do_with_check "echo "$passwd" | gocryptfs $local_path/encrypted $local_path/decrypted" \
              "Decrypting $local_path/encrypted to $local_path/decrypted..."
