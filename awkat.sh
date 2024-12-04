#!/bin/sh

myname=${0##*/}

# usage: check_cmd command
#     returns the command if it exists
check_cmd(){
    [ "$(command -v "$1" 2>/dev/null)" ] && printf '%s\n' "$1"
}

no_hl_err="no HIGHLIGHTER found, install a highlighter program or set the env var HIGHLIGHTER"
[ -z "$HIGHLIGHTER" ] && HIGHLIGHTER="$(check_cmd highlight)"
[ -z "$HIGHLIGHTER" ] && HIGHLIGHTER="$(check_cmd source-highlight)"
[ -z "$HIGHLIGHTER" ] && { printf '%s\n' "$no_hl_err" >&2 ; exit 1; }
case "$HIGHLIGHTER" in
    *source-highlight) HIGHLIGHTER="${HIGHLIGHTER} -f esc -i" ;;
    *highlight) HIGHLIGHTER="${HIGHLIGHTER} -O ansi --force" ;;
esac

#the columns on the left of the printable area
margin=9

# if ran as a preview for fzf use the fzf previe columns
[ -z "$FZF_PREVIEW_COLUMNS" ] || AWKAT_COLS="$FZF_PREVIEW_COLUMNS"
if [ -z "$AWKAT_COLS" ]; then
    clnms=$(( $(tput cols) - margin ))
else
    clnms=$(( AWKAT_COLS - margin ))
fi

# usage: is_num "value"
is_num() {
    printf %d "$1" >/dev/null 2>&1
}

# usage: trim_iden "value"
#     will trim input to 6 chars
trim_iden() {
    printf '%.6s\n' "$1"
}

show_usage () {
    printf 'usage: %s [OPTION] [FILE]\n' "${myname}"
}

show_help () {
  printf '%s\n'   "${myname}: bat imitation with minimal dependencies"
  show_usage
  printf '\n%s\n' "Options:"
  printf '%s\n'   "-I S"
  printf '\t%s\n' "where 'S' is the identifier string."
  printf '%s\n'   "-c N"
  printf '\t%s\n' "where 'N' is the column width of the display area."
  printf '\t%s\n' "if not provided tput cols will be used to determine the display area"
  printf '\t%s\n' "when called from fzf the \$FZF_PREVIEW_COLUMNS variable is used instead."
  printf '%s\n'   "-h"
  printf '\t%s\n' "show this message"
  printf '\n%s\n' "Hihghlighting:"
  printf '\t%s\n' "by default the script will try to use either 'highlight' or 'source-highlight'"
  printf '\t%s\n' "to use a different highlighter you have to set or export the \$HIGHLIGHTER"
  printf '\t%s\n' "variable with your code highlighter of choice and the necessary flags so that it"
  printf '\t%s\n' "will output in ANSI escape sequences."
}

while getopts "c:I:h" opt; do case "${opt}" in
    c)
        if is_num "$OPTARG"; then
            clnms=$(( OPTARG - margin ))
        else
            printf '%s: argument for -%s "%s" is not a number\n' "${myname}" "$opt" "$OPTARG" >&2
            exit 1
        fi
    ;;
    I) ident=$(trim_iden "$OPTARG") ;;
    h) show_help ; exit 0 ;;
    *)
        printf '%s: invalid option %s\n' "${myname}" "$opt" >&2
        show_usage
        exit 1
        ;;
esac done
shift $(( OPTIND -1 ))

awkcmd() {
    iD="$1"
    shift 1
    awk -v iden="$iD" -v file="$*" -v Col="$clnms" '
    BEGIN { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┬";
            for(c=0;c<Col+1;c++) printf"─"; print"\033[0m" }
    BEGIN { printf "\x1b[30;1m%6s │\x1b[0m \x1b[32;1m %s \x1b[0m \n", iden, file };
    BEGIN { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┼";
            for(c=0;c<Col+1;c++) printf"─"; print"\033[0m" }
          { printf "\x1b[30;1m%6d │\x1b[0m %s\n", NR, $0 };
    END   { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┴";
            for(c=0;c<Col+1;c++) printf"─"; print"\033[0m" }
    '
}

tmpfile="${TMPDIR:-/tmp}/${myname}_pipe_$$"
trap 'rm -f -- $tmpfile' EXIT

if [ "$#" -eq 0 ]; then
    if [ -t 0 ]; then
        echo "${myname}: No FILE arguments provided" >&2; exit 1
    else
        # Consume stdin and put it in the temporal file
        cat > "$tmpfile"
        pipearg=1
    fi
fi

for arg in "$@"; do
    # if it's a pipe then drain it to $tmpfile
    [ -p "$arg" ] && { pipearg=1; cat "$arg" > "$tmpfile"; };
done

if [ -z "$pipearg" ]; then
    if [ "$#" -gt 1 ]; then
        [ -z "$ident" ] && ident="File"
        /bin/cat "$@" | fold -s -w "$clnms" | awkcmd "$ident" "$@"
    else
        [ -z "$ident" ] && ident="File"
        fold -s -w "$clnms" "$1" | $HIGHLIGHTER | awkcmd "$ident" "$@"
    fi
else
    [ -z "$ident" ] && ident="Pipe"
    fold -s -w "$clnms" "$tmpfile" | $HIGHLIGHTER | awkcmd "$ident" "${myname}-pipe $$"
fi
