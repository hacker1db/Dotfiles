// Command machine-id prints this machine's fleet identity: `machine-id [label|color]`.
//
// Fleet hosts are inventoried in fleet-manager (fleet.json); any other machine is the
// work machine, which keeps the theme's standard accent (empty color).
package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

type identity struct{ label, color string }

func identify(name string) identity {
	switch name = strings.ToLower(name); {
	case strings.HasPrefix(name, "stronghold"):
		return identity{"STRONGHOLD", "#f16c75"} // Eldritch red
	case strings.HasPrefix(name, "aiserver"):
		return identity{"AISERVER", "#f7c67f"} // Eldritch orange
	}
	return identity{"WORK", ""}
}

// machineName prefers the macOS LocalHostName because hostname is "MacBookPro" on every Mac.
func machineName(localHostName, hostname func() (string, error)) string {
	if name, err := localHostName(); err == nil && strings.TrimSpace(name) != "" {
		return strings.TrimSpace(name)
	}
	name, _ := hostname()
	return strings.Split(name, ".")[0]
}

func render(id identity, field string) (string, error) {
	switch field {
	case "":
		return strings.TrimSpace(id.label + " " + id.color), nil
	case "label":
		return id.label, nil
	case "color":
		return id.color, nil
	}
	return "", fmt.Errorf("usage: machine-id [label|color]")
}

func scutilLocalHostName() (string, error) {
	out, err := exec.Command("scutil", "--get", "LocalHostName").Output()
	return string(out), err
}

func main() {
	field := ""
	if len(os.Args) > 1 {
		field = os.Args[1]
	}
	out, err := render(identify(machineName(scutilLocalHostName, os.Hostname)), field)
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}
	fmt.Println(out)
}
