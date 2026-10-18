package main

import (
	"slices"
	"testing"
)

func TestSSHArgs(t *testing.T) {
	got, err := sshArgs([]string{"aiserver"})
	want := []string{"ssh", "-t", "aiserver", "exec $SHELL -lc 'tmux new-session -A -s main'"}
	if err != nil || !slices.Equal(got, want) {
		t.Fatalf("default session: %q, %v", got, err)
	}
	if got, _ := sshArgs([]string{"stronghold", "ai"}); got[3] != "exec $SHELL -lc 'tmux new-session -A -s ai'" {
		t.Fatalf("named session: %q", got)
	}
}

func TestSSHArgsRejectsUnsafeInput(t *testing.T) {
	for _, args := range [][]string{
		{},
		{"a", "b", "c"},
		{"-oProxyCommand=evil"},
		{"aiserver", "x'; rm -rf ~; '"},
		{"aiserver", "$(id)"},
		{"aiserver", ""},
	} {
		if _, err := sshArgs(args); err == nil {
			t.Errorf("sshArgs(%q) accepted", args)
		}
	}
}
