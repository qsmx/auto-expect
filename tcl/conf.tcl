# config file
set CONF_SETTING "$RC_PATH/setting"
# server info
set CONF_SERVER  "$RC_PATH/server"

# default category
set CONF_CATGORY_DEFAULT "server"
# default username
set CONF_USERNAME ""
# default password
set CONF_PASSWORD ""
# gateway category
set CONF_CATGORY_GATEWAY "gateway"
# current category
set CATEGORY_CURRENT $CONF_CATGORY_DEFAULT

# loaded setting
array set SETTING_FROM_CONF []
# gatway index
set CONF_GATEWAY_INDEX 0

# loaded server
array set SERVER_FROM_CONF []
# hit server
array set SERVER_HITS []

# interact
set CONF_INTERACT false

proc ConfInit {} {
  global CONF_USERNAME
  global CONF_PASSWORD
  global CONF_CATGORY_DEFAULT
  global CONF_SETTING
  global CONF_SERVER
  global ETC_PATH

  if {$ETC_PATH != ""} {
    if {[file exists $ETC_PATH/setting]} {
      ConfRead $ETC_PATH/setting Conf_Settting_Init
    }

    if {[file exists $ETC_PATH/server]} {
      ConfRead $ETC_PATH/server  Conf_Server_Init
    }
  }

  if {[file exists $CONF_SETTING]} {
    ConfRead $CONF_SETTING Conf_Settting_Init
  }

  set CONF_USERNAME [Conf_Get username $CONF_CATGORY_DEFAULT]
  set CONF_PASSWORD [Conf_Get password $CONF_CATGORY_DEFAULT]

  # global env
  # # hidden if username is LOGNAME
  # if {$CONF_USERNAME == $env(LOGNAME)} {
  #   set CONF_USERNAME ""
  # }

  if {[file exists $CONF_SERVER]} {
    ConfRead $CONF_SERVER Conf_Server_Init
  }
}

# get file body
proc ConfRead {filename callback} {
  if [catch {open $filename "r"} fd] { error -100 }
  while {! [eof $fd]} {
    if {![gets $fd line] || [regexp {^\s*[\#;]} $line]} { continue }
    if {[eval $callback \$line] == -1} { break }
  }
  close $fd
}

# get SERVER_HITS
proc ConfHit {domain} {
  global SERVER_HITS
  global SERVER_FROM_CONF
  set index 1
  foreach name [array names SERVER_FROM_CONF] {
    if [regexp "$domain" $name match] {
      set SERVER_HITS($index) $name
      incr index
    }
  }

  if {[array size SERVER_HITS] == 0} {
    puts stderr " ** DO NOT FOUND SERVER MATCH '$domain'"
    error -200
  }
}

proc ConfPrint {lists} {
  upvar $lists SERVER_HITS
  set size [array size SERVER_HITS]

  set idx 1
  while {$idx <= $size} {
    puts stderr "  * \[$idx] - $SERVER_HITS($idx)"
    incr idx
  }

  flush stderr
}

proc ConfList {domain} {
  ConfHit $domain

  global SERVER_HITS
  puts stderr " @@ MATCHED"
  ConfPrint SERVER_HITS
}

proc ConfRemote {domain} {
  global SERVER_HITS
  global SERVER_FROM_CONF

  ConfHit $domain

  set size [array size SERVER_HITS]
  if {$size == 1} {
    return $SERVER_FROM_CONF($SERVER_HITS(1))
  }

  puts stderr " @@ MORE SERVER MATCHED"
  ConfPrint SERVER_HITS

  return [ConfChoose SERVER_HITS]
}

# get auto command
proc ConfAutoCommand {args} {
  global CONF_INTERACT
  global CONF_CATGORY_DEFAULT

  set interact [eval Conf_Gets interact $args $CONF_CATGORY_DEFAULT]
  if {$interact == "true"} {set CONF_INTERACT true}

  set command [eval Conf_Gets command $args]
  if {$command != ""} {return $command }

  global SETTING_FROM_CONF
  set command_default ""

  array set commands [array get SETTING_FROM_CONF *,command]
  foreach name [array names commands] {
    regexp "(.*).command" $name match category
    foreach arg $args {
      if {[regexp $category $arg]} {
        set interact [Conf_Get interact $category]
        if {$interact == "true"} {set CONF_INTERACT true}
        return $commands($name)
      }
    }
  }

  return [eval Conf_Get command $CONF_CATGORY_DEFAULT]
}

proc ConfGateway {server} {
  global CONF_CATGORY_GATEWAY
  lassign $server ip null null domain
  set gateway [Conf_Gets gateway $domain $ip]

  if {$gateway != ""} {
    global SETTING_FROM_CONF
    array set gateways [array get SETTING_FROM_CONF $CONF_CATGORY_GATEWAY,*,name]
    foreach name [array names gateways] {
      if {$gateway == $gateways($name)} {
        regexp "$CONF_CATGORY_GATEWAY,(.*),name" $name match index
        return [Conf_Gateway_info $index]
      }
    }
  }

  if {$gateway != ""} {
    set gateway [Conf_Get gateway $CONF_CATGORY_GATEWAY]
  }

  # search
  # [gateway]
  #   pattern = ...
  return [Conf_Gateway_List $domain $ip]
}

proc ConfChoose {servers} {
  upvar $servers SERVER_HITS
  set size [array size SERVER_HITS]
  global SERVER_FROM_CONF

  set c "x"
  set count 1
  puts -nonewline stderr " -- INPUT ID TO SEARCH ONE \[q]: "
  flush stderr
  while {$c != "q"} {
    set c [gets stdin]
    if {$c == "q"} {
      error -999
    } elseif {$c > 0 && $c <= $size} {
      return $SERVER_FROM_CONF($SERVER_HITS($c))
    }

    puts -nonewline stderr " -- INPUT ID TO SEARCH ONE \[q]: "
    flush stderr
  }
}

proc Conf_Gateway_List {args} {
  global CONF_CATGORY_GATEWAY
  global SETTING_FROM_CONF
  array set gateways [array get SETTING_FROM_CONF $CONF_CATGORY_GATEWAY,*,pattern]
  foreach name [array names gateways] {
    regexp "$CONF_CATGORY_GATEWAY,(.*),pattern" $name match index
    set status [Conf_Get status $CONF_CATGORY_GATEWAY,$index]
    if {$status == "close"} { continue }

    set remote [Conf_Get remote $CONF_CATGORY_GATEWAY,$index]
    if {$remote == ""} { continue }

    foreach arg $args {
      if {$arg == ""} { continue }
      if [regexp "^.*$gateways($name).*$" $arg] {
        return [Conf_Gateway_info $index]
      }
    }
  }

  return ""
}

proc Conf_Gateway_info {index} {
  global CONF_CATGORY_GATEWAY
  global CONF_CATGORY_DEFAULT
  set remote [Conf_Get remote $CONF_CATGORY_GATEWAY,$index]
  set username [Conf_Gets username $CONF_CATGORY_GATEWAY,$index $CONF_CATGORY_DEFAULT]
  set password [Conf_Gets password $CONF_CATGORY_GATEWAY,$index $CONF_CATGORY_DEFAULT]

  if {$username != ""} {
    set username "$username@"
  }

  return "{$remote} {$username} {$password}"
}

proc Conf_Gets {fieldName args} {
  if {$args != ""} {
    foreach arg $args {
      if {$arg != ""} {
        set val [Conf_Get $fieldName $arg]
        if {$val != ""} {
          return $val
        }
      }
    }
  }

  return ""
}

proc Conf_Get {fieldName category} {
  global SETTING_FROM_CONF
  set value [array get SETTING_FROM_CONF "$category,$fieldName"]

  if {$value != ""} {
    return [lindex $value 1]
  }

  return ""
}

proc Conf_Settting_Init {line} {
  global CATEGORY_CURRENT

  # get [...]
  if {[regexp {\[([^\]]*)\]} $line match CATEGORY_CURRENT]} {
    set CATEGORY_CURRENT [string trim $CATEGORY_CURRENT]
    if {$CATEGORY_CURRENT == ""} {
      global CONF_CATGORY_DEFAULT
      set CATEGORY_CURRENT $CONF_CATGORY_DEFAULT
    } else {
      regsub -all " +" $CATEGORY_CURRENT "-" CATEGORY_CURRENT
    }
  } elseif [regexp {^([^=]+)=?\s*(.*?)\s*$} $line match name value] {
    # name = value
    global SETTING_FROM_CONF
    regsub -all {[ :]+} [string trim $name] "-" name
    global CONF_CATGORY_GATEWAY
    if {$CATEGORY_CURRENT == $CONF_CATGORY_GATEWAY} {
      global CONF_GATEWAY_INDEX
      set CATEGORY_CURRENT $CATEGORY_CURRENT,$CONF_GATEWAY_INDEX
      incr CONF_GATEWAY_INDEX
    }

    set SETTING_FROM_CONF($CATEGORY_CURRENT,$name) $value
  }
}

proc Conf_Server_Init {line} {
  global SERVER_FROM_CONF
  set pat {^\s*(\S+)(?:\s+(\S+|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))*?$}
  if {[regexp $pat $line match server alias]} {
    if {$alias == ""} {
      set alias server
      set key "$server"
      set alias ""
    } else {
      set key "$alias|$server"
    }

    set username [eval Conf_Gets username $alias $server]
    if {$username == ""} {
      global CONF_USERNAME
      set username $CONF_USERNAME
    }
    if {$username != ""} {
      set username "$username@"
    }

    set password [Conf_Gets password $alias $server]
    if {$password == ""} {
      global CONF_PASSWORD
      set password $CONF_PASSWORD
    }

    set info "{$server} {$username} {$password} {$alias}"
    set SERVER_FROM_CONF($key) $info
  }
}
