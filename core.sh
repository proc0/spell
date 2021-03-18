#!/usr/bin/env bash

ROWS=44
COLS=88

OFS=$IFS

declare -A frame=( ['y']=$ROWS ['x']=$COLS )
declare -A focus=( ['x']=1 ['y']=1 )

text=""
action=''

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
           *) input=UT ;;
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
    UT) End ;;
  esac
}

Primer(){
  echo -e "\e[1;44m\e[2J"
}

Render(){
  echo -en "\e[${focus['y']};${focus['x']}H ▒ $text"
}

Resize(){
  echo -e "\e[8;$ROWS;$COLS;t"
}

Output(){
  Primer
  Render
}

Core(){
  while [ : ]; do
    Input
    Control
    Output
  done
}

Start(){
  stty raw
  IFS=''
  Resize
  Output
}

End(){
  IFS=$OFS
  exit 0
}

Main(){
  Start
  Core
  End
}

Main
