# Vexcalibur Dev GitHub Defaults

This repository contains shared GitHub community files and workflow templates for
the `vexcalibur-dev` organization.

GitHub applies supported files from this repository to public organization
repositories that do not provide their own copies. Individual repositories can
override these defaults when they need project-specific guidance.

## Repository Role

The shared files in this repository provide:

- organization profile content in [profile/README.md](profile/README.md);
- default bug, feature, security-contact, and pull request templates in
  [.github/](.github/);
- default support, security, contribution, and conduct files;
- workflow templates for Python Poetry CI and Python security analysis in
  [workflow-templates/](workflow-templates/).

GitHub does not apply a default license file from an organization `.github`
repository. Add a license file to each project repository that needs one.

## Current Project Status

`vexcalibur-dev` projects are pre-alpha unless a project repository says
otherwise. Use the [organization profile](profile/README.md) and project
repository READMEs for current project behavior; this defaults repository only
owns shared GitHub metadata and workflow-template routing.

## Security and Support

Report vulnerabilities privately through the affected repository's Security tab.
If GitHub private vulnerability reporting is unavailable, use the inherited
private disclosure channel request issue form and do not include vulnerability
details or sensitive data in the public request.

Use GitHub issues for non-security bugs, feature requests, and compatibility
problems. The inherited issue forms warn users not to post vulnerabilities,
exploit details, secrets, tokens, private package data, logs, stack traces,
screenshots, or reproduction steps in public issues.

## Workflow Templates

See [workflow-templates/README.md](workflow-templates/README.md) before applying
a template. GitHub `filePatterns` only control when a template is offered based
on matching root files; they are not a full compatibility check.
