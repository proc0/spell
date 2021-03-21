#!/usr/bin/env bash

ROWS=44
COLS=88

FOCUS=▒
BLOCK=▒

action=''

string=''

selected=-1
previous=-1
declare -a components=()
declare -a focus=()

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

# declare -A mouse=( ['x']=1 ['y']=1 )
# declare -r -A FRAME=( ['y']=$ROWS ['x']=$COLS )
# Minimum(){ (( mouse[$1] > 1 )) }
# Maximum(){ (( mouse[$1] < FRAME[$1] )) }
# Backward(){ mouse[$1]=$(( ${mouse[$1]}-1 )) }
# Forward(){ mouse[$1]=$(( ${mouse[$1]}+1 )) }
# Retreat(){ Minimum $1 && Backward $1 }
# Advance(){ Maximum $1 && Forward $1 }
# Activate -> `Focus ${focus['y']} ${focus['x']}`

SelectPrev(){
  previous=$selected
  (( selected >= 1 )) && selected=$(( selected - 1 ))
}

SelectNext(){
  previous=$selected
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

COLOR(){
  local color
  case $1 in
      black)  color=0 ;;
      red)    color=1 ;;
      green)  color=2 ;;
      brown)  color=3 ;;
      blue)   color=4 ;;
      violet) color=5 ;;
      cyan)   color=6 ;;
      white)  color=7 ;;
      *)      color=9 ;;
  esac
  echo $color
}

Foreground(){
  echo "\e[01;3`COLOR $1`m"
}

Background(){
  echo "\e[01;4`COLOR $1`m"
}

Focus(){
  echo "\e[$1;$2;H" 
}

MODE(){
  case $1 in
    cursor) echo 25 ;;
  esac
}

ATTR(){
  case $1 in
    invert) echo 7 ;;
    revert) echo 27 ;;
  esac
}

DECReset(){
  echo "\e[?$(MODE $1)l" 
}

DECSet(){
  echo "\e[?$(MODE $1)h" 
}

SGRSet(){
  echo "\e[`ATTR $1`m"
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

Text(){
  echo "`Focus $1 $2`$3"
}

BG=`Background black`

Field(){
  local x=$(( $1 + 1 ))
  local y=$(( $2 + 1 ))
  local w=$(( $3 - 2 ))
  local c=$4

  local field
  if (( ${#string} > 0 )); then
    field+="$BG`Text $x $y`$string"
  else
    field+=$BG
  fi
  field+=`Rectangle $x $y $w 1 $c`

  echo $field
}

Entry(){
  local x=$(( $1 + 1 ))
  local y=$(( $2 + 1 ))
  local tx=$(( $x + 1 ))
  local ty=$(( $y + 1 ))
  local w=$(( $3 ))
  local c=$4
  local label=$5

  local widget="`
    Rectangle $x $y $w 3 $c
  ``Background $c
  ``Text $tx $ty $label
  ``Field $x $y $w
  `"

  echo $widget
}

Layout(){
  echo "${components[*]}${focus[$selected]}"
}

Activate(){
  local selection
  if (( $selected > -1 )); then
    if (( $previous != $selected )); then
      selection+="`SGRSet invert`${components[$selected]}`SGRSet revert`"
    fi
    selection+="${focus[$selected]}$BG\n$FOCUS$string"
  fi
  echo $selection
}

Render(){
  echo -e "$BG\e[2J`Layout`"
  echo -en "`Activate`"
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
  #TODO abstract
  components=( `Entry 3 3 15 green blah1` `Entry 7 3 15 blue blah2` )
  focus=( '\e[5;6;H' '\e[9;6;H' )

  # echo -e "`DECReset cursor`"
  Guard
}

Spin(){
  while [ : ]; do
    Input
    Control
    Render
  done
}

Start(){
  Init
  Resize
  Render
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
