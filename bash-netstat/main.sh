#!/bin/bash
##ss
#Bash params
set -e
set -o errexit
set -o pipefail

# Default values
RED="\e[91m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"
ARGS=("$*")
RED="\e[91m"
GREEN="\e[92m"
ENDCOLOR="\e[0m"
re_num='^[0-9]+$'
re_pname='^[0-9a-zA-Z_]+$'
re_oname='^[a-zA-Z_]+$'
flags_array=("h" "s" "p" "c" "b" "n" "d" "w")
## help info function
# show info about application
helpmessage() {
  echo ""
  echo "Options:"
  echo " -h               help information, you already here"
  echo " -s               silent mode. Removs questions about unset'd\wrong values"
  echo " -p <process>     process_name or process identificator (PID). Default process is 'firefox'."
  echo " -c <number>      number of lines to display. Default value is 5."
  echo " -d               disabling whois option"
  echo " -b <ss|netstat>  switch 'netstat' \  'cc'. Default backend is 'netstat'."
  echo " -w <string>      select desired object from 'whois' output. Default object is 'Organization'."
  echo " -n <l|e|a>       types of connections would you like to see. e -  'ESTABLISHED',l -  'LISTENING', a- 'ALL"
  echo ""
  echo "examples"
  echo ""
  echo -e "sudo ./$(basename "${BASH_SOURCE[0]}") -p chrome -c 5 -b n -n a -w Organization "
  echo -e "sudo ./$(basename "${BASH_SOURCE[0]}") -p chrome -s "
  echo -e "sudo ./$(basename "${BASH_SOURCE[0]}") -p chrome "
  echo -e "sudo ./$(basename "${BASH_SOURCE[0]}") -p firefox -c 5 -b n -n a -w Organization "
  echo -e "sudo ./$(basename "${BASH_SOURCE[0]}") -p firefox -s "
  echo -e "sudo ./$(basename "${BASH_SOURCE[0]}") -p firefox "
  echo "TNX | P.S> Created by Juri Gogolev"
  exit 0
}
## Checking process option function
# if proces option not set, ask to set new one or setting default value
# depends on silent mode option
process_checker() {
  if [[ $SILENT ]]; then
    echo '[Warning] Proces option not set, setting default value "firefox"'
    PROCESS='firefox'
  else
    while ! [[ $PROCESS =~ $re_num || $PROCESS =~ $re_pname ]]; do
      read -p "[MSG] Enter process name/PID or press [ENTER] for default value 'firefox': " PROCESS
      if ! [ "$PROCESS" ]; then
        PROCESS='firefox'
      elif ! [[ $PROCESS =~ $re_num || $PROCESS =~ $re_pname ]]; then
        echo "[Warning] Cant set Process as '$PROCESS', must be diggit or name"
      fi
    done
    echo "[INFO] Process name\PID setted to $PROCESS"
  fi
}
## Checking count option function
# if count option not set, ask to set new one or setting default value
# depends on silent mode option
count_checker() {
  if [[ $SILENT ]]; then
    echo '[Warning] Count option not set, setting default value "5"'
    LIMIT=5
  else
    while ! [[ $LIMIT =~ $re_num || $LIMIT == 'all' ]]; do
      read -p "[MSG] Enter limit count or type \"all\" for disabling limit or press [ENTER] for default value '5': " LIMIT
      if ! [ "$LIMIT" ]; then
        LIMIT='5'
      elif ! [[ $LIMIT =~ $re_num || $LIMIT == 'all' ]]; then
        echo "[Warning] Cant set limit count as '$LIMIT', must be diggit or all"
      fi
    done
    echo "[INFO] LIMIT setted to $LIMIT"
  fi
}
## Checking conntection type function
#if conntection type option not set, ask to set new one or setting default value
# depends on silent mode option
connecttype_checker() {
  if [[ $SILENT ]]; then
    echo '[Warning] State connection type option not set, setting default value "ESTABLISHED"'
    CONTYPE='ESTABLISHED'
  else
    while ! [[ $CONTYPE == 'LISTEN' || $CONTYPE == 'ESTAB' || $CONTYPE == 'ESTAB\|LISTEN' ]]; do
      #      read -p "[MSG] Enter State connection type :\n " CONTYPESHORT
      read -rep $'[MSG] Enter State connection type\n l - for LISTENING , e - for ESTABLISHED, a - for ALL  [ENTER] for default value \'all\': ' CONTYPESHORT
      if ! [ "$CONTYPESHORT" ]; then
        CONTYPE='ESTAB'
      elif ! [[ $CONTYPESHORT == 'l' || $CONTYPESHORT == 'e' || $CONTYPESHORT == 'a' ]]; then
        echo "[Warning] Unknown answer '$CONTYPESHORT', must be 'a' or 'e' or 'l' or emty"
      elif [[ $CONTYPESHORT == 'l' ]]; then
        CONTYPE='LISTEN'
      elif [[ $CONTYPESHORT == 'e' ]]; then
        CONTYPE='ESTAB'
      elif [[ $CONTYPESHORT == 'a' ]]; then
        CONTYPE='ESTAB'
        CONTYPE2='LISTEN'
      fi
    done
    echo "[INFO] State connection type setted to $CONTYPE"
  fi
}
## Checking utility type function
#if utility type option not set, ask to set new one or setting default value
# depends on silent mode option and on allowed utility's
utility_checker() {
  if [[ $UTILNETSTAT ]]; then
    DEFUTIL='netstat'
  else
    DEFUTIL='ss'
  fi
  if [[ $SILENT ]]; then
    echo "[Warning] Utility option not set, setting default value '$DEFUTIL'"
    USEDUTIL=$DEFUTIL
  else
    if [[ $UTILNETSTAT == 1 && $UTILSS == 1 ]]; then
      MSGUSS='s - for ss utility, n - for netstat utility'
    elif [[ $UTILNETSTAT == 1 ]]; then
      MSGUSS='n - for netstat utility'
    else
      MSGUSS='s - for ss utility'
    fi
    while ! [[ $USEDUTIL == 'netstat' || $USEDUTIL == 'ss' ]]; do
      #      read -p "[MSG] Enter State connection type :\n " CONTYPESHORT
      read -rep $"[MSG] Enter Utility type\n $MSGUSS  [ENTER] for default value '$DEFUTIL': " USEDUTIL
      if ! [ "$USEDUTIL" ]; then
        USEDUTIL=$DEFUTIL
      elif [[ $USEDUTIL == 'n' && $UTILNETSTAT == 1 ]]; then
        USEDUTIL='netstat'
      elif [[ $USEDUTIL == 's' && $UTILSS == 1 ]]; then
        USEDUTIL='ss'
      elif ! [[ $USEDUTIL == 'netstat' || $USEDUTIL == 'ss' ]]; then
        echo "[Warning] Unknown answer '$USEDUTIL'"
      fi
      #       echo "[Warning] Unknown answer '$CONTYPESHORT', must be 'a' or 'e' or 'l' or emty"
    done
    echo "[INFO] Utility setted to $USEDUTIL"
  fi
}
## Checking whois filter function
#if whois filter option not set, ask to set new one or setting default value
# depends on silent mode option
whois_checker() {
  if [[ $SILENT ]]; then
    echo '[Warning] Whois filter option not set, setting default value "Organization"'
    WHOISF='Organization'
  else
    while ! [[ $WHOISF =~ $re_oname ]]; do
      read -p "[MSG] Enter whois filter name or press [ENTER] for default value 'Organization': " WHOISF
      if ! [ "$WHOISF" ]; then
        WHOISF='Organization'
      elif ! [[ $WHOISF =~ $re_oname ]]; then
        echo "[Warning] Cant set whois filter name as '$WHOISF', must be or name"
      fi
    done
    echo "[INFO] whois filter name setted to $WHOISF"
  fi
}
###Checking sudo rights | sudo recomended
if [[ $EUID -ne 0 ]]; then
  echo -e "Rights     | [FAIL] | ${RED}No Sudo${ENDCOLOR}"
else
  echo -e "Rights     |  [OK]  | ${GREEN}Sudo${ENDCOLOR}"
  SUDOSTATE=1
fi
###Chechinkg Operation System | must be linux
unamer="$(uname -s)"
if [[ $unamer == Linux* ]]; then
  echo -e "OS         |  [OK]  | ${GREEN}$unamer${ENDCOLOR}"
else
  echo -e "OS         | [FAIL] | ${RED}$unamer${ENDCOLOR}"
  exit 1
fi
### Tools check [ (netstat | ss)!important | whois ]
if [ -z "$(which netstat)" ] && [ -z "$(which ass)" ]; then
  echo -e "Tools      | [FAIL] | ${RED}netstat and ss not installed${ENDCOLOR}"
  exit 1
elif [ -z "$(which netstat)" ]; then
  echo -e "Tools      |  [OK]  | ${GREEN}ss${ENDCOLOR}"
  UTILSS=1
elif [ -z "$(which ss)" ]; then
  echo -e "Tools      |  [OK]  | ${GREEN}netstat${ENDCOLOR}"
  UTILNETSTAT=1
else
  echo -e "Tools      |  [OK]  | ${GREEN}netstat${ENDCOLOR} & ${GREEN}ss${ENDCOLOR}"
  UTILSS=1
  UTILNETSTAT=1
fi
if [ -z "$(which whois)" ]; then
  echo -e "Whois      | [FAIL] | ${RED}not installed ${ENDCOLOR}"
else
  echo -e "Whois      |  [OK]  | ${GREEN}installed${ENDCOLOR}"
  UTILWHOIS=1
fi

#### checking flags of script
#      flag               |        descr
# -s silent mode          | show only errors if exists and result
# -h help                 | show help information
# -p process              | select proces by name or id [nubmer or string]
# -c count                | limit for result [number]
# -w whois option         | selecting option for whois grep [string]
# -b switch netstat\ss    | swich netstat \ ss tool to use [netstat|ss]
# -d disable whois        | disable whois tool using [if -d whois tool is off]
# -n net.connection_state | state connection type [established|LISTENING|all]
for item in ${flags_array[*]}; do
  TESTED=1
  unset OPTIND
  unset TMPOPTARG
  while getopts ":p:n:w:b:c:h:s:d:pnwbchsd" opt; do
    #        echo "[$item] = $opt = $OPTARG"
    if [[ $opt == $item || ($opt == ':' && $OPTARG == $item) ]] && ! [[ $OPTARG =~ ^-[p/n/s/b/w/c/d/h]$ ]]; then
      if [[ $OPTARG && $opt != ':' ]]; then
        TESTED=3
        TMPOPTARG=$OPTARG
      else
        TESTED=2
      fi
    elif [[ ("-$item" == $OPTARG || ($opt == ':' && $OPTARG == $item)) && ($item == 's' || $item == 'b' || $item == 'h') ]]; then
      #    elif [[ ("-$item" == $OPTARG || "$item" == $OPTARG || $opt == $item) && ($item == 's' || $item == 'b' || $item == 'h') ]]; then
      TESTED=2
    fi
  done
  if [[ $item == 's' && ! $SUDOSTATE ]]; then
    echo '[Warning] Without sudo you will not get full info, recomended to start script using'
    if [ ! $SILENT ]; then
      echo -e "sudo ./$(basename "${BASH_SOURCE[0]}") ${ARGS[0]} "
    fi
  fi
  case "$item-$TESTED" in
  h-3 | h-2) helpmessage ;;
  s-3 | s-2)
    echo '[INGO] SILENT MODE IS SET'
    SILENT=1
    ;;
  p-1 | p-2) process_checker ;;
  p-3)
    if ! [[ $TMPOPTARG =~ $re_num || $TMPOPTARG =~ $re_pname ]]; then
      echo "[Warning] Cant set Process as '$TMPOPTARG', must be diggit or name"
      process_checker
    else
      PROCESS=$TMPOPTARG
    fi
    ;;
  c-1 | c-2) count_checker ;;
  c-3)
    if ! [[ $TMPOPTARG =~ $re_num || $TMPOPTARG == 'all' ]]; then
      echo "[Warning] Cant set limit count as '$TMPOPTARG', must be diggit or all"
      count_checker
    else
      LIMIT=$TMPOPTARG
    fi
    ;;
  n-1 | n-2) connecttype_checker ;;
  n-3)
    case $TMPOPTARG in
    LISTENING) CONTYPE='LISTEN' ;;
    LISTEN) CONTYPE='LISTEN' ;;
    ESTABLISHED) CONTYPE='ESTAB' ;;
    ESTAB) CONTYPE='ESTAB' ;;
    ALL)
      CONTYPE='ESTAB'
      CONTYPE2='LISTEN'
      ;;
    e) CONTYPE='ESTAB' ;;
    l) CONTYPE='LISTEN' ;;
    a)
      CONTYPE='ESTAB'
      CONTYPE2='LISTEN'
      ;;
    *)
      echo "[Warning] Unknown option for state connection type '$TMPOPTARG', must be 'a' or 'e' or 'l' "
      connecttype_checker
      ;;
    esac
    ;;
  d-1)
    if ! [[ $UTILWHOIS ]]; then
      echo '[Warning] whois not installed, so cant be used by script'
    fi
    ;;
  d-2 | d-3)
    echo '[INFO] Whois disabled'
    unset UTILWHOIS
    ;;
  b-1 | b-2) utility_checker ;;
  b-3)
    case $TMPOPTARG in
    nestat) USEDUTIL='netstat' ;;
    ss) USEDUTIL='ss' ;;
    n) USEDUTIL='netstat' ;;
    s) USEDUTIL='ss' ;;
    *)
      echo "[Warning] Unknown option utility type '$TMPOPTARG', must be 'netstat' or 'ss' "
      utility_checker
      ;;
    esac
    ;;
  w-1 | w-2)
    if [[ $UTILWHOIS ]]; then
      whois_checker
    elif [[ "$item-$TESTED" == "w-2" ]]; then
      echo "[Warning] Finded option -w but whois cant be used"
    fi
    ;;
  w-3)
    if [[ $UTILWHOIS ]]; then
      if ! [[ $TMPOPTARG =~ $re_oname ]]; then
        echo "[Warning] Unknown Whois filter option '$TMPOPTARG', must be 'name' "
        whois_checker
      else
        WHOISF=$TMPOPTARG
      fi
    else
      echo "[Warning] Finded option -w but whois cant be used"
    fi
    ;;
  esac
done
#### Main code...
## I'm a litle tired now
MAINCOMMAND="$($(echo $USEDUTIL -tunap))"
if [ -z "${CONTYPE2}" ]; then
  CONTYPE2=$CONTYPE
fi
if [ $USEDUTIL == 'netstat' ]; then
  IPLIST="$(echo "$MAINCOMMAND" | grep -e $CONTYPE -e $CONTYPE2 | awk '/'"$PROCESS"/' {print $5}' | cut -d: -f1)"
else
  IPLIST="$(echo "$MAINCOMMAND" | grep -e $CONTYPE -e $CONTYPE2 | awk '/'"$PROCESS"/' {print $6}' | cut -d: -f1)"
fi
if [ -z "${IPLIST}" ]; then
  echo "Cant find any connections on $PROCESS process."
  exit 1
fi
echo -e "========================================================================"
if [ $UTILWHOIS ]; then
  echo -e "     IP\t\t|      Count""\t| Whois filter"
  echo -e "========================================================================"
else
  echo -e "     IP\t\t|      Count"
  echo -e "========================================================================"
fi
NETUTILRESULT="$(echo "$IPLIST" | cut -d: -f1 | sort | uniq -c | sort | tail -n$LIMIT)"
while IFS=', ' read -r str; do
  IP=$(echo $str | awk '{print $2}')
  COUNTER=$(echo $str | awk '{print $1}')
  if [ $UTILWHOIS ]; then
    ORG_NAME=$(whois $IP | grep -m 1 $WHOISF)
    echo -e "$IP\t|\t$COUNTER\t| $ORG_NAME"
  else
    echo -e "$IP\t|\t$COUNTER"
  fi
done <<<"$NETUTILRESULT"
exit 1
