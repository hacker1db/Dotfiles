// Command fleet-login logs in to a fleet host and attaches its tmux session:
// `fleet-login <host> [session]`. Hosts are ~/.ssh/config aliases (stronghold, aiserver);
// the session defaults to "main".
package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"regexp"
	"syscall"
)

var safeName = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9_.@-]*$`)

// sshArgs builds the ssh arguments; names are validated because the session is spliced into a remote shell command.
func sshArgs(args []string) ([]string, error) {
	if len(args) < 1 || len(args) > 2 {
		return nil, errors.New("usage: fleet-login <stronghold|aiserver> [session]")
	}
	host, session := args[0], "main"
	if len(args) == 2 {
		session = args[1]
	}
	if !safeName.MatchString(host) || !safeName.MatchString(session) {
		return nil, fmt.Errorf("invalid host or session name: %q %q", host, session)
	}
	// A login shell puts Homebrew's tmux on PATH on macOS.
	return []string{"ssh", "-t", host, "exec $SHELL -lc 'tmux new-session -A -s " + session + "'"}, nil
}

func main() {
	args, err := sshArgs(os.Args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	ssh, err := exec.LookPath("ssh")
	if err == nil {
		err = syscall.Exec(ssh, args, os.Environ())
	}
	fmt.Fprintln(os.Stderr, "fleet-login:", err)
	os.Exit(1)
}
