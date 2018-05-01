set VerboaseFlag false
set FileToRead "-"

proc usage {} {
    global argv0
    puts stderr "Usage: $argv0 \[subcmd] svr"
    puts stderr "  subcmd:"
    puts stderr "    \[ssh] <svr>    auto ssh login to domain"
    puts stderr "                   default"
    puts stderr "    search <svr>   show servers"
    puts stderr ""
    puts stderr "    scp            ..."

    exit 0
}

foreach arg $argv {
    switch -glob -- $arg {
        -v  { set VerboaseFlag true }
        -h  { usage(); exit 1 }
    }
}