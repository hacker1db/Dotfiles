package main

import (
	"errors"
	"testing"
)

func TestIdentify(t *testing.T) {
	for name, want := range map[string]identity{
		"stronghold-2":  {"STRONGHOLD", "#f16c75"},
		"Stronghold":    {"STRONGHOLD", "#f16c75"},
		"aiserver":      {"AISERVER", "#f7c67f"},
		"MacBookPro":    {"WORK", ""},
		"Corp-MBP-1234": {"WORK", ""},
		"":              {"WORK", ""},
	} {
		if got := identify(name); got != want {
			t.Errorf("identify(%q) = %v, want %v", name, got, want)
		}
	}
}

func TestMachineName(t *testing.T) {
	ok := func(s string) func() (string, error) { return func() (string, error) { return s, nil } }
	fail := func() (string, error) { return "", errors.New("no scutil") }
	if got := machineName(ok("stronghold-2\n"), ok("MacBookPro")); got != "stronghold-2" {
		t.Errorf("macOS: got %q", got)
	}
	if got := machineName(fail, ok("aiserver.lan")); got != "aiserver" {
		t.Errorf("linux: got %q", got)
	}
	if got := machineName(ok("  "), ok("MacBookPro.local")); got != "MacBookPro" {
		t.Errorf("blank LocalHostName: got %q", got)
	}
}

func TestRender(t *testing.T) {
	id := identity{"STRONGHOLD", "#f16c75"}
	for field, want := range map[string]string{"": "STRONGHOLD #f16c75", "label": "STRONGHOLD", "color": "#f16c75"} {
		if got, err := render(id, field); err != nil || got != want {
			t.Errorf("render(%q) = %q, %v", field, got, err)
		}
	}
	if got, _ := render(identity{"WORK", ""}, ""); got != "WORK" {
		t.Errorf("work default: got %q", got)
	}
	if _, err := render(id, "bogus"); err == nil {
		t.Error("unknown field accepted")
	}
}
