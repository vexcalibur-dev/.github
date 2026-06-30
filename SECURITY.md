# Security Policy

## Reporting Vulnerabilities

Report security issues privately. Do not open a public issue with vulnerability
details, exploit steps, secrets, tokens, private package data, or other sensitive
evidence.

Use GitHub private vulnerability reporting from the affected repository's
Security tab. The currently supported disclosure forms are:

- Vexcalibur: <https://github.com/vexcalibur-dev/vexcalibur/security/advisories/new>
- Vexcalibur Action: <https://github.com/vexcalibur-dev/vexcalibur-action/security/advisories/new>
- Organization defaults and shared templates: <https://github.com/vexcalibur-dev/.github/security/advisories/new>

For future `vexcalibur-dev` repositories that inherit this default policy, use
that repository's Security tab when GitHub private vulnerability reporting is
enabled there.

If GitHub does not allow you to use private vulnerability reporting, use the
private disclosure channel request issue form. That public issue must only ask
maintainers to provide a private disclosure channel. Do not include vulnerability
details in that request.

Maintainers should acknowledge private reports within 3 business days, provide a
status update at least every 7 calendar days while the report is active, and
coordinate public disclosure after a fix, mitigation, or no-fix decision is
ready.

## Supported Versions

Security fixes target the default branch until a repository publishes versioned
releases. After releases begin, each repository must document which release
lines receive security fixes.
