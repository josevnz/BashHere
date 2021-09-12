#!/bin/bash
SCRIPT=$(/usr/bin/basename $0)|| exit 100
export SCRIPT
function help_me {
    /usr/bin/cat<<EOF

$SCRIPT -- A kick ass script that names and oh wait...
------------------------------------------------------
$SCRIPT --arg1 \$VALUE --arg2 $\VALUE2

EOF
}

help_me
