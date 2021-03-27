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

SAMPLE_INPUT="inits:pspsp:asdfasd:blahblah"

CODE(){
  case $1 in
    insert) echo 4  ;;
    invert) echo 7  ;;
    cursor) echo 25 ;;
    revert) echo 27 ;;
    *)      echo 0  ;;
  esac
}

COLOR(){
  case $1 in
    black) echo 0 ;;
      red) echo 1 ;;
    green) echo 2 ;;
    brown) echo 3 ;;
     blue) echo 4 ;;
    lilac) echo 5 ;;
     cyan) echo 6 ;;
    white) echo 7 ;;
        *) echo 9 ;;
  esac
}

Mode(){
  local toggle=$1
  local code=$2
  local mode

  if [[ $toggle == '' || $toggle == 'set' ]]; then
    mode=h
  elif [[ $toggle == 'reset' ]]; then
    mode=l
  fi

  echo "\e[?$(CODE $code)$mode" 
}

Term(){
  echo "\e[$(CODE $1)m"
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

# EVENT
###########

Listen(){
  local input=""
  local intent=""
  local command
  read -n1 -r intent
  case "$intent" in
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
  local focus=$2
  local action=$focus
  case "$1" in
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

Label(){
  local cur_row=$1
  local name=$2
  local pad=$(( $w - ${#name} - 1 ))
  local cap1="$(Rect $x $cur_row 1 1 $color)"
  local label="$(Text $pad1 $(($cur_row + 1)) $font_color $name)"
  local cap2="$(Rect $(( $x + ${#name} + 1 )) $cur_row $pad 1 $color)"
  echo "$cap1$label$cap2"
}

Rect(){
  local x=$1
  local y=$2
  local w=$3
  local h=$4

  local rect=$(Background $5)
  for r in $( seq 1 $h ); do 
    rect+="$(Focus $x $(( $y+$r )))\e[$w;@"
  done

  echo $rect
}

Field(){

  local field=$(Label $row $field_name)
  local cap=$(Rect $x $next_row 1 1 $color)
  local box=$(Rect $(( $x + 1 )) $next_row $(( $w - 2 )) 1 $BG_COLOR)
  local end=$(Rect $(( $x + $w - 1 )) $next_row 1 1 $color)
  field+="$cap$box$end"
  echo $field
}

Button(){
  local name=$1
  local pad=$(( $w - ${#name} ))

  # local top="$(Rect $x $(($y-1)) $w 1 $bg)"
  local cap1="$(Rect $x $(($buttonrow-1)) 1 1 $color)"
  local label="$(Text $x $buttonrow $font_color $name)"
  # local foot="$(Rect $x $(($y+1)) $w 1 $bg)"

  local button="$cap1$label\e[$pad;@"

  echo $button
}

Form(){
  local x=2
  local y=2
  local w=20
  local color=$2
  local font_color=$3
  local build_type=$4

  local fields=($(echo $1 | tr ":" "\n"))
  local field_len=${#fields[*]}
  local len=$(( ${#fields[*]} - 1 ))
  local pad1=$(( $x + 1 ))

  local i=0
  local row=0
  local next_row=1
  local field_height=2
  for i in $( seq 0 $len ); do
    row=$(( $y + $field_height*$i ))
    next_row=$(( $row + 1 ))
    local field_name=${fields[$i]}
    content[$i]="$(Field)"
    if [[ -z $build_type ]]; then
      selection[$i]="$(Focus $pad1 $(($next_row + 1)))"
    fi
    handlers[$i]='FieldHandler'
  done

  i=$(( $i + 1 ))
  row=$(( $y + 2*$i ))
  next_row=$(($row+1))
  content[$i]="$(Label $row '[button]')"
  if [[ -z $build_type ]]; then
    selection+=($(Focus $x $row ))
  fi
  handlers[$i]='ButtonHandler'

  i=$(( $i + 1 ))
  content[$i]="$(Rect $x $next_row $w 1 $color)"
}


# RUN UI
###########

Layout(){
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

  layout="$bg\e[2J$layout$fg$bg"

  return 0
}

Render(){
  local layout
  if (( focus != blur )); then
    Layout $focus $fg $bg
  fi

  if [[ ${handlers[$focus]} == 'FieldHandler' ]]; then
    echo -en "$layout${selection[$focus]}$(Mode set cursor)$string"
  elif [[ ${handlers[$focus]} == 'ButtonHandler' ]]; then
    echo -e "$layout${selection[$focus]}"
    eval ${handlers[$focus]} $focus $action
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
  echo -en "$(Mode reset cursor)"
  if (( $action == -3 && _io == 0 )); then
    echo -en "${selection[$focus]}`Foreground yellow`YAYA"
    _io=1
  fi
  return 0
}

Resize(){
  local win_h=$1
  local win_w=$2
  local win_code

  if [[ -n $win_h && -n $win_w ]]; then
    win_code="\e[8;$win_h;$win_w;t\e[1;$win_h;r"
    echo $win_code
  else
    local pos
    printf "\e[13t" > /dev/tty
    IFS=';' read -r -d t -a pos

    local xpos=${pos[1]}
    local ypos=${pos[2]}

    printf "\e[14;2t" > /dev/tty
    IFS=';' read -r -d t -a size

    local hsize=${size[1]}
    local wsize=${size[2]}

    win_code="\e[8;$hsize;$wsize;t\e[1;$win_h;"
    echo $win_code
  fi
}

Setup(){
  echo -e $(Resize $ROWS $COLS)
  Render
  echo -e $(Focus 0 0)
  echo -en $(Mode reset cursor)
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
  Form $SAMPLE_INPUT $FORM_FOCUS_COLOR $FORM_FONT_FOCUS_COLOR 1

  for c in ${!content[@]}; do
    focused[$c]=${content[$c]}
  done
  Form $SAMPLE_INPUT $FORM_COLOR $FORM_FONT_COLOR
  # content=($(Form $fields $FORM_COLOR $FORM_FONT_COLOR))
  # focused=($(Form $fields $FORM_FOCUS_COLOR $FORM_FONT_FOCUS_COLOR))
  # git add -A . | git commit -m <comment> | git push
  # git checkout {branch;git branch} | git push {$branch}
  Guard
  stty raw min 0 time 0
}

Spin(){

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
      Render
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
  local fg=$(Foreground $FG_COLOR)
  local bg=$(Background $BG_COLOR)
  local blur=0
  local focus=-1
  local action=-1
  local input=""
  local buffer=""
  local string=""
  

  declare -a focused=()
  declare -a content=()
  declare -a selection=()
  declare -f handlers=()
  local _io=0

  Spawn
  Setup
  Spin
  Stop
}


# RUN
###########
trap 'Stop' HUP INT QUIT TERM
Core
