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

crop=$(( clnms - 9 ))

awkcmd() {
    awk -v file="$*" -v Col="$clnms" '
    BEGIN { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┬"; for(c=0;c<Col-8;c++) printf"─"; print"\033[0m" }
    BEGIN { printf "\x1b[30;1m%6s │\x1b[0m \x1b[32;1m %s \x1b[0m \n", "file", file };
    BEGIN { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┼"; for(c=0;c<Col-8;c++) printf"─"; print"\033[0m" }
          { printf "\x1b[30;1m%6d │\x1b[0m %s\n", NR, $0 };
    END { printf "\033[30;1m"; for(c=0;c<7;c++) printf"─"; printf"┴"; for(c=0;c<Col-8;c++) printf"─"; print"\033[0m" }
    '
}

if [ "$#" -gt 1 ]; then
    /bin/cat "$@" | colrm "$crop" | awkcmd "$@"
else
    colrm "$crop" < "$1" | $HIGHLIGHTER | awkcmd "$@"
fi
