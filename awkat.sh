#!/bin/sh
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

[ -z "$AWKAT_COLS" ] && { clnms="$(tput cols)"; } || { clnms="$AWKAT_COLS"; }

is_num() {
    # usage: is_num "value"
    printf %d "$1" >/dev/null 2>&1
}

while getopts "c:" opt; do case "${opt}" in
    c)
        if is_num "$OPTARG"; then
            clnms="$OPTARG"
        else
            printf '%s: argument for -%s "%s" is not a number\n' "${0##*/}" "$opt" "$OPTARG" >&2
            exit 1
        fi
    ;;
    *) printf '%s: invalid option %s\n' "${0##*/}" "$opt" >&2 ; exit 1 ;;
esac done
shift $(( OPTIND -1 ))

crop=$(( clnms - 9 ))

awkcmd() {
    awk -v file="$*" -v Col="$clnms" '
    BEGIN { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┬";
            for(c=0;c<Col-8;c++) printf"─"; print"\033[0m" }
    BEGIN { printf "\x1b[30;1m%6s │\x1b[0m \x1b[32;1m %s \x1b[0m \n", "file", file };
    BEGIN { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┼";
            for(c=0;c<Col-8;c++) printf"─"; print"\033[0m" }
          { printf "\x1b[30;1m%6d │\x1b[0m %s\n", NR, $0 };
    END   { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┴";
            for(c=0;c<Col-8;c++) printf"─"; print"\033[0m" }
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

if [ -z "$pipearg" ]; then
    if [ "$#" -gt 1 ]; then
        /bin/cat "$@" | colrm "$crop" | awkcmd "$@"
    else
        $HIGHLIGHTER "$1" | colrm "$crop" | awkcmd "$@"
    fi
else
    $HIGHLIGHTER "$tmpfile" | colrm "$crop" | awkcmd "${0##*/}-pipe $$"
fi
