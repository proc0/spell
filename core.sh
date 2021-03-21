#!/usr/bin/env bash

ROWS=44
COLS=88

FOCUS=▒
BLOCK=▒

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

Background(){
  echo "\e[01;4`COLOR $1`m"
}

Foreground(){
  echo "\e[01;3`COLOR $1`m"
}

BG=`Background black`

input=''
action=''
selected=-1
previous=-1
declare -a focus=()
declare -a content=()

Listen(){
  local intent=''
  local key
  read -n1 -r key
  case $key in
    $'\e') 
      read -n2 -r -t.001 key
      case $key in
        '[A') intent=UP ;;
        '[B') intent=DN ;;
        '[C') intent=RT ;;
        '[D') intent=LT ;;
           *) intent=QU ;;
      esac;;
    *) input+=$key ;;
  esac
  action=$intent
}

Backward(){
  previous=$selected
  (( selected >= 1 )) && \
    selected=$(( selected - 1 ))
}

Foreward(){
  previous=$selected
  (( selected < ${#content[@]}-1 )) && \
    selected=$(( selected + 1 ))
}

Control(){
  case $action in
    UP) Backward ;;
    DN) Foreward ;;
    LT) Backward ;;
    RT) Foreward ;;
    QU) Stop ;;
  esac
}

CODE(){
  local code
  case $1 in
    invert) code=7 ;;
    cursor) code=25 ;;
    revert) code=27 ;;
    *)      code=0 ;;
  esac
  echo $code
}

Focus(){
  echo "\e[$1;$2;H" 
}

Mode(){
  local mode
  if [[ $1 == '' || $1 == 'set' ]]; then
    mode=h
  elif [[ $1 == 'reset' ]]; then
    mode=l
  fi
  echo "\e[?$(CODE $1)$mode" 
}

Term(){
  echo "\e[`CODE $1`m"
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

Field(){
  local x=$(( $1 + 1 ))
  local y=$(( $2 + 1 ))
  local w=$(( $3 - 2 ))
  local c=$4

  local field
  if (( ${#input} > 0 )); then
    field+="$BG`Text $x $y`$input"
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

Select(){
  local selection
  if (( $selected > -1 )); then
    if (( $previous != $selected )); then
      selection+="`Term invert`${content[$selected]}`Term revert`"
    fi
    selection+="${focus[$selected]}$BG\n$FOCUS$input"
  fi
  echo $selection
}

Render(){
  echo -e "$BG\e[2J${content[*]}${focus[$selected]}"
  echo -en "`Select`"
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
  content=( `Entry 3 3 15 green blah1` `Entry 7 3 15 blue blah2` )
  focus=( '\e[5;6;H' '\e[9;6;H' )
  # echo -e "`Mode reset cursor`"
  Guard
}

Spin(){
  while [ : ]; do
    Listen
    Control
    Render
  done
}

Start(){
  Init
  Resize
  Render
  echo -e "`Focus 0 0`"

}

Stop(){
  Guard
  exit
}

Core(){
  Start
  Spin
  Stop
}

Core
