#!/bin/bash

help() {
    echo " @_@ INSTALL rd into system."
    echo "   `basename $0` -i rd -p /usr/local/bin/ -c ~/.rd.d/"
    echo "          -n rd       command name, default rd"
    echo "                      rd - remote login do ..."
    echo "          -i /usr/local/bin/"
    echo "                      install path, require sudo"
    echo "          -c ~/.rd.d/"
    echo "                      config file path"
    echo
    echo "          -h          show this message"
    exit 0
}

NAME_N=rd
PATH_I=/usr/local/bin
PATH_C=

until [[ $# == 0 ]]
do
    case "$1" in
        -i) NAME_N=$2; shift;;
        -p) PATH_I=$2; shift;;
        -c) PATH_C=$2; shift;;
        -h|--help) help;;
    esac

    shift
done

echo "RUN: `basename $0` -i rd -p /usr/local/bin/ -c ~/.rd.d/"
echo -n " press any key to continue, 'q' to quit: "

read -t 5 -n 1 r

[[ $r == "q" || $r == "Q" ]] && { echo; exit 0; }

[[ -z $PATH_C ]] && PATH_C=$HOME/.$NAME_N.d

# echo $NAME_N, $PATH_I, $PATH_C

mkdir -p $PATH_C || {
    PATH_C=$HOME/.$NAME_N.d
    mkdir -p $PATH_C
}
DIR_PATH=`dirname $0`

[[ ! -f $PATH_C/server ]] && cp config/server $PATH_C
[[ ! -f $PATH_C/setting ]] && cp config/setting* $PATH_C

touch $NAME_N &>/dev/null || { NAME_N=/tmp/$NAME_N; :>$NAME_N; }
chmod +x $NAME_N

cat > $NAME_N <<<'#!/usr/bin/env expect

set RC_PATH '"$PATH_C"'
'

cat $DIR_PATH/tcl/cmd.tcl >> $NAME_N
echo >> $NAME_N
cat $DIR_PATH/tcl/help.tcl >> $NAME_N
echo >> $NAME_N
cat $DIR_PATH/tcl/conf.tcl >> $NAME_N
echo >> $NAME_N

cat >> $NAME_N <<<'
proc Main {argc argv} {
    global server_from_conf
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
        -400    { puts "未检测到远程服务器"}
        -401    { puts "无法拷贝不存在的本地文件"}
        -402    { puts "远程拷贝到本地时不允许覆盖本地文件"}
        -403    { puts "无法创建本地目录"}
        -500    { puts "无法理解参数以':'开始"}
        -501    { puts "多':'冲突"}
        -502    { puts "无法sshfs远程目录到本地文件"}
        -503    { puts "无法创建sshfs本地目录"}
        -999    {}
        default { puts "error, $message" }
    }
}

if [catch {Confinit} message] {
    Error $message
} elseif [catch {Main $argc $ARGVS} message] {
    Error $message
}
'

[[ $UID != 0 ]] && SUDO=sudo

$SUDO mv $NAME_N $PATH_I

