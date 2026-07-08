# Vexcalibur Dev

![Vexcalibur wordmark and sword logo](assets/vexcalibur-banner.png)

Vexcalibur Dev builds open source security automation for Vulnerability
Exploitability eXchange (VEX), Software Bill of Materials (SBOM), package URL
(PURL), and vulnerability intelligence workflows.

The project focuses on practical supply chain security tooling: ingest an SBOM,
query or import vulnerability findings, and produce useful VEX statements that
fit developer workflows, CI/CD pipelines, GitHub Actions, and downstream
security reporting.

## What Vexcalibur Is For

Vexcalibur helps teams answer a direct question: which vulnerabilities in this
software inventory are actually exploitable, affected, fixed, or not affected?

Current project goals include:

- SBOM-driven VEX generation for CycloneDX and GitHub Dependency Graph data.
- Provider-neutral vulnerability lookup through OSV-compatible services and
  local no-network findings files.
- CI-friendly output for security automation, release evidence, and audit
  workflows.
- Clear extension points for future VEX, SBOM, vulnerability, and end-of-life
  software data sources.

## Components

- [vexcalibur](https://github.com/vexcalibur-dev/vexcalibur) is the core
  command-line tool and Python library for generating and transforming VEX
  documents from SBOMs and vulnerability data.
- [Vexcalibur documentation source](https://github.com/vexcalibur-dev/vexcalibur/tree/main/docs)
  provides the quickstart, how-to guides, CLI reference, provider contract, and
  architecture notes for the core tool while generated documentation publishing
  is being enabled.
- [vexcalibur-action](https://github.com/vexcalibur-dev/vexcalibur-action) is
  the GitHub Action wrapper for running Vexcalibur in repository workflows.
- [vexcalibur-dev/.github](https://github.com/vexcalibur-dev/.github) contains
  shared organization profile content, community defaults, and workflow
  templates.

## Status

Vexcalibur is usable today for supported SBOM, OSV-compatible, local findings,
and CycloneDX VEX workflows. Public contracts remain unstable before 1.0, so
pin exact versions in automation and check each repository's README and
documentation for current support details.

## Security and Support

Report vulnerabilities privately through the affected repository's Security tab.
Do not post vulnerabilities, exploit details, secrets, tokens, private package
data, logs, stack traces, screenshots, or reproduction steps in public issues.

Use GitHub issues for non-security bugs, feature requests, and compatibility
problems.

## Contributing

Start with the contribution guidance in the repository you want to change. The
organization welcomes focused bug reports, compatibility reports, documentation
fixes, provider ideas, and security automation use cases.
