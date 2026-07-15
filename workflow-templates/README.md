# Workflow templates

These templates appear on the **Actions** > **New workflow** page for repositories in the `vexcalibur-dev` organization. GitHub copies the selected file into the repository. From that point on, the repository owns its copy and changes here do not flow into it.

The metadata `filePatterns` are suggestion filters, not compatibility checks. Check every prerequisite before you select a template.

## Choose a template

| Template | Use it when | GitHub suggests it when |
| --- | --- | --- |
| `python-ci.yml` | A Poetry package uses the required layout and quality tools | `poetry.lock` exists at the repository root |
| `security-analysis.yml` | A Python repository can run Dependency Review, CodeQL, and OpenSSF Scorecard | `pyproject.toml` exists at the repository root |

You can use both templates in one repository. Neither replaces release checks or project-specific tests.

## Python Poetry CI

### Poetry CI prerequisites

Use `python-ci.yml` unchanged only when the repository has all of the following:

- A `.python-version` file containing a version supported by GitHub Actions.
- `pyproject.toml` and `poetry.lock` at the root.
- Importable package code under `src/`.
- Tests under `tests/`.
- Poetry-managed commands for Ruff, mypy, pytest, and package builds.
- Poetry development dependencies for `pip-audit` and `detect-secrets`.
- A committed `.secrets.baseline` created by `poetry run detect-secrets scan > .secrets.baseline`.

If the project uses different paths, another package manager, no distribution build, or a different test layout, adapt the copied workflow before you merge it.

### Checks

The workflow runs on pull requests and pushes to the default branch. It also supports manual runs.

| Job | Checks |
| --- | --- |
| `quality` | Package metadata, lock consistency, Ruff formatting and linting, mypy, dependency audit, secret scan, and pytest |
| `build` | Wheel and source-distribution build |

The workflow installs Poetry at the version in `POETRY_VERSION`. Update that value in a reviewed pull request; do not replace it with a floating install.

### Secret baseline behavior

Pull request runs fetch `.secrets.baseline` from the exact base commit and scan every tracked file against it. A pull request cannot hide a new secret by changing the baseline in the same branch.

Push and manual runs use the baseline from the checked-out commit. When a legitimate change requires a baseline update, run this command and submit the result as a separate maintenance change:

```bash
poetry run detect-secrets scan --baseline .secrets.baseline
```

Review every new baseline entry before you merge it. A baseline suppresses detection; it does not make the matched value safe to publish.

## Python security analysis

### Security analysis prerequisites

Use `security-analysis.yml` when all of these conditions hold:

- The repository contains Python that CodeQL should analyze.
- GitHub Actions can write security events for CodeQL and SARIF uploads.
- The dependency graph is enabled.
- The repository is public, or its GitHub plan enables the required code-security features.

The dependency review action is available to public repositories. Private repositories need GitHub Code Security or GitHub Advanced Security. Confirm current availability in the [GitHub dependency review documentation](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependency-review).

### Checks and events

| Job | Events | Behavior |
| --- | --- | --- |
| `dependency-review` | Pull requests | Fails when a dependency change introduces a vulnerability rated high or critical; PR comments are disabled |
| `codeql` | Pull requests, pushes, weekly schedule, manual runs | Analyzes Python with the `security-and-quality` query suite and uploads results |
| `scorecard` | Pull requests, pushes, weekly schedule, manual runs | Runs OpenSSF Scorecard and uploads `scorecard.sarif`; public Scorecard result publishing is disabled |

The schedule runs each Monday at 08:41 UTC.

PR comments stay disabled so the dependency review job only needs `contents: read`. If a repository enables comments in its copy, set `comment-summary-in-pr` as needed and add `pull-requests: write`. Fork and Dependabot pull requests can still receive reduced token permissions.

The template does not enable repository settings. After adding it, confirm the dependency graph, code scanning, private vulnerability reporting, Dependabot security updates, secret scanning, and push protection that apply to the repository.

## Add Dependabot updates

GitHub does not inherit `.github/dependabot.yml` from this repository. Add one to each project that needs version updates.

This example groups weekly Poetry and GitHub Actions updates. Change the schedule and grouping to fit the repository's maintenance window.

```yaml
version: 2
updates:
  - package-ecosystem: pip
    directory: /
    schedule:
      interval: weekly
      day: monday
      time: "09:00"
    groups:
      python-dependencies:
        patterns:
          - "*"

  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
      day: monday
      time: "09:30"
    groups:
      github-actions:
        patterns:
          - "*"
```

## Validate template changes

Run these checks from the `.github` repository root in Bash. You need Ruby with its `json` and `yaml` standard libraries, Perl, and Go.

Parse every YAML and JSON file:

```bash
ruby <<'RUBY'
require "json"
require "yaml"

(
  Dir[".github/ISSUE_TEMPLATE/*.yml"] +
  Dir[".github/workflows/*.yml"] +
  Dir["workflow-templates/*.yml"]
).sort.each do |path|
  YAML.safe_load_file(path, permitted_classes: [], permitted_symbols: [], aliases: false)
  puts "YAML OK #{path}"
end

Dir["workflow-templates/*.json"].sort.each do |path|
  JSON.parse(File.read(path))
  puts "JSON OK #{path}"
end
RUBY
```

Render `$default-branch` before running `actionlint`; the placeholder is valid only while GitHub creates a workflow from the template.

```bash
tmpdir="$(mktemp -d)"
cp workflow-templates/*.yml "$tmpdir"/
perl -0pi -e 's/\[\$default-branch\]/[main]/g' "$tmpdir"/*.yml
go run github.com/rhysd/actionlint/cmd/actionlint@v1.7.12 \
  .github/workflows/*.yml \
  "$tmpdir"/*.yml
rm -rf "$tmpdir"
```

The `Validate repository metadata` workflow adds a GitHub API content-read check and runs the Python security commands in a temporary Poetry package. Both jobs must pass before a template change is ready to merge.
