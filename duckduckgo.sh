#!/bin/bash

# Note: This is only a beta version
# Date: 2021/09/19
# 0x0d1n

if [ $# -eq 0 ]; then
        echo "usage: ${0##*/} [query]" >&2
        exit 2
fi

red=`tput setaf 1`
reset=`tput sgr0`
UA='Mozilla/5.0 (Windows NT 10.0; rv:81.0) Gecko/20100101 Firefox/81.0'
PER_PAGE=50
START_PAGE=0
declare -n page=START_PAGE      # like pointer

function urlencode {
  local length="${#1}"
  for (( i = 0; i < length; i++ )); do
    local c="${1:i:1}"
    case $c in
      [a-zA-Z0-9.~_-]) printf "$c" ;;
    *) printf "$c" | xxd -p -c1 | while read x;do printf "%%%s" "$x";done
  esac
done
}

function search {
        echo "Searching for \"$1\"..." > /dev/tty
        for i in {1..5}; do
                html=$(pc curl -A "$UA" -s 'https://duckduckgo.com/?q='$(urlencode "$1")'&t=hx&va=g')
                [ ${#html} -gt 0 ] && break || return 1
        done

        link=$(sed 's/;/\n/g' <<< "$html" | grep 'initialize' | sed "s/')//g" | sed 's/.*\//https:\/\/links.duckduckgo.com\//g')
        link=$(sed -r 's/&s=[0-9]{1,}&/\&s='$page'\&/g' <<< "$link")
        for i in {1..5};do
                data=$(pc curl -A "$UA" -s "$link")
                [ ${#data} -gt 0 ] && { echo "$data"; break; } || return 1
        done
}


function format {
        c=1
        sed 's/,/\n/g' <<< "$1" | grep '"t":\|"u"' | awk -F'":"' '{print $2}' | sed 's/"//g' \
                | sed 's/}//g'  | perl -MHTML::Entities -pe 'decode_entities($_);' \
                | while read -r line; do
                        printf '%b\n' "$line"
                        if [[ $c -ge 2 ]]; then
                                echo; c=0
                        fi
                        let c++
                done
}

kw="$@"
format "$(search "$kw")"

while true; do
        read -n 1 -p "${red}Show More?[Y/n]: ${reset}" show_more
        echo
        case $show_more in
                y)
                        let START_PAGE+=$PER_PAGE
                        format "$(search "$kw")"
                ;;
                *)
                        break
                ;;
        esac
done

exit 0
