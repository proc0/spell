#!/usr/bin/env bash

LINES=44
COLUMNS=88

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
        '[A') input=FW ;;
        '[B') input=BW ;;
        '[C') input=RT ;;
        '[D') input=LT ;;
           *) input=EX ;;
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

Bakward(){
  focus[$1]=$(( ${focus[$1]}-1 ))
}

Forward(){
  focus[$1]=$(( ${focus[$1]}+1 ))
}

Control(){
  case $action in
    FW) Minimum y && Bakward y ;;
    BW) Maximum y && Forward y ;;
    RT) Maximum x && Forward x ;;
    LT) Minimum x && Bakward x ;;
    EX) exit ;;
  esac
}

Primer(){
  echo -e "\ec\e[1;44m\e[2J"
}

Render(){
  echo -en "\e[${focus['y']};${focus['x']}H ▒ $text"
}

End(){
  IFS=$ifs
  exit 0
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

Resize(){
  echo -e "\e[8;$LINES;$COLUMNS;t"
}

Start(){
  stty raw
  ifs=$IFS
  IFS=''
  Resize
}

# Main
# ----
Start
Output
Core
End
