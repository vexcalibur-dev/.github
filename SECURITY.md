# Security policy

## Report a vulnerability privately

Use GitHub private vulnerability reporting in the repository that contains the affected code:

| Project | Private report |
| --- | --- |
| Vexcalibur | [Open a Vexcalibur security advisory](https://github.com/vexcalibur-dev/vexcalibur/security/advisories/new) |
| Vexcalibur Action | [Open a Vexcalibur Action security advisory](https://github.com/vexcalibur-dev/vexcalibur-action/security/advisories/new) |
| Vexcalibur CircleCI Orb | Private vulnerability reporting is not enabled; [request a private channel](https://github.com/vexcalibur-dev/.github/issues/new?template=private_disclosure_request.yml) without identifying the affected system |
| Organization defaults and workflow templates | [Open an organization-defaults security advisory](https://github.com/vexcalibur-dev/.github/security/advisories/new) |

Do not open a public issue with vulnerability details. Keep exploit steps, credentials, private package data, affected private package names, logs, stack traces, screenshots, and reproduction material in the private advisory.

If the table directs you to the request form, or GitHub will not let you open a private advisory, submit a [private disclosure channel request](https://github.com/vexcalibur-dev/.github/issues/new?template=private_disclosure_request.yml). That request is a public issue. Ask for a private channel and include nothing about the vulnerability or the affected system.

Maintainers aim to acknowledge a private report within three business days. While work continues, they aim to send a status update at least once every seven calendar days. The reporter and maintainers should coordinate publication after a fix, mitigation, or no-fix decision is ready.

## Supported versions

A repository's local `SECURITY.md` defines its supported release lines. If a repository inherits this policy, only its default branch receives security fixes; no release line is supported by implication.

For this `.github` repository, security fixes target `main`. Workflow templates are copied into other repositories, so maintainers must review and apply relevant fixes to copies they already use.
