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
