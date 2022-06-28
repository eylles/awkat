#!/bin/sh
echo () { printf %s\\n "$*" ; }
check_cmd(){
    if command -v "$1" >/dev/null; then
        echo "$1"
    fi
}

[ -z "$HIGHLIGHTER" ] && HIGHLIGHTER="$(check_cmd highlight)"
[ -z "$HIGHLIGHTER" ] && HIGHLIGHTER="$(check_cmd source-highlight)"
[ -z "$HIGHLIGHTER" ] && { echo "dependencies unmet, install a highlighter program or set the env var HIGHLIGHTER"; exit 1; }
case "$HIGHLIGHTER" in
    *source-highlight) HIGHLIGHTER="${HIGHLIGHTER} -f esc -i" ;;
    *highlight) HIGHLIGHTER="${HIGHLIGHTER} -O ansi --force" ;;
esac

awkcmd() {
awk -v file="$*" '
    BEGIN { print  "\x1b[30;1m───────┬────────────────────────────────────────────────────────────────────────\x1b[0m" };
    BEGIN { printf "\x1b[30;1m%6s │\x1b[0m \x1b[32;1m %s \x1b[0m \n", "file", file };
    BEGIN { print  "\x1b[30;1m───────┼────────────────────────────────────────────────────────────────────────\x1b[0m" };
          { printf "\x1b[30;1m%6d │\x1b[0m %s\n", NR, $0 };
    END   { print  "\x1b[30;1m───────┴────────────────────────────────────────────────────────────────────────\x1b[0m" };
    '
}

if [ "$#" -gt 1 ]; then
    /bin/cat "$@" | awkcmd "$@"
else
    $HIGHLIGHTER "$1" | awkcmd "$@"
fi
