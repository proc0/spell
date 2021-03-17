#!/bin/bash

COLUMNS=30
LINES=30

declare -g -x input=''

declare -g -x -A room=( ['x']=$LINES ['y']=$COLUMNS )

declare -g -x -A mouse=( ['x']=1 ['y']=1 )


Move(){
  case $1 in
    up) (( mouse['y'] > 1 )) && mouse['y']=$(( ${mouse['y']}-1 )) ;;
    down) (( mouse['y'] < room['x'] )) && mouse['y']=$(( ${mouse['y']}+1 )) ;;
    left) (( mouse['x'] > 1 )) && mouse['x']=$(( ${mouse['x']}-1 )) ;;
    right) (( mouse['x'] < room['y'] )) && mouse['x']=$(( ${mouse['x']}+1 )) ;;
  esac
}

Input(){
  read -n3 -r input 2>/dev/null
}

Control(){
  case $input in
    $'\e[A') Move up;;
    $'\e[B') Move down;;
    $'\e[C') Move right;;
    $'\e[D') Move left;;
    $'\e[\e') return 1;;
    *) return 0;;
  esac
}

Output(){
  echo -e "\ec"
  echo -e "\e[1;44m"
  echo -e "\e[2J"
  echo -e "\e[${mouse['y']};${mouse['x']}H\e ▒"
}

Setup(){
  stty raw
}

End(){
  exit 0
}

Core(){

  while [ : ]; do
    Input
    Control
    Output
  done
}

Start(){
  Setup
  Output
  trap 'Input, Core, Control; exit' 1
}

Start
Core
End
