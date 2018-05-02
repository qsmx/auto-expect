set VerboaseFlag false

# print command
set TryRun false
set FileToRead "-"

proc usage {} {
    global argv0
    puts stderr "Usage: [file tail $argv0] \[options] \[subcmd] svr"
    puts stderr "  subcmd:"
    puts stderr "    ssh <svr>      auto ssh login to domain"
    puts stderr "                   default, ignore ssh"
    puts stderr ""
    puts stderr "    list <svr>     show servers"
    puts stderr ""
    puts stderr "    scp <svr>:src-path/file \[dest-path]"
    puts stderr "                   dest-path default ."
    puts stderr "    scp local-path/file <svr>\[:dest-path]"
    puts stderr "                   dest-path default \$HOME"
    puts stderr ""
    puts stderr "    sshfs <svr:dest-path> \[local-path]"
    puts stderr "                   run \"unmount local-path\" to remove"
    puts stderr ""
    puts stderr "  options:"
    puts stderr "    -t             try run, only print command"
    puts stderr "    -h             show this message"

    exit 0
}

set ARGVS ""
foreach arg $argv {
    switch -glob -- $arg {
        -v  { set VerboaseFlag true }
        -t  { set TryRun true }
        -h  { usage }
        -*  { usage }
        default {set ARGVS "$ARGVS $arg"}
    }
}

if {$ARGVS == ""} { usage }
