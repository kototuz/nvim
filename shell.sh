#!/usr/bin/bash

kill_child() {
    pkill -SIGTERM -P $$
}

trap kill_child SIGINT SIGTERM
while true; do
    read -s cwd
    read -s cmd
    cd $cwd
    script -q -e -E always -c "$cmd" /dev/null
    echo -e "\n[Process exited $?]"
done
