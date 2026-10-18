from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = (ROOT / '.github/workflows/sonarqube.yml').read_text()
PROPERTIES = (ROOT / 'sonar-project.properties').read_text()


class SonarQubeWorkflowTest(unittest.TestCase):
    def test_scan_runs_after_tests_on_main_and_pull_requests(self):
        self.assertRegex(WORKFLOW, r'(?m)^  push:\n    branches: \[main\]$')
        self.assertRegex(WORKFLOW, r'(?m)^  pull_request:\n    types: \[opened, synchronize, reopened\]$')
        self.assertIn('needs: [test, lint]', WORKFLOW)
        self.assertIn("github.event.pull_request.head.repo.full_name == github.repository", WORKFLOW)
        self.assertIn("github.actor != 'dependabot[bot]'", WORKFLOW)
        for command in (
            'bash install/tests/claude-profiles.test.sh',
            'node install/tests/plan-manager-harness-contracts.test.mjs',
            'python3 install/tests/sonarqube-workflow.test.py',
        ):
            self.assertIn(command, WORKFLOW)

    def test_scan_uses_cloud_project_settings(self):
        self.assertRegex(WORKFLOW, r'(?m)^permissions:\n  contents: read$')
        self.assertIn('fetch-depth: 0', WORKFLOW)
        self.assertRegex(WORKFLOW, r'SonarSource/sonarqube-scan-action@[0-9a-f]{40} # v\d+\.\d+\.\d+')
        self.assertIn('SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}', WORKFLOW)
        self.assertIn('-Dsonar.organization=${{ vars.SONAR_ORGANIZATION }}', WORKFLOW)
        self.assertIn('-Dsonar.projectKey=hacker1db_Dotfiles', WORKFLOW)
        self.assertIn('sonar.sources=.\n', PROPERTIES)
        self.assertIn('sonar.tests=install/tests\n', PROPERTIES)
        self.assertIn('sonar.test.inclusions=install/tests/**\n', PROPERTIES)

    def test_lint_checks_shell_zsh_and_lua(self):
        self.assertIn("'*.sh' '*.bash' ':(exclude)bin/dotnet-install.sh' | xargs -0 shellcheck -S error", WORKFLOW)
        self.assertIn('zsh -n "$file"', WORKFLOW)
        self.assertRegex(WORKFLOW, r'lunarmodules/luacheck@[0-9a-f]{40} # v1\.2\.0')

    def test_actions_are_pinned_to_commit_shas(self):
        import re
        for ref in re.findall(r'uses: (\S+)', WORKFLOW):
            self.assertRegex(ref, r'@[0-9a-f]{40}$')


if __name__ == '__main__':
    unittest.main()
