# Vexcalibur organization defaults

[![Validate repository metadata](https://github.com/vexcalibur-dev/.github/actions/workflows/validate-repository-metadata.yml/badge.svg)](https://github.com/vexcalibur-dev/.github/actions/workflows/validate-repository-metadata.yml)
[![OpenSSF Scorecard](https://github.com/vexcalibur-dev/.github/actions/workflows/scorecard.yml/badge.svg)](https://github.com/vexcalibur-dev/.github/actions/workflows/scorecard.yml)

This public `.github` repository holds the shared GitHub profile, community files, and workflow templates for the [`vexcalibur-dev` organization](https://github.com/vexcalibur-dev). It has no runtime package of its own.

GitHub uses the community files here when a public organization repository does not provide a file of the same type. A repository can replace any default with guidance that fits its own release or development process.

## What lives here

| Path | Purpose |
| --- | --- |
| [`profile/README.md`](profile/README.md) | Public organization profile |
| [`.github/dependabot.yml`](.github/dependabot.yml) | Weekly updates for pinned actions in `.github/workflows/` |
| [`.github/ISSUE_TEMPLATE/`](.github/ISSUE_TEMPLATE/) | Default issue forms and issue-chooser links |
| [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md) | Default pull request template |
| [`.github/scripts/`](.github/scripts/) | Metadata parser and security-policy drift tests |
| [`.github/workflows/`](.github/workflows/) | Repository validation and OpenSSF Scorecard analysis |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Contribution guidance for repositories without a local guide |
| [`SECURITY.md`](SECURITY.md) | Private reporting routes and the default support policy for security fixes |
| [`SUPPORT.md`](SUPPORT.md) | Routes for questions, bugs, and feature requests |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Conduct and moderation policy |
| [`workflow-templates/`](workflow-templates/) | Optional Python CI and security workflows |

The [`LICENSE`](LICENSE) covers this repository. GitHub does not inherit a license from an organization defaults repository, so every project must carry its own license file.

## How inheritance works

A local community file wins over the organization default. Issue forms are the exception worth remembering: if a repository has any file in its own `.github/ISSUE_TEMPLATE/` directory, GitHub does not add the forms from this repository.

Workflow templates are not inherited. A maintainer chooses one from the repository's **Actions** page, and GitHub copies it into that repository. Later changes here do not update existing copies.

The `filePatterns` in each workflow template only decide when GitHub suggests it. They do not check the repository's layout, tools, permissions, or security settings. Read the [workflow template guide](workflow-templates/README.md) before using one.

## Validate a change

Run the metadata checks from the repository root. The [workflow template guide](workflow-templates/README.md#validate-template-changes) contains the exact local commands and their prerequisites.

The `Validate repository metadata` workflow checks YAML and JSON, rejects mutable GitHub Action references, tests and verifies the reviewed Scorecard and Dependabot policies, renders the default-branch placeholder, runs `actionlint`, and exercises the Python security commands in a temporary fixture. A successful pull request has both workflow jobs passing.

The repository's own OpenSSF Scorecard workflow runs after changes to `main` and on a weekly schedule. It sends SARIF to this repository's GitHub code-scanning dashboard. Public Scorecard API publication stays disabled, so the workflow does not request an OpenID Connect token.

## Project links

- Meet the projects on the [Vexcalibur organization profile](profile/README.md).
- Use the [Vexcalibur manual](https://vexcalibur-dev.github.io/vexcalibur/) for the command-line tool and Python library.
- Read [CONTRIBUTING.md](CONTRIBUTING.md) before changing shared defaults.
- Report vulnerabilities through [SECURITY.md](SECURITY.md), not a public issue.
- Use [SUPPORT.md](SUPPORT.md) for questions and non-security problems.
