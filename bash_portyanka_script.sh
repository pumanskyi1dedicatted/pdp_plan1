#!/bin/bash
set -euo pipefail
readonly ADMIN_GROUP="admins"

add_group(){

local group="$1"

if getent group "$group" > /dev/null
then
    echo "The required group has been detected"
elif groupadd "$group"
then
    echo "The group has been created"
else
    echo "The group wasn't created. Something went wrong" >&2
    return 1
fi
}

grant_sudo(){
local group="$1"
local path_to_file="/etc/sudoers.d/${group}"
local group_privileges="%${group} ALL=(ALL:ALL) ALL"

if [[ -f "$path_to_file" ]] && cmp -s "$path_to_file" <(printf '%s\n' "$group_privileges")
then
    echo "File $group is already configured"
    return 0
fi
local tmp
tmp=$(mktemp)
printf '%s\n' "$group_privileges" > "$tmp"
if ! visudo -cf "$tmp" > /dev/null
then
    echo "sudoers rule for $group failed validation" >&2
    rm -f "$tmp"
    return 1
fi
install -m 0440 -o root -g root "$tmp" "$path_to_file"
rm -f "$tmp"
if ! visudo -c > /dev/null
then
    echo "sudo config invalid after install, rolled back" >&2
    rm -f "$path_to_file"
    return 1
fi
echo "sudo granted to group $group"
}

create_user(){
local user="$1"
local group="$2"

if getent passwd "$user" > /dev/null
then
    echo "User $user already exists. Nothing to create"
elif useradd -m -s /bin/bash "$user"
then
    echo "The user $user has been created"
else
    echo "There is an error with creating a user $user" >&2
    return 1
fi

if id -nG "$user" | tr ' ' '\n' | grep -qx "$group"
then
    echo "User $user already in the $group group"
elif usermod -aG "$group" "$user"
then
    echo "The user $user has been successfully added to the $group group"
else
    echo "The user $user hasn't been added to the $group group" >&2
    return 1
fi
}

set_password(){
local user="$1"
local password

echo "Set up the password:" >&2
read -rs password
echo >&2
if [[ -z "$password" ]]
then
    echo "Please fill the password" >&2
    return 1
fi
if chpasswd <<< "$user:$password"
then
    echo "Password for $user has been added successfully"
else
    echo "Password for $user hasn't been added. Please try again" >&2
    return 1
fi
}

parse_args() {
    username="${1:-}"

    if [[ -z "$username" ]]; then
        echo "Usage: $0 <username>" >&2
        exit 1
    fi
    if [ $# -ne 1 ]
    then
        echo "Usage: $0 <username>" >&2
        exit 1
fi

}

if [ $EUID -ne 0 ]
then
    echo "This script must be run with root privileges" >&2
    exit 1
fi

parse_args "$@"
add_group "$ADMIN_GROUP";
grant_sudo "$ADMIN_GROUP";
create_user "$username" "$ADMIN_GROUP";
set_password "$username"


