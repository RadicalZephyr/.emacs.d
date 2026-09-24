#!/bin/sh
# Tests for personal/bin/in-container.  Needs a running distrobox.
#
# Run with:
#   ~/.emacs.d/personal/test/in-container-test.sh [box] [other-box]
#
# BOX defaults to dev.  The different-box case runs only when OTHER-BOX
# names a second running distrobox.

box=${1:-dev}
other=$2
script=$(cd "$(dirname "$0")/../bin" && pwd)/in-container
# Under $HOME: distrobox mounts it at the same path, unlike /tmp.
mkdir -p "$HOME/.cache"
root=$(mktemp -d "$HOME/.cache/in-container-test.XXXXXX")
shims=$root/$box
mkdir "$shims"
for tool in cat sh sleep; do
	ln -s "$script" "$shims/$tool"
done
trap 'rm -rf "$root"' EXIT

failures=0
pass() { printf 'ok   %s\n' "$1"; }
fail() {
	printf 'FAIL %s: %s\n' "$1" "$2"
	failures=$((failures + 1))
}

# Wait up to 5s for no process to match PATTERN.
gone() {
	for _ in 1 2 3 4 5 6 7 8 9 10; do
		pgrep -f "$1" >/dev/null || return 0
		sleep 0.5
	done
	pkill -f "$1"
	return 1
}

name="stdin reaches the tool"
out=$(printf 'hello\n' | "$shims/cat")
[ "$out" = hello ] && pass "$name" || fail "$name" "got '$out'"

name="exit status comes back"
"$shims/sh" -c 'exit 3'
status=$?
[ $status -eq 3 ] && pass "$name" || fail "$name" "got $status"

name="runs in the box"
out=$("$shims/sh" -c 'echo "$CONTAINER_ID"')
[ "$out" = "$box" ] && pass "$name" || fail "$name" "got '$out'"

name="runs in the working directory"
out=$(cd "$root" && "$shims/sh" -c pwd)
[ "$out" = "$root" ] && pass "$name" || fail "$name" "got '$out'"

name="shims are off PATH in the box"
out=$(PATH=$shims:$PATH "$shims/sh" -c 'echo "$PATH"')
case :$out: in
*":$shims:"*) fail "$name" "PATH=$out" ;;
*) pass "$name" ;;
esac

name="clean exit doesn't wait for the watchdog"
start=$(date +%s%N)
"$shims/sh" -c true
elapsed=$((($(date +%s%N) - start) / 1000000))
[ $elapsed -lt 900 ] && pass "$name" || fail "$name" "${elapsed}ms"

for signal in KILL INT TERM; do
	name="SIG$signal to the client kills the tool"
	marker=$((7000 + $$ % 1000))$signal
	"$shims/sh" -c "sleep 60; : $marker" &
	client=$!
	sleep 2
	if ! pgrep -f "sleep 60; : $marker" >/dev/null; then
		fail "$name" "tool never started"
	else
		kill -"$signal" $client
		gone "sleep 60; : $marker" && pass "$name" || fail "$name" "still running"
	fi
done

name="children of the tool die too"
marker=$((8000 + $$ % 1000))
"$shims/sh" -c "sleep 60 & sleep 61; : $marker" &
client=$!
sleep 2
kill -KILL $client
gone "sleep 60$" && gone "sleep 61; : $marker" && pass "$name" || fail "$name" "still running"

name="in the same box, runs the tool directly"
out=$(podman exec --user "$USER" -e PATH="$shims:/usr/bin:/bin" "$box" \
	"$shims/sh" -c 'echo "$CONTAINER_ID $PATH"')
[ "$out" = "$box /usr/bin:/bin" ] && pass "$name" || fail "$name" "got '$out'"

if [ -n "$other" ]; then
	name="in another box, goes through the host"
	out=$(podman exec --user "$USER" "$other" "$shims/sh" -c 'echo "$CONTAINER_ID"')
	[ "$out" = "$box" ] && pass "$name" || fail "$name" "got '$out'"
else
	printf 'skip in another box, goes through the host (no OTHER-BOX)\n'
fi

[ $failures -eq 0 ] && echo "all passed" || echo "$failures failed"
[ $failures -eq 0 ]
