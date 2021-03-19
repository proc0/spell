#!/usr/bin/env bash

ROWS=44
COLS=88

FOCUS=▒
BLOCK=▒

declare -r -A FRAME=( ['y']=$ROWS ['x']=$COLS )
declare -A focus=( ['x']=1 ['y']=1 )

action=''

text=''
rect=''

Input(){
  local input=''
  local key
  read -n1 -r key
  case $key in
    $'\e') 
      read -n2 -r -t.001 key
      case $key in
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
  (( focus[$1] < FRAME[$1] ))
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
    UT) Stop ;;
  esac
}

Foreground(){
  local color="\e"
  case "$1" in
      gray) color+="[01;30m" ;;
      red) color+="[01;31m" ;;
      green) color+="[01;32m" ;;
      yellow) color+="[01;33m" ;;
      blue) color+="[01;34m" ;;
      magenta) color+="[01;35m" ;;
      cyan) color+="[01;36m" ;;
      white) color+="[01;37m" ;;
      *) color+="[01;37m" ;;
  esac
  echo $color
}

Background(){
  local color="\e"
  case $1 in
      gray) color+="[01;40m" ;;
      red) color+="[01;41m" ;;
      green) color+="[01;42m" ;;
      yellow) color+="[01;43m" ;;
      blue) color+="[01;44m" ;;
      magenta) color+="[01;45m" ;;
      cyan) color+="[01;46m" ;;
      white) color+="[01;47m" ;;
      black) color+="[01;49m" ;;
      *) color+="[01;49m" ;;
  esac
  echo $color
}

Rectangle(){
  local x=$(( $1 + 1 ))
  local y=$(( $2 + 1 ))
  local w=$(( $3 ))
  local h=$(( $4 ))

  local rectangle="\e[$x;$y;H\e[1;$5"
  for i in $( seq 1 $h ); do 
    row=$(( i + x ))
    for ii in $( seq 1 $w ); do 
      rectangle+=$BLOCK
    done
    rectangle+="\n\e[$row;$y;H"
  done

  echo $rectangle
}

Primer(){
  bg=`Background cyan`
  echo -e "$bg\e[2J"
}

Render(){
  bg=`Background cyan`
  echo -e $rect
  echo -en "$bg\e[${focus['y']};${focus['x']}H$FOCUS$text"
}

Resize(){
  echo -e "\e[8;$ROWS;$COLS;t"
}

Output(){
  Primer
  Render
}

Spin(){
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

OFS=$IFS

Stop(){
  IFS=$OFS
  exit 0
}

Core(){
  Start
  Spin
  Stop
}

rect=$(Rectangle 3 3 15 5 `Background green`)
rect+=$(Rectangle 4 4 13 1 `Background cyan`)

Core
