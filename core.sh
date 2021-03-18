#!/usr/bin/env bash

COLUMNS=30
LINES=30

declare -g -x ifs=''

declare -g -x -A frame=( ['y']=$LINES ['x']=$COLUMNS )
declare -g -x -A focus=( ['x']=1 ['y']=1 )

declare -g -x text=""
declare -g -x action=''

Input(){
  input=''
  read -n1 -r key
  case $key in
    $'\e') 
      read -n2 -r -t.001 ctrl
      case $ctrl in
        '[A') input=up ;;
        '[B') input=dn ;;
        '[C') input=rt ;;
        '[D') input=lt ;;
           *) input=qt ;;
      esac;;
    *) text+=$key ;;
  esac
  action=$input
}

Minimum(){
  (( focus[$1] > 1 ))
}

Maximum(){
  (( focus[$1] < frame[$1] ))
}

Reverse(){
  focus[$1]=$(( ${focus[$1]}-1 ))
}

Forward(){
  focus[$1]=$(( ${focus[$1]}+1 ))
}

Control(){
  case $action in
    up) Minimum y && Reverse y ;;
    dn) Maximum y && Forward y ;;
    rt) Maximum x && Forward x ;;
    lt) Minimum x && Reverse x ;;
    qt) exit ;;
  esac
}

Primer(){
  echo -e "\ec"
  echo -e "\e[1;44m"
  echo -e "\e[2J"
}

Render(){
  echo -en "\e[${focus['y']};${focus['x']}H\e ▒ $text"
}

End(){
  IFS=$ifs
  exit
}

Core(){
  while [ : ]; do
    Input
    Control
    Output
  done
}

Output(){
  Primer
  Render
}

Start(){
  stty raw
  ifs=$IFS
  IFS=''
}

# Main
# ----
Start
Output
Core
End
