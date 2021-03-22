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

ROLOC(){
  local roloc
  case $1 in
    black)  roloc=white ;;
    red)    roloc=green ;;
    green)  roloc=red ;;
    brown)  roloc=blue ;;
    blue)   roloc=brown ;;
    violet) roloc=cyan ;;
    cyan)   roloc=violet ;;
    white)  roloc=white ;;
    *)      roloc=white ;;
  esac
  echo $roloc  
}

Background(){
  echo "\e[4`COLOR $1`m"
}

Foreground(){
  echo "\e[3`COLOR $1`m"
}

_BG=black
_FG=white
BG=`Background $_BG`
FG=`Foreground $_FG`

input=''
action=''
selected=-1
previous=-1
declare -a focused=()
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
  (( selected >= 1 )) \
    && selected=$(( selected - 1 ))
}

Foreward(){
  previous=$selected
  (( selected < ${#content[@]}-1 )) \
    && selected=$(( selected + 1 ))
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
    insert) code=4 ;;
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

Text(){
  echo "`Foreground $3``Focus $1 $2`$4"
}

Rect(){
  local x=$(( $1 ))
  local y=$(( $2 ))
  local w=$(( $3 ))
  local h=$(( $4 ))

  local rect="`Background $5`"
  for r in $( seq 1 $h ); do 
    rect+="\e[4h`Focus $(( $x+$r )) $y`\e[$w;@\e[4l"
  done

  echo $rect
}

Field(){
  local x=$(( $1 + 1 ))
  local y=$(( $2 + 1 ))
  local w=$(( $3 - 2 ))
  local bg=$4
  local fc=$5

  local field=`Rect $x $y $w 1 $bg`
  if (( ${#input} > 0 )); then
    field+=`Text $x $y $fc $input`
  fi

  echo $field
}

Entry(){
  local x=$(( $1 ))
  local y=$(( $2 ))
  local tx=$(( $x + 1 ))
  local ty=$(( $y + 1 ))
  local w=$(( $3 ))
  local bg=$4
  local fc=`ROLOC $4`
  local label=$5

  local top=`Rect $x $y $w 2 $bg`
  local lb=`Text $(( $x+2 )) $(( $y+1 )) $fc $label`
  local cap1=`Rect $(( $x + 2 )) $y 1 1 $bg`
  local inp=`Field $(( $x + 2 )) $y $w $_BG $_FG`
  local cap2=`Rect $(( $x + 2 )) $(( $y + $w - 1 )) 1 1 $bg`
  local bott=`Rect $(( $x + 3 )) $y $w 1 $bg`
  # attaching focus for input, at the end of command
  echo "$top\n$lb\n$cap1\n$inp\n$cap2\n$bott`Focus $(( $x+3 )) $(( $y+1 ))`"
}

Form(){
  local x=$1; 
  local y=$2;
  local w=$3;

  for arg in $( seq 4 $# ); do
    local i=$(($arg-4))
    content[$i]=`Entry $(( $x + 5*$i )) $y $w blue "${!arg}"`
    focused[$i]=`Entry $(( $x + 5*$i )) $y $w red "${!arg}"`
  done
}

Layout(){
  local layout
  if (( $selected > -1 )); then
    for i in "${!content[@]}"; do
      if (( $selected == $i )); then
        layout+="${focused[$i]}"
      else
        layout+="${content[$i]}"
      fi
    done
  else
    layout="${content[*]}"
  fi
  echo $layout
}

Select(){
  local selection
  local active
  if (( $selected > -1 )); then
    # focused element has its focus at the end
    selection+="$BG\e${content[$selected]##*e}$FOCUS$input"
  fi
  echo $selection
}

Render(){

  echo -e "$BG\e[2J`Layout`${focus[$selected]}$FG"
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
  Form 3 3 15 blah1 blah3 some stuff glaaxy
  Guard
  #TODO abstract
  # content=( `Entry 3 3 15 red blah1` `Entry 8 3 15 blue blah2` )
  # focused=( `Entry 3 3 15 cyan blah1` `Entry 8 3 15 cyan blah2` )

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
