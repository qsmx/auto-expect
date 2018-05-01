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
set Category_Current $CONF_CATGORY_DEFAULT

# loaded setting
array set setting_from_conf []
# gatway index
set conf_gateway_index 0

# loaded server
array set server_from_conf []
# hit server
array set server_hits []

# get file body
proc Conf_read {filename callback} {
  if [catch {open $filename "r"} fd] { error -100 }
  while {! [eof $fd]} {
    if {![gets $fd line] || [regexp {^\s*[\#;]} $line]} { continue }
    if {[eval $callback \$line] == -1} { break }
  }
  close $fd
}

# get server_hits
proc Conf_Hit {domain} {
  global server_hits
  global server_from_conf
  set index 1
  foreach name [array names server_from_conf] {
    if [regexp "$domain" $name match] {
      set server_hits($index) $name
      incr index
    }
  }

  if {[array size server_hits] == 0} {
    puts " ** DO NOT FOUND SERVER MATCH '$domain'"
    error -200
  }
}

proc Conf_Search {domain} {
  Conf_Hit $domain

  global server_hits
  global server_from_conf

  set size [array size server_hits]

  puts stderr " @@ MATCHED"
  set idx 1
  while {$idx <= $size} {
    puts "  * \[$idx] - $server_hits($idx)"
    incr idx
  }
}

proc Conf_Remote {domain} {
  Conf_Hit $domain
  global server_hits
  global server_from_conf

  set size [array size server_hits]
  if {$size == 1} {
    return $server_from_conf($server_hits(1))
  }

  puts stderr " @@ MORE SERVER MATCHED"
  set idx 1
  while {$idx <= $size} {
    puts "  * \[$idx] - $server_hits($idx)"
    incr idx
  }

  return [Conf_Choose server_hits]
}

proc Conf_Choose {servers} {
  upvar $servers server_hits
  set size [array size server_hits]
  global server_from_conf

  set c "x"
  set count 1
  puts -nonewline stderr " -- INPUT ID TO SEARCH ONE \[q]: "
  flush stderr
  while {$c != "q"} {
    set c [gets stdin]
    if {$c == "q"} {
      error -999
    } elseif {$c > 0 && $c <= $size} {
      return $server_from_conf($server_hits($c))
    }

    puts -nonewline stderr " -- INPUT ID TO SEARCH ONE \[q]: "
    flush stderr
  }
}

proc Conf_Gateway {domain {ip ""}} {
    global CONF_CATGORY_GATEWAY
  set gateway [Conf_Gets gateway $domain $ip]

  if {$gateway != ""} {
    global setting_from_conf
    array set gateways [array get setting_from_conf $CONF_CATGORY_GATEWAY,*,name]
    foreach name [array names gateways] {
      if {$gateway == $gateways($name)} {
        regexp "$CONF_CATGORY_GATEWAY,(.*),name" $name match index
        return [Conf_Gateway_info $index]
      }
    }
  }

  if {$gateway != ""} {
    set gateway [Conf_Get $CONF_CATGORY_GATEWAY gateway]
  }

  # search
  # [gateway]
  #   pattern = ...
  return [Conf_Gateway_List $domain $ip]
}

proc Conf_Gateway_List {args} {
  global CONF_CATGORY_GATEWAY
  global setting_from_conf
  array set gateways [array get setting_from_conf $CONF_CATGORY_GATEWAY,*,pattern]
  foreach name [array names gateways] {
    regexp "$CONF_CATGORY_GATEWAY,(.*),pattern" $name match index
    set status [Conf_Get $CONF_CATGORY_GATEWAY,$index status]
    if {$status == "close"} { continue }

    set remote [Conf_Get $CONF_CATGORY_GATEWAY,$index remote]
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
  set remote [Conf_Get $CONF_CATGORY_GATEWAY,$index remote]
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
        set val [Conf_Get $arg $fieldName]
        if {$val != ""} {
          return $val
        }
      }
    }
  }

  return ""
}

proc Conf_Get {category fieldName} {
  global setting_from_conf
  set value [array get setting_from_conf "$category,$fieldName"]

  if {$value != ""} {
    return [lindex $value 1]
  }

  return ""
}

proc Conf_init {} {
  global CONF_USERNAME
  global CONF_PASSWORD
  global CONF_CATGORY_DEFAULT
  global CONF_SETTING
  global CONF_SERVER

  Conf_read $CONF_SETTING Conf_Settting_Init
  set CONF_USERNAME [Conf_Get $CONF_CATGORY_DEFAULT username]
  set CONF_PASSWORD [Conf_Get $CONF_CATGORY_DEFAULT password]

  Conf_read $CONF_SERVER Conf_Server_Init
}

proc Conf_Settting_Init {line} {
  global Category_Current

  # get [...]
  if [regexp {\[([^\]]*)\]} $line match Category_Current] {
    set Category_Current [string trim $Category_Current]
    if {$Category_Current == ""} {
      global CONF_CATGORY_DEFAULT
      set Category_Current $CONF_CATGORY_DEFAULT
    } else {
      regsub -all " +" $Category_Current "-" Category_Current
    }
  } elseif [regexp {^([^=]+)=?\s*(.*?)\s*$} $line match name value] {
    # name = value
    global setting_from_conf
    regsub -all {[ :]+} [string trim $name] "-" name
    global CONF_CATGORY_GATEWAY
    if {$Category_Current == $CONF_CATGORY_GATEWAY} {
      global conf_gateway_index
      set Category_Current $Category_Current,$conf_gateway_index
      incr conf_gateway_index
    }

    set setting_from_conf($Category_Current,$name) $value
  }
}

proc Conf_Server_Init {line} {
  global server_from_conf
  set pat {^\s*(\S+)(?:\s+(\S+|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}))*?$}
  if [regexp $pat $line match alias server] {
    if {$server == ""} {
      set server $alias
      set key "$server"
      set alias ""
    } else {
      set key "$alias|$server"
    }

    set username [eval Conf_Gets username $alias $server]
    if {$username == ""} {
      global CONF_USERNAME
      set username $CONF_USERNAME
      if {$username != ""} {
        set username "$username@"
      }
    }

    set password [Conf_Gets password $alias $server]
    if {$password == ""} {
      global CONF_PASSWORD
      set password $CONF_PASSWORD
    }

    set info "{$server} {$username} {$password}"
    set server_from_conf($key) $info
  }
}
