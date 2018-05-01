#!/usr/bin/expect -f

set YD_CONFIG_PATH  "~/.yd"

######
# option
######
set yd_options {
    ssh     {
        "%s     <alias|ip>"
    } \
    sftp    {
        "%s     <alias|ip>"
    } \
    sshfs   {
        "%s     <alias|ip> <remote-path> [local-path]"
    } \
    help    {
        "%s     <cmd>"
        "show this message."
    }
}

######
# command
######
proc YD_cmd_help {args} {
    global yd_options
    array set options $yd_options

    if {$args == ""} {
        foreach name [array names options] {
            puts $name
        }
    } else {
    }
}

proc YD_cmd_ssh {args} {
    if {$args == "" || [llength $args] > 1} {
        error -1
    }

    YD_func_init
    set cmd ""
    set pwd ""
    set server [YD_func_completed_server [lindex $args 0]]
    set command [lindex $server 1]
    set server  [lindex $server 0]
    foreach svr $server {
        set cmd "ssh -t [lindex $svr 0] $cmd"
        set pwd "[lindex $svr 3] $pwd"
    }
    YD_ssh_expect $cmd $pwd $command
}

proc YD_cmd_sftp {args} {
    # sftp -o "ProxyCommand=ssh $board nc %h 22" $target
    YD_func_init
    set server [YD_func_completed_server [lindex $args 0]]
    set server [lindex $server 0]
    lassign $server target board

    if {$board != ""} {
        set cmd "sftp -o \"ProxyCommand=ssh [lindex $board 0] nc %h %p\" [lindex $target 0]"
        set pwd "[lindex $board 3] [lindex $target 3]"
    } else {
        set cmd "sftp [lindex $target 0]"
        set pwd "[lindex $target 3]"
    }
    YD_ssh_expect $cmd $pwd
}

proc YD_cmd_sshfs {args} {
    # sshfs -o ProxyCommand="ssh $board nc %h %p" $target: ./sshfs-162/
    YD_func_init
    set server [YD_func_completed_server [lindex $args 0]]
    set server [lindex $server 0]
    lassign $server target board

    lassign $args null remote_path local_path
    if {$local_path == ""} {
        set local_path "[YD_func_config sshfs,path]/[lindex $target 1]"
    }
    if [file exists $local_path] {
        if {![file isdirectory $local_path]} {
            error -400
        }
    } else {
        file mkdir $local_path
    }

    if {$board != ""} {
        set cmd "-ignore HUP sshfs -o \"ProxyCommand=ssh [lindex $board 0] nc %h %p\" [lindex $target 0]:$remote_path $local_path"
        set pwd "[lindex $board 3] [lindex $target 3]"
    } else {
        set cmd "-ignore HUP sshfs [lindex $target 0]:$remote_path $local_path"
        set pwd "[lindex $target 3]"
    }
    YD_ssh_expect $cmd $pwd
}

# umount sshfs
proc YD_cmd_um {args} {
    YD_func_init

    if [catch {glob [YD_func_config sshfs,path]/*} message] {
        puts "没有挂载任何远程目录"
        exit
    }
    foreach d [glob [YD_func_config sshfs,path]/*] {
        file stat $d st
        # 如果文件是mount
        if {$st(nlink) == 1 && $st(blksize) == 65536} {
            puts "umount $d"
            exec sh -c "umount $d"
            file delete $d
        }
    }
}

proc YD_cmd_scp {args} {
    # scp -o ProxyCommand="ssh gaoguodong@gateway.yongche-inc.com nc %h %p" gaoguodong@172.17.0.162:test .
    YD_func_init
    set server [YD_func_completed_server [lindex $args 0]]
    set server [lindex $server 0]
    set target [lindex $server 0]
    set board  [lindex $server 1]

    set remote_path         [lindex $args 1]
    set local_path          [lindex $args 2]
    if {$local_path == ""} {
        set local_path "[YD_func_config scp,path]/[lindex $target 1]"
    }
    if [file exists $local_path] {
        if {![file isdirectory $local_path]} {
            error -500
        }
    } else {
        file mkdir $local_path
    }

    if {$board != ""} {
        set cmd "-ignore HUP scp -r -o \"ProxyCommand=ssh [lindex $board 0] nc %h %p\" [lindex $target 0]:$remote_path $local_path"
        set pwd "[lindex $board 3] [lindex $target 3]"
    } else {
        set cmd "-ignore HUP scp -r [lindex $target 0]:$remote_path $local_path"
        set pwd "[lindex $target 3]"
    }
    YD_ssh_expect $cmd $pwd
}

proc YD_cmd_lscp {args} {
    # scp -o ProxyCommand="ssh gaoguodong@gateway.yongche-inc.com nc %h %p" {xx} gaoguodong@172.17.0.162:test
    if {[llength $args] < 2} {error -300 }

    YD_func_init
    set server [YD_func_completed_server [lindex $args 0]]
    set server [lindex $server 0]
    lassign $server target board

    set local_path [lreplace $args 0 0]
    puts $local_path
    if {[llength $local_path] > 1} {
        set remote_path [lindex $args end]
        set local_path [lreplace $local_path end end]
    } else {
        set remote_path ""
    }

    foreach lf $local_path {
        if {![file exists $lf]} {
            error -301
        }
    }

    if {$board != ""} {
        set cmd "-ignore HUP scp -r -o \"ProxyCommand=ssh [lindex $board 0] nc %h %p\" $local_path [lindex $target 0]:$remote_path"
        set pwd "[lindex $board 3] [lindex $target 3]"
    } else {
        set cmd "-ignore HUP scp -r $local_path [lindex $target 0]:$remote_path"
        set pwd "[lindex $target 3]"
    }

    YD_ssh_expect $cmd $pwd
}

# 远程命令
proc YD_ssh_expect {spawn_cmd {passwd ""} {command ""} args} {
    eval spawn $spawn_cmd

    foreach pwd $passwd {
        expect {
            "yes/no"        { send "yes\r"; set timeout 1; exp_continue }
            "assword:"      { send "$pwd\r" }
            "*$*"           { break }
        }
    }

    if {[lindex $spawn_cmd 0] == "ssh"} {
        if {$command != ""} {
            expect "*$*" { send "$command\r" }
        }
    }

    interact
}

# 补全 server 数据
proc YD_func_completed_server {server} {
    set server [YD_func_searched_server $server]

    global YD_TAG_NAME
    set command [YD_func_config_command [lindex $server 0] [lindex $server 1] $YD_TAG_NAME]

    set completed_server "{[YD_func_fill_server $server]}"
    while {[set server [YD_func_searched_board $server]] != ""} {
        set svr [YD_func_fill_server $server]
        # set completed_server [linsert $completed_server 0 $svr]
        lappend completed_server $svr
    }

    return "{$completed_server} {$command}"
}

#
proc YD_func_fill_server {server} {
    set username [lindex $server 2]

    set ip [lindex $server 1]
    if {$ip == ""} { set ip [lindex $server 0] }

    if {$username == ""} {
        global yd_list_config
        global YD_TAG_NAME

        set domain [lindex $server 0]

        set username [YD_func_config_opt username $domain $ip $YD_TAG_NAME]
        set password [YD_func_config_opt password $domain $ip $YD_TAG_NAME]

        set server [lreplace $server 2 3 $username $password]
    }

    if {[lindex $server 2] == ""} {
        set svr_remote "$ip"
    } else {
        set svr_remote "[lindex $server 2]@$ip"
    }

    return [lreplace $server 0 1 $svr_remote $ip]
    # return [linsert $server 0 $svr_remote]
}

# 获取登录命令
proc YD_func_config_command {args} {
    foreach target $args {
        if {$target == ""} { continue }
        set ac [YD_func_config $target,command]
        if {$ac != ""} {
            return $ac
        }
    }

    return ""
}

proc YD_func_config_opt {args} {
    set args [lassign $args opt]

    foreach target $args {
        if {$target == ""} { continue }
        set ac [YD_func_config $target,$opt]
        if {$ac != ""} {
            return $ac
        }
    }

    return ""
}

# 匹配服务器
proc YD_func_searched_server {server} {
    global yd_list_server

    foreach name [array names yd_list_server] {
        if [regexp "$server" $name match] {
            return $yd_list_server($name)
        }
    }

    error -200
}

# 查找跳板机
proc YD_func_searched_board {server} {
    set alias   [lindex $server 0]
    set ip      [lindex $server 1]
    # 通过别名查找跳板机
    set board [YD_func_config $alias,board-machine]
    if {$board == "" && $ip != ""} {
        # 通过IP查找跳板机
        set board [YD_func_config $ip,board-machine]
    }

    if {$board != ""} {
        set board [YD_func_board $board]
        if {$board == "close"} {
            return ""
        } else {
            return $board
        }
    }

    return [YD_func_get_board_catched $alias $ip]
}

proc YD_func_get_board_catched {args} {
    #set args [subst $args]
    global yd_list_config
    global YD_TAG_BOARD
    global YD_TAG_BOARD_CATCHED

    # 获取所有自定义模式
    array set catched [array get yd_list_config $YD_TAG_BOARD_CATCHED,*]
    foreach name [array names catched] {
        regexp "$YD_TAG_BOARD_CATCHED,(.*)" $name match sname
        foreach arg $args {
            if {$arg == ""} { continue }
            if [regexp "^x*$sname.*$" $arg] {
                set board [YD_func_board $catched($name)]
                if {$board == "close"} {
                    return ""
                } else {
                    return $board
                }
            }
        }
    }

    array set custom_board [array get yd_list_config $YD_TAG_BOARD,*-pattern]
    foreach name [array names custom_board] {
        regexp "$YD_TAG_BOARD,(.*)-pattern" $name match sname
        foreach arg $args {
            if {$arg == ""} { continue }
            if [regexp "^x*$custom_board($name).*$" $arg] {
                set board [YD_func_board $sname]
                if {$board == "close"} {
                    return ""
                } else {
                    return $board
                }
            }
        }    }

    return ""
}

# 获取配置
proc YD_func_config {name} {
    global yd_list_config
    set config [array get yd_list_config "$name"]
    if {$config != ""} {
        return [lindex $config 1]
    }
    return ""
}

# 跳板机状态
proc YD_func_board {name} {
    global YD_TAG_BOARD
    set status [YD_func_config $YD_TAG_BOARD,${name}-status]
    if {$status == "close" || $status == "redirect"} {
        return $status
    }

    set domain [YD_func_config $YD_TAG_BOARD,$name]
    if {$domain == ""} {
        return "close"
    }

    set user [YD_func_config $YD_TAG_BOARD,${name}-user]
    set passwd [YD_func_config $YD_TAG_BOARD,${name}-passwd]

    global YD_TAG_NAME
    if {$user == ""} {
        set user [YD_func_config_opt username $domain $YD_TAG_NAME]
    }

    if {$passwd == ""} {
        set passwd [YD_func_config_opt password $domain $YD_TAG_NAME]
    }

    return "$domain \"\" \"$user\" \"$passwd\""
}

# 初始化
proc YD_func_init {} {
    global YD_CONFIG_NAME
    global YD_CONFIG_SERV

    YD_func_read $YD_CONFIG_NAME YD_func_init_config
    YD_func_read $YD_CONFIG_SERV YD_func_init_server
}

# 初始化配置信息
proc YD_func_init_config {line} {
    global yd_tag_name
    if [regexp {\[([^\]]+)\]} $line match tag_name] {
        set yd_tag_name [string trim $tag_name]
        if {$yd_tag_name == ""} {
            global YD_TAG_NAME
            set yd_tag_name $YD_TAG_NAME
        } else {
            regsub -all " +" $yd_tag_name "-" yd_tag_name
        }
    } else {
        if [regexp {^\s*([^=]+)\s*=?\s*(.*?)\s*$} $line match name value] {
            global yd_list_config
            regsub -all {[ :]+} [string trim $name] "-" name
            array set yd_list_config [list "$yd_tag_name,$name" "$value"]
        }
    }
}

# 初始化服务器信息
proc YD_func_init_server {line} {
    global yd_list_server
    set pat {^\s*(\S+)(?:\s+(\S+|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))*?(?:\s+(\S+?)\s+(\S+))?\s*$}
    if [regexp $pat $line match alias server user passwd] {
        set key "$alias|$server"
        # if {$server == ""} { set server $alias }
        set info "$alias \"$server\" \"$user\" \"$passwd\""
        array set yd_list_server [list "$key" "$info"]
    }
}

# 读取文件，回调
proc YD_func_read {filename callback args} {
    if [catch {open $filename "r"} fd] { error -100 }
    while {! [eof $fd]} {
        if {![gets $fd line] || [regexp {^\s*[\#;]} $line]} { continue }
        # if [eof $fd] { break }
        if {[eval $callback \$line $args] == -1} { break }
    }
    close $fd
}

# 全局配置类
set YD_CONFIG_NAME          "$YD_CONFIG_PATH/config"
set YD_CONFIG_SERV          "$YD_CONFIG_PATH/server"

set YD_TAG_BOARD            "board-machine"
set YD_TAG_BOARD_CATCHED    "board-catched"
set YD_TAG_NAME             "server"

set yd_tag_name             "$YD_TAG_NAME"
array set yd_list_server    []
array set yd_list_config    []

######
# main
######
proc YD_main {argc argv} {
    if {$argc == 0} { error -1 }

    set cmd "YD_cmd_[lindex $argv 0]"
    if {[info procs $cmd] != $cmd} {
        eval YD_cmd_ssh $argv
    } else {
        eval $cmd [lreplace $argv 0 0]
    }

}

if [catch {YD_main $argc $argv} message] {
    switch $message {
        -1 { puts "1" }
        -100    { puts "读取文件失败."}
        -200    { puts "找不到指定的服务器"}
        -300    { puts "lscp 必须指定至少一个本地文件或目录"}
        -301    { puts "不存在本地文件"}
        -400    { puts "sshfs 非目录"}
        -500    { puts "scp 非目录"}
        default { puts "error, $errorInfo" }
    }

    #   puts $errorInfo
}

# parray yd_list_config
# parray yd_list_server
