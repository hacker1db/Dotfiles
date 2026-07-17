#!/bin/sh

EXIT_CODE=0

hook_type=$(basename "$0")
hooks="$HOME/.dotfiles/git/hooks"

echo "Executing $hook_type hook(s)"

for hook in "$hooks"/*."$hook_type"; do
	[ -e "$hook" ] || continue

	echo ""
	echo "Executing $hook"
	"$hook" "$@"
	hook_exit_code=$?
	if [ "$hook_exit_code" -ne 0 ]; then
		EXIT_CODE=$hook_exit_code
	fi
done

if [ "$EXIT_CODE" -ne 0 ]; then
	echo ""
	echo "$hook_type hook failed."
fi

exit "$EXIT_CODE"
