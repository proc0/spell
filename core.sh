#!/usr/bin/env bash

ROWS=44
COLS=88

FOCUS=▒
BLOCK=▒

declare -r -A FRAME=( ['y']=$ROWS ['x']=$COLS )
declare -A focus=( ['x']=1 ['y']=1 )

action=''

string=''

selected=-1
declare -a components=()
declare -a focals=()

Input(){
  local input=''
  local key
  read -n1 -r key
  case $key in
    $'\e') 
      read -n2 -r -t.001 key
      case $key in
        '[A') input=UP ;;
        '[B') input=DN ;;
        '[C') input=RT ;;
        '[D') input=LT ;;
           *) input=QU ;;
      esac;;
    *) string+=$key ;;
  esac
  action=$input
}

Minimum(){
  (( focus[$1] > 1 ))
}

Maximum(){
  (( focus[$1] < FRAME[$1] ))
}

Backward(){
  focus[$1]=$(( ${focus[$1]}-1 ))
}

Forward(){
  focus[$1]=$(( ${focus[$1]}+1 ))
}

Retreat(){
  Minimum $1 && Backward $1
}

Advance(){
  Maximum $1 && Forward $1
}

SelectPrev(){
  (( selected >= 1 )) && selected=$(( selected - 1 ))
}

SelectNext(){
  (( selected < ${#components[@]}-1 )) && selected=$(( selected + 1 ))
}

Control(){
  case $action in
    # UP) Retreat y ;;
    # DN) Advance y ;;
    # LT) Retreat x ;;
    # RT) Advance x ;;
    UP) SelectPrev ;;
    DN) SelectNext ;;
    LT) SelectPrev ;;
    RT) SelectNext ;;
    QU) Stop ;;
  esac
}

Color(){
  local color
  case $1 in
      gray)   color=0 ;;
      red)    color=1 ;;
      green)  color=2 ;;
      yellow) color=3 ;;
      blue)   color=4 ;;
      violet) color=5 ;;
      cyan)   color=6 ;;
      white)  color=7 ;;
      *)      color=8 ;;
  esac
  echo $color
}

Foreground(){
  echo "\e[01;3`Color $1`m"
}

Background(){
  echo "\e[01;4`Color $1`m"
}

Focus(){
  echo "\e[$1;$2;H" 
}

Civis(){
  echo "\e[?25l" 
}

Cnorm(){
  echo "\e[?25h" 
}

Rectangle(){
  local x=$(( $1 + 1 ))
  local y=$(( $2 + 1 ))
  local w=$(( $3 ))
  local h=$(( $4 ))

  local rect="`Focus $x $y``Background $5`"
  for r in $( seq 1 $h ); do 
    row=$(( r + x ))
    for c in $( seq 1 $w ); do 
      rect+=$BLOCK
    done
    rect+="\n`Focus $row $y`"
  done
  echo $rect
}

InputText(){
  local x=$(( $1 + 1 ))
  local y=$(( $2 + 1 ))
  local w=$(( $3 ))

  local dx=$(( $x + 1 ))
  local dy=$(( $y + 1 ))
  local dw=$(( $w - 2 ))

  local widget
  widget=$( Rectangle $x $y $w 3 green )
  widget+=$( Rectangle $dx $dy $dw 1 gray )

  echo $widget
}

Layout(){
  echo -e "${components[*]}"
  if (( $selected > -1 )); then
    echo -e "`Cnorm`\e[7m${components[$selected]}\e[27m"
  else
    echo -e "`Civis`"
  fi
}

BG=`Background gray`

Cursor(){
  # Move XY -> `Focus ${focus['y']} ${focus['x']}`
  (( $selected > -1 )) && echo -e "${focals[$selected]}$BG"
  (( ${#string} > 0 || $selected > -1 )) && echo -en "\e[7m$FOCUS$string\e[27m"
}

Primer(){
  echo -e "$BG\e[2J"
}

Render(){
  Layout
  Cursor
}

Resize(){
  echo -e "\e[8;$ROWS;$COLS;t"
}

Guard(){
  if [[ -n $OFS && $IFS == '' ]]; then
    IFS=$OFS
  else
    OFS=$IFS
    IFS=''
  fi
}

Init(){
  stty raw

  components=( `InputText 3 3 15` `InputText 7 3 15` )
  focals=( '\e[5;6;H' '\e[9;6;H' )

  Guard
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
  Init
  Resize
  Output
}

Stop(){
  IFS=$OFS
  exit 0
}

Core(){
  Start
  Spin
  Stop
}

Core
