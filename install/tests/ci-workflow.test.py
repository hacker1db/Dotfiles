from pathlib import Path
import re
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / '.github/workflows'
CI = (WORKFLOWS / 'ci.yml').read_text()
CODEQL = (WORKFLOWS / 'codeql.yml').read_text()
DEPENDABOT = (ROOT / '.github/dependabot.yml').read_text()


class CiWorkflowTest(unittest.TestCase):
    def test_tests_run_on_main_and_pull_requests(self):
        self.assertRegex(CI, r'(?m)^  push:\n    branches: \[main\]$')
        self.assertRegex(CI, r'(?m)^  pull_request:\n    types: \[opened, synchronize, reopened\]$')
        self.assertRegex(CI, r'(?m)^permissions:\n  contents: read$')
        for command in (
            'bash install/tests/claude-profiles.test.sh',
            'bash install/tests/opencode-config.test.sh',
            'node install/tests/plan-manager-harness-contracts.test.mjs',
            'python3 install/tests/ci-workflow.test.py',
        ):
            self.assertIn(command, CI)

    def test_lint_checks_shell_zsh_and_lua(self):
        self.assertIn("'*.sh' '*.bash' ':(exclude)bin/dotnet-install.sh' | xargs -0 shellcheck -S error", CI)
        self.assertIn('zsh -n "$file"', CI)
        self.assertRegex(CI, r'lunarmodules/luacheck@[0-9a-f]{40} # v1\.2\.0')

    def test_pull_requests_fail_on_any_vulnerable_dependency(self):
        self.assertIn("if: github.event_name == 'pull_request'", CI)
        self.assertRegex(CI, r'actions/dependency-review-action@[0-9a-f]{40} # v\d+\.\d+\.\d+')
        self.assertIn('fail-on-severity: low', CI)

    def test_codeql_scans_every_supported_language(self):
        self.assertIn('security-events: write', CODEQL)
        self.assertIn('language: [actions, javascript-typescript, python]', CODEQL)
        self.assertIn('queries: security-extended', CODEQL)
        self.assertIn('schedule:', CODEQL)
        self.assertRegex(CODEQL, r'github/codeql-action/init@[0-9a-f]{40} # v\d+\.\d+\.\d+')
        self.assertRegex(CODEQL, r'github/codeql-action/analyze@[0-9a-f]{40} # v\d+\.\d+\.\d+')

    def test_dependabot_tracks_actions_and_npm(self):
        self.assertIn('package-ecosystem: "github-actions"', DEPENDABOT)
        self.assertIn('directory: "/claude/drawio-scripts"', DEPENDABOT)

    def test_actions_are_pinned_to_commit_shas(self):
        for workflow in WORKFLOWS.glob('*.yml'):
            for ref in re.findall(r'uses: (\S+)', workflow.read_text()):
                self.assertRegex(ref, r'@[0-9a-f]{40}$', f'{workflow.name}: {ref}')

    def test_sonarqube_is_not_used(self):
        self.assertFalse((ROOT / 'sonar-project.properties').exists())
        for workflow in WORKFLOWS.glob('*.yml'):
            self.assertNotIn('sonar', workflow.read_text().lower(), workflow.name)


if __name__ == '__main__':
    unittest.main()
