#!/usr/bin/env bash

ROWS=44
COLS=88

BG=black
FG=white
FORM_BG=blue
FORM_FC=cyan

declare -a focused=()
declare -a content=()

COLOR(){
  local value
  case $1 in
    black) value=0 ;;
    red) value=1 ;;
    green) value=2 ;;
    brown) value=3 ;;
    blue) value=4 ;;
    violet) value=5 ;;
    cyan) value=6 ;;
    white) value=7 ;;
    *) value=9 ;;
  esac
  echo $value
}

LIGHT(){
  local value
  case $1 in
    black) value=white ;;
    red) value=green ;;
    green) value=red ;;
    brown) value=blue ;;
    blue) value=brown ;;
    violet) value=cyan ;;
    cyan) value=black ;;
    white) value=white ;;
    *) value=white ;;
  esac
  echo $value  
}

Background(){
  echo "\e[4`COLOR $1`m"
}

Foreground(){
  echo "\e[3`COLOR $1`m"
}

Backward(){
  local point=$1
  if (( point >= 1 )); then
    point=$(( point - 1 ))
  fi
  echo $point
}

Foreward(){
  local point=$1
  local limit=${#content[@]}
  if (( point < limit-1 )); then
    point=$(( point + 1 ))
  fi
  echo $point
}

# CODE(){
#   local code
#   case $1 in
#     insert) code=4 ;;
#     invert) code=7 ;;
#     cursor) code=25 ;;
#     revert) code=27 ;;
#     *)      code=0 ;;
#   esac
#   echo $code
# }

# Mode(){
#   local mode
#   if [[ $1 == '' || $1 == 'set' ]]; then
#     mode=h
#   elif [[ $1 == 'reset' ]]; then
#     mode=l
#   fi
#   echo "\e[?$(CODE $1)$mode" 
# }

# Term(){
#   echo "\e[`CODE $1`m"
# }

# EVENT
###########

Listen(){
  local intent=''
  local input
  read -n1 -r input
  case $input in
    $'\e') 
      read -n2 -r -t.001 input
      case $input in
        '[A') intent=UP ;;
        '[B') intent=DN ;;
        '[C') intent=RT ;;
        '[D') intent=LT ;;
           *) intent=QU ;;
      esac;;
    *) (( ${#input} > 0 )) && intent="IN$input" ;;
  esac
  echo $intent
}

Control(){
  local intent=$1
  local focus=$2
  local code=$focus
  case $intent in
    UP) code=`Backward $focus` ;;
    DN) code=`Foreward $focus` ;;
    LT) code=`Backward $focus` ;;
    RT) code=`Foreward $focus` ;;
    IN*) code=-2 ;;
    QU) code=-9 ;;
  esac
  echo $code
}

Focus(){
  echo "\e[$1;$2;H" 
}

# BUILD UI
###########

Text(){
  echo "`Foreground $3``Focus $1 $2`$4"
}

Rect(){
  local x=$1
  local y=$2
  local w=$3
  local h=$4

  local rect=`Background $5`
  for r in $( seq 1 $h ); do 
    rect+=`Focus $(( $x+$r )) $y`
    rect+="\e[$w;@"
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
  # field+=`Text $x $y $fc $_input`

  echo $field
}

TextField(){
  local x=$(( $1 ))
  local y=$(( $2 ))
  local tx=$(( $x + 1 ))
  local ty=$(( $y + 1 ))
  local w=$(( $3 ))
  local bg=$4
  local fc=`LIGHT $4`
  local label=$5

  local top=`Rect $x $y $w 2 $bg`
  local lb=`Text $(( $x+2 )) $(( $y+1 )) $fc $label`
  local cap1=`Rect $(( $x + 2 )) $y 1 1 $bg`
  local inp=`Field $(( $x + 2 )) $y $w $BG $FG`
  local cap2=`Rect $(( $x + 2 )) $(( $y + $w - 1 )) 1 1 $bg`
  local bott=`Rect $(( $x + 3 )) $y $w 1 $bg`
  # attaching focus at the end
  local focus=`Focus $(( $x+3 )) $(( $y+1 ))`

  echo "$top\n$lb\n$cap1\n$inp\n$cap2\n$bott$focus"
}

Form(){
  local x=$1; 
  local y=$2;
  local w=$3;
  local idx
  for idx in $( seq 4 $# ); do
    local i=$(($idx-4))
    content[$i]=`TextField $(( $x + 5*$i )) $y $w $FORM_BG "${!idx}"`
    focused[$i]=`TextField $(( $x + 5*$i )) $y $w $FORM_FC "${!idx}"`
  done
}

# OUTPUT UI
###########

Blur(){
  echo -e "`Focus 0 0`"
}

Layout(){
  local focus=$1
  local fg=$2
  local bg=$3
  local layout
  if (( focus > -1 )); then
    for i in ${!content[@]}; do
      if (( focus == i )); then
        layout+=${focused[$i]}
      else
        layout+=${content[$i]}
      fi
    done
  else
    layout=${content[*]}
  fi
  echo -e "$bg\e[2J$layout$fg$bg"
}

Render(){
  local focus=$1
  local blur=$2
  local context=$3
  local fg=$4
  local bg=$5

  if (( focus != blur )); then
    Layout $focus $fg $bg
  fi

  if (( ${#context} > 0 && focus > -1 )); then 
    echo -en "\e${focused[$focus]##*e}$context"
  fi
}

# SETUP
###########
# TODO refactor setup, use Resize
Setup(){
  # local setup="`Resize`"
  local setup="\e[8;$ROWS;$COLS;t"
  setup+="\e[1;$ROWS;r"
  echo -e $setup
}

Resize(){
  local pos
  printf "\e[13t" > /dev/tty
  IFS=';' read -r -d t -a pos

  local xpos=${pos[1]}
  local ypos=${pos[2]}

  printf "\e[14;2t" > /dev/tty
  IFS=';' read -r -d t -a size

  local hsize=${size[1]}
  local wsize=${size[2]}

  echo "\e[8;$hsize;$wsize;t"
}

Guard(){
  if [[ -n $OFS ]]; then
    IFS=$OFS
  else
    OFS=$IFS
    IFS=
  fi

  if [[ -n $OTTY ]]; then
    stty $OTTY
    OTTY=
  else
    OTTY=$(stty -g)
  fi
}


# MAIN
###########
Begin(){
  Form 3 3 35 blah1 blah3 some stuff glaaxy
  Guard
  stty raw min 0 time 0
}

Spin(){
  local blur=-1
  local code=-1
  local focus=-1
  local intent=''
  local input=''
  local context=''
  local fg=$1
  local bg=$2

  while [ : ]; do
    intent=`Listen`
    if [[ -n $intent ]]; then
      code=`Control $intent $focus`
      case $code in
        -2) input=${intent:2};
            context+=$input ;;
        -9) break ;;
         *) blur=$focus; focus=$code ;;
      esac
      Render $focus $blur $context $fg $bg
    fi
  done
}

Start(){
  local fg=$1
  local bg=$2
  local fc=-1
  Begin
  Setup
  Layout $fc $fg $bg
  Blur
}

Stop(){
  Guard
  clear
  exit
}

Core(){
  local fg=`Foreground $FG`
  local bg=`Background $BG`

  Start $fg $bg
  Spin $fg $bg
  Stop
}


# RUN
###########
Core
