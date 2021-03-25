#!/usr/bin/env bash

# WINDOW
ROWS=44
COLS=88

# PALETTE
BG_COLOR=black
FG_COLOR=white
FORM_COLOR=blue
FORM_FOCUS_COLOR=cyan
FORM_FONT_COLOR=white
FORM_FONT_FOCUS_COLOR=black

declare -a focused=()
declare -a content=()
declare -a selection=()
declare -f handlers=()
_io=0

COLOR(){
  local value
  case $1 in
    black) value=0 ;;
      red) value=1 ;;
    green) value=2 ;;
    brown) value=3 ;;
     blue) value=4 ;;
    lilac) value=5 ;;
     cyan) value=6 ;;
    white) value=7 ;;
        *) value=9 ;;
  esac
  echo $value
}

Background(){
  echo "\e[4$(COLOR $1)m"
}

Foreground(){
  echo "\e[3$(COLOR $1)m"
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
  local limit=${#selection[@]}
  if (( point < limit - 1 )); then
    point=$(( $point + 1 ))
  fi
  echo $point
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

Mode(){
  local mode
  if [[ $1 == '' || $1 == 'set' ]]; then
    mode=h
  elif [[ $1 == 'reset' ]]; then
    mode=l
  fi
  echo "\e[?$(CODE $1)$mode" 
}

# Term(){
#   echo "\e[$(CODE $1)m"
# }

# EVENT
###########

Listen(){
  local input=""
  local intent=""
  local command
  read -n1 -r intent
  case $intent in
    $'\e') 
      read -n2 -r -t.001 command
      case $command in
        [A) input=UP ;;
        [B) input=DN ;;
        [C) input=RT ;;
        [D) input=LT ;;
         *) input=QU ;;
      esac ;;
    $'\0d') input=EN ;;
    *) input="IN$intent" ;;
  esac
  echo "$input"
}

Control(){
  local input="$1"
  local focus=$2
  local action=$focus
  case "$input" in
     UP) action=$(Backward $focus) ;;
     DN) action=$(Foreward $focus) ;;
     LT) action=$(Backward $focus) ;;
     RT) action=$(Foreward $focus) ;;
    IN*) action=-2 ;;
     EN) action=-3 ;;
     QU) action=-9 ;;
  esac
  echo $action
}

Focus(){
  local x=$1
  local y=$2
  echo "\e[$y;$x;H" 
}

# BUILD UI
###########

Text(){
  local x=$1
  local y=$2
  echo "$(Foreground $3)$(Focus $x $y)$4"
}

Rect(){
  local x=$1
  local y=$2
  local w=$3
  local h=$4

  local rect="$(Background $5)"
  for r in $( seq 1 $h ); do 
    rect+="$(Focus $x $(( $y+$r )))\e[$w;@"
  done

  echo $rect
}

Field(){
  local x=$1
  local y=$2
  local w=$3
  local name=$4
  local bg=$5
  local fg=$6
  local fc=$7
  local pad=$(( $w - ${#name} - 1 ))

  local cap1="$(Rect $x $(($y-1)) 1 1 $bg)"
  local label="$(Text $(($x+1)) $y $fc $name)"
  local cap2="$(Rect $x $y 1 1 $bg)"
  local box="$(Rect $(( $x + 1 )) $y $(( $w - 2 )) 1 $fg)"
  local end="$(Rect $(( $x + $w - 1 )) $y 1 1 $bg)"
  local field="$(Background $bg)$cap1$label\e[$pad;@$cap2$box$end"
  echo $field
}

# TextField(){
#   local x=$(( $1 ))
#   local y=$(( $2 ))
#   local tx=$(( $x + 1 ))
#   local ty=$(( $y + 1 ))
#   local w=$(( $3 ))
#   local bg=$4
#   local fc=$(FOCOL $4)
#   local label=$5

#   local top=$(Rect $x $y $w 2 $bg)
#   local lb=$(Text $(( $x+3 )) $y $fc $label)
#   local field=$(Field $(( $x + 4 )) $y $w $bg $BG_COLOR)
#   local bott=$(Rect $(( $x + 5 )) $y $w 1 $bg)
#   # attaching focus at the end
#   local focus=$(Focus $(( $x+3 )) $(( $y+1 )))

#   echo "$top\n$lb\n$field\n$bott$focus"
# }
Button(){
  local x=$1
  local y=$2
  local w=$3
  local name=$4
  local bg=$5
  local fg=$6
  local fc=$7
  local pad=$(( $w - ${#name} ))

  # local top="$(Rect $x $(($y-1)) $w 1 $bg)"
  local cap1="$(Rect $x $(($y-1)) 1 1 $bg)"
  local label="$(Text $x $y $fc $name)"
  # local foot="$(Rect $x $(($y+1)) $w 1 $bg)"

  local button="$cap1$label\e[$pad;@"

  echo $button
}

Form(){
  local fields=($(echo $1 | tr ":" "\n"))
  local color=$2
  local font_color=$3
  local field_color="$BG_COLOR"
  local no_select=$4
  local x=3
  local y=3
  local w=20
  local len=$(( ${#fields[*]} - 1 ))
  for i in $( seq 0 $len ); do
    local row=$(( $y + 2*$(($i+1)) ))
    local field_name=${fields[$i]}
    content[$i]="$(Field $x $row $w $field_name $color $field_color $font_color)"
    if [[ -z $no_select ]]; then
      selection+=("$(Focus $(($x+1)) $(($row+1)))")
    fi
    handlers+=(FieldHandler)
  done
  local buttpos=$(( $len + 1 ))
  local bottpos=$(( $len + 2 ))
  content[$buttpos]="$(Button $x $(( $y + $(( 3 * $len )) + 1 )) $w '[button]' $color $field_color $font_color)"
  if [[ -z $no_select ]]; then
    selection+=($(Focus $x $(( $y + $(( 3 * $len )) + 1 )) ))
  fi
  handlers+=(ButtonHandler)
  content[$bottpos]="$(Rect $x $(( $y + $(( 3 * $len )) + 1 )) $w 1 $color)"
}

Page(){
  local fields=$1
  Form $fields $FORM_FOCUS_COLOR $FORM_FONT_FOCUS_COLOR 1

  for c in ${!content[@]}; do
    focused[$c]=${content[$c]}
  done
  Form $fields $FORM_COLOR $FORM_FONT_COLOR
  # content=($(Form $fields $FORM_COLOR $FORM_FONT_COLOR))
  # focused=($(Form $fields $FORM_FOCUS_COLOR $FORM_FONT_FOCUS_COLOR))
}

# RUN UI
###########

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
    layout=${content[@]}
  fi

  echo -e "$bg\e[2J$layout$fg$bg"

  return 0
}

Render(){
  local focus=$1
  local action=$2
  local blur=$3
  local string="$4"
  local fg=$5
  local bg=$6

  if (( focus != blur )); then
    Layout $focus $fg $bg
  fi

  if [[ -n ${handlers[$focus]} ]]; then 
    echo -en "${selection[$focus]}" 
    eval ${handlers[$focus]} $focus $action
  fi

  if [[ ${handlers[$focus]} == 'FieldHandler' ]]; then
    echo -en "$string"
  fi

  return 0
}

FieldHandler(){
  local focus=$1
  return 0
}

ButtonHandler(){
  local focus=$(( $1 - 1 ))
  local action=$2

  if (( $action == -3 && _io == 0 )); then
    echo -en "${selection[$focus]}`Foreground yellow`YAYA"
    _io=1
  fi
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

# TODO refactor setup, use Resize
Setup(){
  local fg=$1
  local bg=$2
  local fc=-1
  # local setup="$(Resize)"
  local setup="\e[8;$ROWS;$COLS;t"
  setup+="\e[1;$ROWS;r"
  echo -e $setup
  Layout $fc $fg $bg
  echo -e "$(Focus 0 0)"
}

# MAIN
#######

Guard(){
  if [[ -n $OFS ]]; then
    IFS=$OFS
  else
    OFS=$IFS
    IFS=''
  fi

  if [[ -n $OTTY ]]; then
    stty $OTTY
    OTTY=
  else
    OTTY=$(stty -g)
  fi
}

Spawn(){
  Page "inits:proc:sub:sys"
  Guard
  stty raw min 0 time 0
}

Spin(){
  local blur=-1
  local focus=-1
  local action=-1
  local input=""
  local buffer=""
  local string=""
  local fg=$1
  local bg=$2

  while [ : ]; do
    input="$(Listen)"
    if (( ${#input} > 0 )); then
      action=$(Control "$input" $focus)
      case $action in
        -2) buffer="${input:2}";
            string+="$buffer" ;;
        -3) string="" ;;
        -9) break ;;
         *) blur=$focus; focus=$action ;;
      esac
      Render $focus $action $blur "$string" $fg $bg
    fi
  done

  return 0
}

Stop(){
  Guard
  clear
  exit
}

Core(){
  local fg="$(Foreground $FG_COLOR)"
  local bg="$(Background $BG_COLOR)"

  Spawn
  Setup $fg $bg
  Spin $fg $bg
  Stop
}


# RUN
###########
trap 'Stop' HUP INT QUIT TERM
Core
