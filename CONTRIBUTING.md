# Contributing to Vexcalibur projects

Vexcalibur welcomes focused fixes, documentation, compatibility reports, and new security-automation use cases. Each repository owns its development commands and public contracts; its local contribution guide takes precedence over this organization default.

## Before you start

1. Choose the [repository](https://github.com/orgs/vexcalibur-dev/repositories) that owns the behavior.
2. Search its issues and pull requests for related work.
3. For a bug, feature, or question, use that repository's issue forms. For a vulnerability, stop and follow the [security policy](https://github.com/vexcalibur-dev/.github/security/policy) instead.
4. Read the repository README and local contribution guide. Set up the versions and tools they name.

We prefer an issue before a large change when the public interface, compatibility policy, release process, or architecture may change. A short design discussion can prevent work on an approach the project cannot support.

## Make the change

- Keep one pull request focused on one problem.
- Add or update tests when behavior changes.
- Update the user-facing docs in the same pull request when commands, inputs, output, permissions, or compatibility change.
- Preserve trust boundaries. Use synthetic or public examples, and never commit credentials, private vulnerability details, private package inventories, or sensitive logs.
- Run every local check required by the repository. Record the exact commands and results in the pull request.

When a repository documents a commit or pull request title convention, follow it. Do not infer a release promise from another Vexcalibur project; each project versions independently.

## Open the pull request

Open pull requests ready for review. Explain the problem, the chosen approach, and any compatibility or security effect. Link the issue when one exists.

Complete the verification, documentation, compatibility, and security sections in the pull request template. If a check could not run, name it and explain what remains unverified.

Maintainers may ask you to split unrelated changes or add evidence before review. They may also close a proposal that conflicts with the project's scope, but should leave the reason in the pull request or issue.
