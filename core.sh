#!/usr/bin/env bash

COLUMNS=30
LINES=30


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

declare -g -x input=''

Input(){
  read -n1 -r -d '' input
}

Control(){
  case "$input" in
    $'\e') 
      read -n2 -r -t.001 -d '' input
      case "$input" in
          '[A') Move up ;;
          '[B') Move down ;;
          '[C') Move right ;;
          '[D') Move left ;;
          *) exit ;;
      esac
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
}

Start
Core
exit
