# Vexcalibur

![Vexcalibur wordmark beside a stylized sword](assets/vexcalibur-banner.png)

Vexcalibur is an open source toolkit for turning software inventory and vulnerability findings into Vulnerability Exploitability eXchange (VEX) documents. The core runs from a local shell or Python, and a companion GitHub Action brings it into repository workflows. CircleCI orb source is available but has not reached the registry.

The core tool reads CycloneDX 1.4–1.6 JSON or XML software bills of materials (SBOMs). It can also fetch an SPDX 2.3 SBOM from the GitHub Dependency Graph. Findings can come from a local file or an OSV-compatible service.

[Vexcalibur 0.2.0](https://github.com/vexcalibur-dev/vexcalibur/releases/tag/v0.2.0) natively emits [CycloneDX 1.6 VEX JSON](https://vexcalibur-dev.github.io/vexcalibur/reference/cyclonedx-vex-output.html) and [OpenVEX 0.2.0 JSON](https://vexcalibur-dev.github.io/vexcalibur/reference/openvex-output.html).

Vexcalibur does not turn a vulnerability database match into an exploitability decision. OSV findings enter the document as `in_triage`; a local findings file carries the assessment its author supplied.

## Start here

Follow the [Vexcalibur quickstart](https://vexcalibur-dev.github.io/vexcalibur/tutorials/quickstart.html) to generate a VEX document without sending package data over the network. The [complete manual](https://vexcalibur-dev.github.io/vexcalibur/) covers network trust boundaries, command behavior, and the Python API. Its format references define each output contract.

Vexcalibur uses a 0.x version line. Pin exact releases in automation because command flags, Python APIs, action inputs, and output details can change.

## Projects

| Project | What it provides | Availability |
| --- | --- | --- |
| [vexcalibur](https://github.com/vexcalibur-dev/vexcalibur) | Command-line tool and typed Python library | [Version 0.2.0 on PyPI](https://pypi.org/project/vexcalibur/0.2.0/) |
| [vexcalibur-action](https://github.com/vexcalibur-dev/vexcalibur-action) | Composite GitHub Action that installs and runs an exact Vexcalibur package release | [Versioned GitHub releases](https://github.com/vexcalibur-dev/vexcalibur-action/releases) |
| [vexcalibur-orb](https://github.com/vexcalibur-dev/vexcalibur-orb) | CircleCI orb source for the same isolated install and execution boundary | Source is available; no CircleCI registry release yet |
| [.github](https://github.com/vexcalibur-dev/.github) | Organization profile, community defaults, and optional workflow templates | Used across the organization |

## Get help or contribute

Use the affected project's issue forms for questions, bugs, and feature requests. Read its contribution guide before opening a pull request.

Do not put exploit details, credentials, private package data, logs, or reproduction steps in a public issue. The [organization security policy](https://github.com/vexcalibur-dev/.github/security/policy) lists the private reporting route for each project.
