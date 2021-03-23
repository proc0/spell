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
    black)  value=0 ;;
    red)    value=1 ;;
    green)  value=2 ;;
    brown)  value=3 ;;
    blue)   value=4 ;;
    violet) value=5 ;;
    cyan)   value=6 ;;
    white)  value=7 ;;
    *)      value=9 ;;
  esac
  echo $value
}

LIGHT(){
  local value
  case $1 in
    black)  value=white ;;
    red)    value=green ;;
    green)  value=red ;;
    brown)  value=blue ;;
    blue)   value=brown ;;
    violet) value=cyan ;;
    cyan)   value=black ;;
    white)  value=white ;;
    *)      value=white ;;
  esac
  echo $value  
}

Background(){
  echo "\e[4`COLOR $1`m"
}

Foreground(){
  echo "\e[3`COLOR $1`m"
}

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
    *) intent="IN$input" ;;
  esac
  echo $intent
}

Backward(){
  local vector=$1
  if (( vector >= 1 )); then
    vector=$(( vector - 1 ))
  fi
  echo $vector
}

Foreward(){
  local vector=$1
  if (( vector < ${#content[@]}-1 )); then
    vector=$(( vector + 1 ))
  fi
  echo $vector
}

Control(){
  local action=$2
  case $1 in
    UP) action=`Backward $2` ;;
    DN) action=`Foreward $2` ;;
    LT) action=`Backward $2` ;;
    RT) action=`Foreward $2` ;;
    IN*) action=-2 ;;
    QU) action=-9 ;;
  esac
  echo $action
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

Focus(){
  echo "\e[$1;$2;H" 
}


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

Layout(){
  local select=$1
  local layout
  if (( $select > -1 )); then
    for i in "${!content[@]}"; do
      if (( $select == $i )); then
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

Cursor(){
  local focus=$1
  local context=$2
  local cursor
  if (( focus > -1 )); then
    local focal="\e${content[$focus]##*e}"
    cursor+="$focal$context"
  fi
  echo $cursor
}

Blur(){
  echo -e "`Focus 0 0`"
}

Render(){
  local focus=$1
  local context=$2
  local bg=`Background $BG`
  local fg=`Foreground $FG`
  echo -e "$bg\e[2J`Layout $focus`$fg$bg"
  echo -en "`Cursor $focus $context`"
}

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

Begin(){
  Form 3 3 35 blah1 blah3 some stuff glaaxy
  Guard
  stty raw min 0 time 0
}

Spin(){
  local focus=-1
  local intent=''
  local action=''
  local input=''
  local context=''
  while [ : ]; do
    intent=`Listen`
    action=`Control $intent $focus`
    case $action in
      -2) input=${intent:2};
          context+=$input ;;
      -9) break; Stop ;;
       *) focus=$action ;;
    esac
    Render $focus $context
  done
}

Start(){
  Begin
  Setup
  Render
  Blur
}

Stop(){
  Guard
  clear
  exit
}

Core(){
  Start
  Spin
  Stop
}

Core
