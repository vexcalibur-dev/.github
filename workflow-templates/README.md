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
- GitHub Actions can write security events for CodeQL and Static Analysis
  Results Interchange Format (SARIF) uploads.
- The dependency graph is enabled.
- The repository is public, or its GitHub plan enables the required code-security features.

The dependency review action is available to public repositories. Private repositories need GitHub Code Security or GitHub Advanced Security. Confirm current availability in the [GitHub dependency review documentation](https://docs.github.com/en/code-security/concepts/supply-chain-security/dependency-review).

### Checks and events

| Job | Events | Behavior |
| --- | --- | --- |
| `dependency-review` | Pull requests | Fails when a dependency change introduces a vulnerability rated high or critical; PR comments are disabled |
| `codeql` | Pull requests, pushes, weekly schedule, manual runs | Analyzes Python with the `security-and-quality` query suite and uploads results |
| `scorecard` | Pushes and weekly schedule | Runs OpenSSF Scorecard and uploads `scorecard.sarif`; public Scorecard result publishing is disabled |

The schedule runs each Monday at 08:41 UTC.

PR comments stay disabled so the dependency review job only needs `contents: read`. If a repository enables comments in its copy, set `comment-summary-in-pr` as needed and add `pull-requests: write`. Fork and Dependabot pull requests can still receive reduced token permissions.

Public Scorecard API publication is disabled, so the Scorecard job does not request an OpenID Connect token. It retains only the read permissions needed to inspect repository signals and `security-events: write` for the repository's SARIF upload.

The template does not enable repository settings. After adding it, confirm the dependency graph, code scanning, private vulnerability reporting, Dependabot security updates, secret scanning, and push protection that apply to the repository.

## Add Renovate updates

Each project needs its own `renovate.json`; Renovate reads the configuration from that project's default branch. The shared repository does not supply an inherited configuration.

### Prerequisites

Give Renovate access to the repository, then confirm that the dependency graph,
Dependabot alerts, and Dependabot security updates are enabled. The policy below
deliberately leaves auto-merge disabled. If you later enable it, first protect
the default branch with every CI check that must gate dependency updates. Then
confirm that a pull request with a failing required check cannot auto-merge.

Renovate updates workflow and action metadata, including this repository's `workflow-templates/` files. It keeps each action on a full commit SHA and updates the adjacent version comment with it. It creates ordinary update branches on Monday mornings in `America/Chicago`; `config:recommended` may group related dependencies. For ordinary updates, Renovate creates at most two pull requests an hour and keeps at most five open. Dependabot remains responsible for vulnerability-fix pull requests, so the policy disables Renovate vulnerability alerts. Every Renovate update remains an ordinary pull request for review.

Renovate waits five days before it creates a branch for a normal dependency
update. It requires a registry release timestamp, and a release without a
trusted timestamp stays pending. Security fixes are not delayed; Dependabot
opens those pull requests as soon as it identifies them.

The `enabledManagers` list is deliberate. Add a manager only after the
repository has checks that exercise its updates. It decides which dependency
types Renovate may update.

When migrating from Dependabot version updates, merge the Renovate configuration
first. Then close the remaining Dependabot version-update pull requests without
merging them before Renovate's first scheduled window. Keep Dependabot alerts
and security updates enabled; the configuration below disables only Renovate's
duplicate vulnerability updates.

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": [
    "config:recommended",
    "helpers:pinGitHubActionDigests"
  ],
  "timezone": "America/Chicago",
  "schedule": ["* 8-11 * * 1"],
  "labels": ["dependencies"],
  "prConcurrentLimit": 5,
  "prHourlyLimit": 2,
  "minimumReleaseAge": "5 days",
  "minimumReleaseAgeBehaviour": "timestamp-required",
  "internalChecksFilter": "strict",
  "enabledManagers": ["github-actions"],
  "vulnerabilityAlerts": {
    "enabled": false
  },
  "packageRules": [
    {
      "description": "Group reviewable GitHub Actions updates.",
      "matchManagers": ["github-actions"],
      "groupName": "GitHub Actions"
    }
  ]
}
```

For a Renovate configuration change, open the pull request from a branch named
`renovate/reconfigure` in the repository where Renovate is installed. Renovate
does not validate branches in forks. Fork-based contributors should ask a
maintainer to push the branch to the source repository before relying on the
`renovate/config-validation` check. Merge only after it and the repository's
other required checks pass.

## Validate template changes

Run these checks from the `.github` repository root in Bash. You need Ruby
with its `json` and `yaml` standard libraries, Perl, Go, and network access
to the Go module proxy unless the Actionlint module is already cached.

Run the repository metadata and security-policy validator:

```bash
ruby .github/scripts/validate-repository-metadata-test.rb
ruby .github/scripts/validate-repository-metadata.rb
```

The validator parses every YAML and JSON metadata file, requires full commit-SHA pins for remote GitHub Actions, and fails closed if the repository-level Scorecard, Renovate, or code-ownership policy drifts from its reviewed boundary.

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
