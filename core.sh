#!/usr/bin/env bash

COLUMNS=30
LINES=30


declare -g -x -A frame=( ['x']=$LINES ['y']=$COLUMNS )
declare -g -x -A focus=( ['x']=1 ['y']=1 )

declare -g -x text=''

Move(){
  case $1 in
    up) (( focus['y'] > 1 )) && focus['y']=$(( ${focus['y']}-1 )) ;;
    down) (( focus['y'] < frame['x'] )) && focus['y']=$(( ${focus['y']}+1 )) ;;
    left) (( focus['x'] > 1 )) && focus['x']=$(( ${focus['x']}-1 )) ;;
    right) (( focus['x'] < frame['y'] )) && focus['x']=$(( ${focus['x']}+1 )) ;;
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
      esac;;
    *) text+="$input";;
  esac
}

Preset(){
  echo -e "\ec"
  echo -e "\e[1;44m"
  echo -e "\e[2J"
}

Render(){
  echo -e "\e[${focus['y']};${focus['x']}H\e ▒ $text"
}

Output(){
  Preset
  Render
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
