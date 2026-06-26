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

The template runs package metadata checks, lock-file checks, formatting, linting,
type checking, tests, and wheel/sdist builds. Repositories with different test
paths, no package build, no `src/` layout, or tools other than Poetry should copy
and adapt the workflow instead of selecting the template unchanged.

The Poetry bootstrap install is pinned with `POETRY_VERSION`. Update that value
intentionally when adopting a newer Poetry release instead of floating the CI
bootstrap tool at install time.

The metadata uses `poetry.lock` as a coarse availability hint so the template is
offered mainly to Poetry repositories. It is not a full compatibility check.

## Python Security Analysis

Use `security-analysis.yml` for Python repositories where CodeQL and OpenSSF
Scorecard should publish SARIF results. The repository must allow GitHub Actions
to write security events. Public repositories should also enable GitHub private
vulnerability reporting, Dependabot security updates, secret scanning, and push
protection.

The template does not replace dependency review, dependency audits, secret
scanning, or repository-specific release gates.

The metadata uses `pyproject.toml` as a coarse availability hint for Python
repositories. It is not a full compatibility check.

## Validation

Before changing these templates, validate the files from this repository root:

```bash
ruby <<'RUBY'
require "json"
require "yaml"

(Dir[".github/ISSUE_TEMPLATE/*.yml"] + Dir["workflow-templates/*.yml"]).sort.each do |path|
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
actionlint "$tmpdir"/*.yml
```
