#!/bin/bash
:<<DOC
Convert a file in the following format to Ansible YAML:
# List of hosts, tagged by group
macmini2:servers
raspberrypi:servers
dmaf5:desktops
mac-pro-1-1:desktops
DOC
SCRIPT="$(/usr/bin/basename "$0")"|| exit 100
function help {
    /usr/bin/cat<<EOF
Example:
$SCRIPT $HOME/inventory_file.csv servers desktops
EOF
}

# We could use a complicated if-then-else or a case ... esac to handle the tag description logic
# with an Associate Array is very simple
declare -A var_by_tag
var_by_tag["desktops"]="Desktops for the Nunez family"
var_by_tag["servers"]="Linux servers for the Nunez family"

function extract_hosts {
    tag=$1
    host_file=$2
    /usr/bin/grep -P ":$tag$" "$host_file"| /usr/bin/cut -f1 -d':'
    test $? -eq 0 && return 0|| return 1
}
# Consume the host file
hosts_file=$1
shift 1
if [ -z "$hosts_file" ]; then
    echo "ERROR: Missing host file!"
    help
    exit 100
fi

if [ ! -f "$hosts_file" ]; then
    echo "ERROR: Cannot use provided host file: $hosts_file"
    help
    exit 100
fi
# Consume the tags
if [ -z "$*" ]; then
    echo "ERROR: You need to provide one or more tags for the script to work!"
    help
    exit 100
fi
: <<DOC
Generate the YAML
----------------------
The most anoying part is to make sure indentation is correct. YAML depends entirely on that.
The idea is to iterate through the tags and perform the proper actions based on that.
DOC
for tag in "$@"; do  # Quick check for tag description handling. Show the user available tags if that happens
    if [ -z "${var_by_tag[$tag]}" ]; then
        echo "ERROR: I don't know how to handle tag=$tag (known tags=${!var_by_tag[*]}). Fix the script!"
        exit 100
    fi
done
/usr/bin/cat<<YAML
---
all:
  children:
YAML
# I do want to split by spaces to initialize my array, this is OK:
# shellcheck disable=SC2207
for tag in "$@"; do
    /usr/bin/cat<<YAML
    $tag:
      hosts:
YAML
    declare -a hosts=($(extract_hosts "$tag" "$hosts_file"))|| exit 100
    host_cnt=0  # Declare your counter
    for host in "${hosts[@]}"; do
        /usr/bin/cat<<YAML
        $host:
YAML
        ((host_cnt+=1))  # This is how you increment a counter
    done
    if [ "$host_cnt" -lt 1 ]; then
        echo "ERROR: Could not find a single host with tag=$tag"
        exit 100
    fi
    /usr/bin/cat<<YAML
      vars:
        description: ${var_by_tag[$tag]}
YAML
done
