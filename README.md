# Bash here documents and applications

Some times we will need to generate multi-line documents from inside
our Bash scripts. And they may have complex nested structures like a YAML or HTML document. It is possible to create documents from bash by using some special features.

By the end of this article you will have learned the following:
* Use arrays, dictionaries and counters
* Work with different types of comments
* Generate YAML and HTML documents
* Send emails with text and attachments


## Quick introduction to arrays, dictionaries and counters

TODO 

## Documenting a script

Not much to say here. You can have single line comments with a '#' or you
can have multiline comments with the usage of ":" and the  '<<ANYTAG'
combination:

```shell=
# This is a simple comment
: <<COMMENT

This is a multiline comment
Very usefull for some complex comments

COMMENT
```

Another useful example: A [help fuction for your script](https://github.com/josevnz/BashHere/blob/main/help.sh):

```shell=
Also to show the contents
```shell=
#!/bin/bash
SCRIPT=$(/usr/bin/basename $0)|| exit 100
export SCRIPT
function help_me {
    /usr/bin/cat<<EOF

$SCRIPT -- A kick ass script that names and oh wait...
------------------------------------------------------
$SCRIPT --arg1 \$VALUE --arg2 \$VALUE2

EOF

help_me
}

# To use the help function just call help
help_me

```

The multiline is pretty useful by itself, specially when documenting complex scripts. However, there is a nice twist to the usage of "here documents" you may have seen before:

```shell=
/usr/bin/cat<<EOF>$HOME/test_doc.txt
Here is a multiline document, that I want to save.
Note how I can use variables inside like HOME=$HOME.

EOF
```

Let's see what got written on the file:

```shell
[josevnz@dmaf5 BashHere]$ /usr/bin/cat $HOME/test_doc.txt
Here is a multiline document, that I want to save.
Note how I can use variables inside like HOME=/home/josevnz.
```

Good, now let's move to something else where we can use what we just learned.

## Using arrays, and dictionarys to generate an Ansible inventory YAML file

For sake of this example say that we have a [CSV file with list of hosts](https://github.com/josevnz/BashHere/blob/main/hosts.txt) each line containing servers or desktops

```csv
# List of hosts, tagged by group
macmini2:servers
raspberrypi:servers
dmaf5:desktops
mac-pro-1-1:desktops
```

And we want to convert them to the following [Ansible](https://docs.ansible.com/) [YAML](https://yaml.org/) inventory [inventory file](https://docs.ansible.com/ansible/latest/user_guide/intro_inventory.html):

```yaml
---
all:
  children:
    servers:
      hosts:
        macmini2:
        raspberrypi:
      vars:
        description: Linux servers for the Nunez family
    desktops:
      hosts:
        dmaf5:
        mac-pro-1-1:
      vars:
        description: Desktops for the Nunez family        
```

Extra constraints:
* Depending of the type of server (desktops or servers) it will have a different variable called 'description'. Using [Arrays and Associative Arrays](https://www.gnu.org/software/bash/manual/html_node/Arrays.html) and counters will allow us to satisfy this requirement
* The script should fail if the user doesn't provide all the correct tags. An incomplete inventory is not acceptable. For that a simple counter will help.

Below is [a script](https://github.com/josevnz/BashHere/blob/main/text_to_yaml_inventory.sh) that will acomplish that:

```bash
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

# We could use a complicated if-then-else or a case ... esac 
# to handle the tag description logic
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
```

So how the [output](https://github.com/josevnz/BashHere/blob/main/hosts.yaml) looks like?
```shell
[josevnz@dmaf5 BashHere]$ ./text_to_yaml_inventory.sh hosts.txt servers desktops
---
all:
  children:
    servers:
      hosts:
        macmini2:
        raspberrypi:
      vars:
        description: Linux servers for the Nunez family
    desktops:
      hosts:
        dmaf5:
        mac-pro-1-1:
      vars:
        description: Desktops for the Nunez family

```

* A better way could be to create a [dynamic inventory and let Ansible-playbook use](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html#intro-dynamic-inventory) it, but to keep the example simple I will not do that here.


## Sending HTML emails, with YAML attachments

Last example, will show you how to pipe a here document to [Mozilla Thunderbird](http://kb.mozillazine.org/Command_line_arguments_-_Thunderbird) (you can do something similar with /usr/bin/mailx) to create a message with an HTML document and attachments:

```bash=
#!/bin/bash
:<<HELP
Please take a look a the following document so you understand the Thunderbird command line below:
http://kb.mozillazine.org/Command_line_arguments_-_Thunderbird
HELP
declare EMAIL
EMAIL=$1
test -n "$EMAIL"|| exit 100
declare ATTACHMENT
test -n "$2"|| exit 100
test -f "$2"|| exit 100
ATTACHMENT="$(/usr/bin/realpath "$2")"|| exit 100
declare DATE
declare TIME
declare USER
declare KERNEL_VERSION
DATE=$(/usr/bin/date '+%Y%m%d')|| exit 100
TIME=$(/usr/bin/date '+%H:%M:%s')|| exit 100
USER=$(/usr/bin/id --real --user --name)|| exit 100
KERNEL_VERSION=$(/usr/bin/uname -a)|| exit 100

/usr/bin/cat<<EMAIL| /usr/bin/thunderbird -compose "to='$EMAIL',subject='Example of here documents with Bash',message='/dev/stdin',attachment='$ATTACHMENT'"
<!DOCTYPE html>
<html>
<head>
<style>
table {
  font-family: arial, sans-serif;
  border-collapse: collapse;
  width: 100%;
}

td, th {
  border: 1px solid #dddddd;
  text-align: left;
  padding: 8px;
}

tr:nth-child(even) {
  background-color: #dddddd;
}
</style>
</head>
<body>
<h2>Hello,</p> <b>This is a public announcement from $USER:</h2>
<table>
  <tr>
    <th>Date</th>
    <th>Time</th>
    <th>Kernel version</th>
  </tr>
  <tr>
    <td>$DATE</td>
    <td>$TIME Rovelli</td>
    <td>$KERNEL_VERSION</td>
  </tr>
</table>
</body>
</html>
EMAIL
```

Then you call the [mailer script](https://github.com/josevnz/BashHere/blob/main/html_mail.sh) it like this

```shell=
[josevnz@dmaf5 BashHere]$ ./html_mail.sh cooldevops@kodegeek.com hosts.yaml
```

And if things go as expected, Thunderibird will create an email as follows:

![Here document example usage with Thunderbird](https://github.com/josevnz/BashHere/raw/main/heredocument-thunderbird.png)

# Wrapping up

Let's recap what we learned:
* Use more sofisticated data structures like arrays, associative arrays to generate documents
* Use counters to keep track of events
* Use here documents to create YAML documents, help instructions, HTML...
* How to send emails with HTML, YAML

Bash is OK to generate this type of documents but only if their size is small or have little complexity, otherwise you may be better using another scripting language like Python or Perl to get the same results with less effort. Also never underestimate the ability to have a real debugger when dealing with a complex document creation.


