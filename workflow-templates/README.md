# Workflow Templates

These templates are shared starting points for `vexcalibur-dev` repositories.
They are intentionally scoped. GitHub `filePatterns` only control when a
template is offered based on matching root files; they do not prove all
prerequisites are present. Review the prerequisites before applying a template.

## Python Poetry CI

Use `python-ci.yml` for Python packages that have:

- `.python-version` with a GitHub Actions-supported Python version.
- `pyproject.toml` and `poetry.lock`.
- source code under `src/`.
- tests under `tests/`.
- Poetry-managed commands for `ruff`, `mypy`, `pytest`, and package builds.
- Poetry-managed development dependencies for `pip-audit` and
  `detect-secrets`.
- a committed `.secrets.baseline` created with
  `detect-secrets scan > .secrets.baseline`.

The template runs package metadata checks, lock-file checks, formatting, linting,
type checking, dependency audit, secret scanning, tests, and wheel/sdist builds.
Repositories with different test paths, no package build, no `src/` layout, no
secret baseline, or tools other than Poetry should copy and adapt the workflow
instead of selecting the template unchanged.

The secret scan uses `detect-secrets-hook` over tracked files so newly
introduced secrets fail CI. Pull requests are checked against the base branch's
committed `.secrets.baseline`, which prevents a PR from suppressing a new secret
by updating the baseline in the same change. Push and manual runs use the
current checkout's `.secrets.baseline`. Use
`detect-secrets scan --baseline .secrets.baseline` only when intentionally
refreshing the baseline in a separate reviewed maintenance change.

The Poetry bootstrap install is pinned with `POETRY_VERSION`. Update that value
intentionally when adopting a newer Poetry release instead of floating the CI
bootstrap tool at install time.

The metadata uses `poetry.lock` as a coarse availability hint so the template is
offered mainly to Poetry repositories. It is not a full compatibility check.

## Python Security Analysis

Use `security-analysis.yml` for Python repositories where Dependency Review,
CodeQL, and OpenSSF Scorecard should run. The repository must allow GitHub
Actions to write security events. Public repositories should also enable GitHub
private vulnerability reporting, Dependabot security updates, secret scanning,
and push protection.

The Dependency Review job only runs on pull requests and requires the dependency
graph to be enabled. GitHub supports the dependency review action for public
repositories and for private repositories with GitHub Code Security or GitHub
Advanced Security enabled. CodeQL and OpenSSF Scorecard run on pull requests,
pushes, schedules, and manual dispatch. The template does not replace
repository-specific release gates.

Dependency Review PR comments are disabled in the shared template so fork and
Dependabot pull requests can run with a read-only `GITHUB_TOKEN`. Repositories
that want PR comments can opt in locally by changing `comment-summary-in-pr` and
granting `pull-requests: write`; those runs may still be limited by GitHub's
fork and Dependabot token rules.

The metadata uses `pyproject.toml` as a coarse availability hint for Python
repositories. It is not a full compatibility check.

## Dependabot Guidance

Add a repository-local `.github/dependabot.yml`; GitHub does not apply one from
this defaults repository. For a Poetry-based Python package with pinned GitHub
Actions, use this as a starting point:

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

Adjust schedules and grouping for each repository's maintenance window.

## Validation

The repository's `Validate Repository Metadata` workflow runs YAML/JSON checks,
rendered-template `actionlint`, a GitHub API content-read smoke check, and a
minimal Poetry fixture smoke test for the Python security commands. Before
changing these templates, also validate the files from this repository root:

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

Run `actionlint` against rendered copies of workflow templates because GitHub
template placeholders such as `$default-branch` are not valid workflow syntax
outside the template renderer.

```bash
tmpdir="$(mktemp -d)"
cp workflow-templates/*.yml "$tmpdir"/
perl -0pi -e 's/\[\$default-branch\]/[main]/g' "$tmpdir"/*.yml
ASDF_ACTIONLINT_VERSION=1.7.12 actionlint .github/workflows/*.yml "$tmpdir"/*.yml
```
