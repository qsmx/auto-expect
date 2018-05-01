proc Cmd_ssh {svr {cmd ""}} {
  set server [Conf_Remote $svr]

  if {$server != "" } {
    set gateway [Conf_Gateway [lindex $server 0]]
    set ssh_cmd "ssh -tt [lindex $server 1][lindex $server 0]"
    set passwords "[lindex $server 2]"

    if {$gateway != ""} {
      set ssh_cmd "ssh -tt [lindex $gateway 1][lindex $gateway 0] $ssh_cmd"
      set passwords "[lindex $gateway 2] $passwords"
    }

    command_low_spawn $ssh_cmd $passwords
  }
}

proc Cmd_search {svr} {
  Conf_Search $svr
}

proc Cmd_scp {svr src {dest "."}} {
puts "developing..."
}

proc command_spawn {cmd {password ""}} {
  command_low_spawn $cmd $password
}

proc command_low_spawn {cmd {password ""} {command ""}} {
  eval spawn $cmd
  foreach pwd $password {
    expect {
      "yes/no"        { send "yes\r"; set timeout 1; exp_continue }
      "assword:"      { send "$pwd\r" }
      "*$*"           { break }
    }
  }

  if {$command != ""} {
    expect "*$*" { send "$command\r" }
  }

  interact
}
