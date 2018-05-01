#!/bin/bash

help() {
    echo " !!! INSTALL auto-expect into system."
    echo "   `basename $0` -i <rld> -p </usr/local/bin/> -c <~/.rld.d/>"
    echo "          -i rld      command name, default rld"
    echo "                      rld - remote login do ..."
    echo "          -p /usr/local/bin/"
    echo "                      install path, require sudo"
    echo "          -c ~/.rld.d/"
    echo "                      config file path"
    echo
    echo "          -h          show this message"
    exit 0
}

echo "RUN: `basename $0` -i rld -p /usr/local/bin/ -c ~/.rld.d/"
echo -n " press any key to continue"

read -t 5 -n 1

NAME_I=rld
PATH_P=/usr/local/bin
PATH_C=

until [[ $# == 0 ]]
do
    case "$1" in
        -i) NAME_I=$2; shift;;
        -p) PATH_P=$2; shift;;
        -c) PATH_C=$2; shift;;
        -h) help;;
    esac

    shift
done

[[ -z $PATH_C ]] && PATH_C=$HOME/.$NAME_I.d

# echo $NAME_I, $PATH_P, $PATH_C

mkdir -p $PATH_C
[[ ! -f $PATH_C/server ]] && cp config/server $PATH_C
[[ ! -f $PATH_C/setting ]] && cp config/setting* $PATH_C

: > $NAME_I
chmod +x $NAME_I

cat > $NAME_I <<<'#!/usr/bin/env expect

set RC_PATH '"$PATH_C"'
'

cat tcl/cmd.tcl >> $NAME_I
echo >> $NAME_I
cat tcl/help.tcl >> $NAME_I
echo >> $NAME_I
cat tcl/conf.tcl >> $NAME_I
echo >> $NAME_I

cat >> $NAME_I <<<'
proc Main {argc argv} {
    global server_from_conf
    parray server_from_conf
    if {$argc == 0} { usage }

    set cmd "Cmd_[lindex $argv 0]"
    if {[info procs $cmd] != $cmd} {
        eval Cmd_ssh $argv
    } else {
        eval $cmd [lreplace $argv 0 0]
    }

}

proc Error {message} {
    switch $message {
        -100    { puts "读取文件失败."}
        -200    { puts "找不到指定的服务器"}
        -999    {}
        default { puts "error, $message" }
    }
}

if [catch {Conf_init} message] {
    Error $message
} elseif [catch {Main $argc $argv} message] {
    Error $message
}
'

sudo cp $NAME_I $PATH_P

