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
 
Rectangle(){
  local x=$(( $1 + 1 ))
  local y=$(( $2 + 1 ))
  local w=$(( $3 ))
  local h=$(( $4 ))

  local rectangle="\e[$x;$y;H\e[1;$5m"
  for i in $( seq 1 $h ); do 
    row=$(( i + x ))
    for ii in $( seq 1 $w ); do 
      rectangle+=$BLOCK
    done
    rectangle+="\n\e[$row;$y;H"
  done
  rectangle+="\e[1;44m"

  echo $rectangle
}

Primer(){
  echo -e "\e[1;44m\e[2J"
}

Render(){
  echo -e $rect
  echo -en "\e[${focus['y']};${focus['x']}H$FOCUS$text"
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

rect=$(Rectangle 3 3 15 5 41)
rect+=$(Rectangle 4 4 13 1 44)

Core
