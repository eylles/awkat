#!/bin/sh

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
[ -z "$AWKAT_COLS" ] && { clnms=$(( $(tput cols) -margin )); } || { clnms=$(( AWKAT_COLS -margin )); }

# usage: is_num "value"
is_num() {
    printf %d "$1" >/dev/null 2>&1
}

# usage: trim_iden "value"
#     will trim input to 6 chars
trim_iden() {
    printf '%.6s\n' "$1"
}

_help () {
    printf 'usage: %s [OPTION] [FILE]\n' "${0##*/}"
}

while getopts "c:I:fh" opt; do case "${opt}" in
    c)
        if is_num "$OPTARG"; then
            clnms=$(( OPTARG -margin ))
        else
            printf '%s: argument for -%s "%s" is not a number\n' "${0##*/}" "$opt" "$OPTARG" >&2
            exit 1
        fi
    ;;
    I) ident=$(trim_iden "$OPTARG") ;;
    f) Folding=1 ;;
    h) _help ; exit 0 ;;
    *) printf '%s: invalid option %s\n' "${0##*/}" "$opt" >&2 ; exit 1 ;;
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

tmpfile="${TMPDIR:-/tmp}/${0##*/}_pipe_$$"
trap 'rm -f -- $tmpfile' EXIT

if [ "$#" -eq 0 ]; then
    if [ -t 0 ]; then
        echo "${0##*/}: No FILE arguments provided" >&2; exit 1
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

# constraining method: one of 2 according to -f option
#     default remove: colrm
#     -f      fold:   fold -s -w
constrainer=""
if [ -z "$Folding" ]; then
    constrainer='colrm'
else
    constrainer='fold -s -w'
fi

if [ -z "$pipearg" ]; then
    if [ "$#" -gt 1 ]; then
        [ -z "$ident" ] && ident="File"
        /bin/cat "$@" | $constrainer "$clnms" | awkcmd "$ident" "$@"
    else
        [ -z "$ident" ] && ident="File"
        $HIGHLIGHTER "$1" | $constrainer "$clnms" | awkcmd "$ident" "$@"
    fi
else
    [ -z "$ident" ] && ident="Pipe"
    $HIGHLIGHTER "$tmpfile" | $constrainer "$clnms" | awkcmd "$ident" "${0##*/}-pipe $$"
fi
