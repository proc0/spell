#!/bin/bash

COLUMNS=30
LINES=30

declare -g -x input=''
declare -g -x ifs=$IFS

declare -g -x -A _screen=(
    ['rows']=$LINES
    ['cols']=$COLUMNS
)

declare -g -x -A _cursor=( ['x']=5 ['y']=5 )
declare -g -x -A _prev=( ['x']=5 ['y']=5 )
declare -g -x blink=0

Move(){
  case $1 in
    "up") (( _cursor['y'] > 1 )) && _cursor['y']=$(( ${_cursor['y']}-1 )) ;;
    "down") (( _cursor['y'] < _screen['rows'] )) && _cursor['y']=$(( ${_cursor['y']}+1 )) ;;
    "left") (( _cursor['x'] > 1 )) && _cursor['x']=$(( ${_cursor['x']}-1 )) ;;
    "right") (( _cursor['x'] < _screen['cols'] )) && _cursor['x']=$(( ${_cursor['x']}+1 )) ;;
    *) (( _cursor['x'] < _screen['cols'] )) && _cursor['x']=$(( ${_cursor['x']}+1 )) ;;
  esac

  if [[ ${_cursor['x']} != ${_prev['x']} ]] || [[ ${_cursor['y']} != ${_prev['y']} ]]; then

    _prev['x']=${_cursor['x']}
    _prev['y']=${_cursor['y']}
  fi
}

Input(){
  read -n2 -r _input 2>/dev/null
  # read -n1 -r -t 0.01 _input 2>/dev/null >&2
  input=$_input
}

Control(){
  case $input in
    $'\e[A') Move ;;
    $'\e[B') Move down;;
    $'\e[C') Move right;;
    $'\e[D') Move left;;
    $'\e') exit 0;;
    *) echo "";;
  esac
}

Output(){
  echo -e "\ec"
  echo -e "\e[1;44m"
  echo -e "\e[2J"
  echo -e "\e[${_cursor['y']};${_cursor['x']}H"

}

Start(){
  IFS=''
  stty sane time 0 2>/dev/null 
}

End(){
  IFS=$ifs
  exit 0
}

Core(){
  Start
  Output
  while [ : ]; do
    Input
    Control
    Output
  done
}

Core
