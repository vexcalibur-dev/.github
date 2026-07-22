# frozen_string_literal: true

require "fileutils"
require "minitest/autorun"
require "pathname"
require "tmpdir"

require_relative "validate-repository-metadata"

class RepositoryMetadataValidatorTest < Minitest::Test
  REPOSITORY_ROOT = Pathname(__dir__).join("../..").expand_path

  def test_current_repository_passes
    result, _output, errors = validate(REPOSITORY_ROOT)

    assert result, errors
  end

  def test_rejects_mutable_action_reference
    with_repository_copy do |root|
      workflow = root.join(".github/workflows/scorecard.yml")
      workflow.write(workflow.read.sub(
        %r{ossf/scorecard-action@[0-9a-f]{40}},
        "ossf/scorecard-action@v2.4.3",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "must pin uses: ossf/scorecard-action@v2.4.3 to a full commit SHA"
    end
  end

  def test_rejects_mutable_action_in_yaml_extension_and_flow_mapping
    with_repository_copy do |root|
      root.join(".github/workflows/bypass.yaml").write(<<~YAML)
        name: Pin bypass fixture
        on:
          push:
        permissions: {}
        jobs:
          fixture:
            runs-on: ubuntu-latest
            steps:
              - { "uses" : "actions/checkout@v7" }
      YAML

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "must pin uses: actions/checkout@v7 to a full commit SHA"
    end
  end

  def test_rejects_local_action_outside_reviewed_directories
    with_repository_copy do |root|
      custom_action = root.join("custom-action")
      custom_action.mkpath
      custom_action.join("action.yml").write(<<~YAML)
        name: Local bypass fixture
        runs:
          using: composite
          steps:
            - uses: actions/checkout@v7
      YAML
      root.join(".github/workflows/local-bypass.yaml").write(<<~YAML)
        name: Local bypass caller
        on:
          push:
        permissions: {}
        jobs:
          fixture:
            runs-on: ubuntu-latest
            steps:
              - uses: ./custom-action
      YAML

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "local uses reference must target ./, ./.github/actions/, or ./.github/workflows/"
    end
  end

  def test_checks_pins_inside_allowed_local_action
    with_repository_copy do |root|
      custom_action = root.join(".github/actions/custom-action")
      custom_action.mkpath
      custom_action.join("action.yml").write(<<~YAML)
        name: Local pin fixture
        runs:
          using: composite
          steps:
            - uses: actions/checkout@v7
      YAML
      root.join(".github/workflows/local-action.yaml").write(<<~YAML)
        name: Local action caller
        on:
          push:
        permissions: {}
        jobs:
          fixture:
            runs-on: ubuntu-latest
            steps:
              - uses: ./.github/actions/custom-action
      YAML

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "must pin uses: actions/checkout@v7 to a full commit SHA"
    end
  end

  def test_rejects_local_action_reached_through_intermediate_symlink
    with_repository_copy do |root|
      custom_action = root.join("custom-parent/foo")
      custom_action.mkpath
      custom_action.join("action.yml").write(<<~YAML)
        name: Symlink bypass fixture
        runs:
          using: composite
          steps:
            - uses: actions/checkout@v7
      YAML
      actions_directory = root.join(".github/actions")
      actions_directory.mkpath
      actions_directory.join("link").make_symlink("../../custom-parent")
      root.join(".github/workflows/symlink-bypass.yaml").write(<<~YAML)
        name: Symlink bypass caller
        on:
          push:
        permissions: {}
        jobs:
          fixture:
            runs-on: ubuntu-latest
            steps:
              - uses: ./.github/actions/link/foo
      YAML

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "local action directory must exist without symbolic-link traversal"
    end
  end

  def test_rejects_unsupported_scorecard_trigger
    with_repository_copy do |root|
      workflow = root.join(".github/workflows/scorecard.yml")
      workflow.write(workflow.read.sub("  push:\n", "  workflow_dispatch:\n  push:\n"))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "must use only the supported push and schedule triggers"
    end
  end

  def test_rejects_unneeded_repository_scorecard_oidc_permission
    with_repository_copy do |root|
      workflow = root.join(".github/workflows/scorecard.yml")
      workflow.write(workflow.read.sub(
        "      security-events: write\n",
        "      id-token: write\n      security-events: write\n",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "scorecard permissions changed from the reviewed public-repository set"
    end
  end

  def test_rejects_unneeded_template_scorecard_oidc_permission
    with_repository_copy do |root|
      template = root.join("workflow-templates/security-analysis.yml")
      template.write(template.read.sub(
        "      issues: read\n",
        "      id-token: write\n      issues: read\n",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "Scorecard permissions changed from the reviewed private-compatible set"
    end
  end

  def test_rejects_repository_scorecard_job_bypass
    with_repository_copy do |root|
      workflow = root.join(".github/workflows/scorecard.yml")
      workflow.write(workflow.read.sub(
        "    timeout-minutes: 15\n",
        "    timeout-minutes: 15\n    continue-on-error: true\n",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "scorecard job contains unreviewed controls"
    end
  end

  def test_rejects_extra_repository_scorecard_job
    with_repository_copy do |root|
      workflow = root.join(".github/workflows/scorecard.yml")
      workflow.write("#{workflow.read}\n  unexpected:\n    runs-on: ubuntu-latest\n    steps:\n      - run: echo unexpected\n")

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "must contain only jobs.scorecard"
    end
  end

  def test_rejects_extra_repository_scorecard_input
    with_repository_copy do |root|
      workflow = root.join(".github/workflows/scorecard.yml")
      workflow.write(workflow.read.sub(
        "          publish_results: false\n",
        "          publish_results: false\n          file_mode: git\n",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "scorecard action sequence changed from the reviewed boundary"
    end
  end

  def test_rejects_template_scorecard_on_experimental_event
    with_repository_copy do |root|
      template = root.join("workflow-templates/security-analysis.yml")
      template.write(template.read.sub(
        "    if: github.event_name == 'push' || github.event_name == 'schedule'\n",
        "    if: github.event_name == 'pull_request'\n",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "Scorecard job must run only on supported events"
    end
  end

  def test_rejects_disabled_template_scorecard_triggers
    with_repository_copy do |root|
      template = root.join("workflow-templates/security-analysis.yml")
      template.write(template.read.sub(
        "  push:\n    branches: [$default-branch]\n  schedule:\n    - cron: \"41 8 * * 1\"\n",
        "",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "triggers changed from the reviewed event boundary"
    end
  end

  def test_rejects_broadened_template_scorecard_push
    with_repository_copy do |root|
      template = root.join("workflow-templates/security-analysis.yml")
      template.write(template.read.sub(
        "  push:\n    branches: [$default-branch]\n",
        "  push:\n    branches: [\"**\"]\n",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "triggers changed from the reviewed event boundary"
    end
  end

  def test_rejects_self_hosted_template_scorecard_runner
    with_repository_copy do |root|
      template = root.join("workflow-templates/security-analysis.yml")
      template.write(template.read.sub(
        "    runs-on: ubuntu-latest\n    if: github.event_name == 'push' || github.event_name == 'schedule'\n",
        "    runs-on: self-hosted\n    if: github.event_name == 'push' || github.event_name == 'schedule'\n",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "Scorecard job must use ubuntu-latest"
    end
  end

  def test_rejects_renovate_schedule_drift
    with_repository_copy do |root|
      renovate = JSON.parse(root.join("renovate.json").read)
      renovate["schedule"] = ["* 12-15 * * 1"]
      root.join("renovate.json").write("#{JSON.pretty_generate(renovate)}\n")

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "differs from the canonical reviewed Renovate update policy"
    end
  end

  def test_rejects_enabled_renovate_vulnerability_alerts
    with_repository_copy do |root|
      renovate = JSON.parse(root.join("renovate.json").read)
      renovate["vulnerabilityAlerts"]["enabled"] = true
      root.join("renovate.json").write("#{JSON.pretty_generate(renovate)}\n")

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "differs from the canonical reviewed Renovate update policy"
    end
  end

  def test_rejects_renovate_without_action_digest_pinning
    with_repository_copy do |root|
      renovate = JSON.parse(root.join("renovate.json").read)
      renovate["extends"].delete("helpers:pinGitHubActionDigests")
      root.join("renovate.json").write("#{JSON.pretty_generate(renovate)}\n")

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "differs from the canonical reviewed Renovate update policy"
    end
  end

  def test_rejects_renovate_automerge_policy
    with_repository_copy do |root|
      renovate = JSON.parse(root.join("renovate.json").read)
      renovate["packageRules"] = [{
        "matchManagers" => ["github-actions"],
        "automerge" => true,
      }]
      root.join("renovate.json").write("#{JSON.pretty_generate(renovate)}\n")

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "differs from the canonical reviewed Renovate update policy"
    end
  end

  def test_rejects_codeowners_override_after_security_rules
    with_repository_copy do |root|
      codeowners = root.join(".github/CODEOWNERS")
      codeowners.write("#{codeowners.read}\n* @unexpected-owner\n")

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "differs from the canonical reviewed rule set"
    end
  end

  def test_rejects_codeowners_owner_drift
    with_repository_copy do |root|
      codeowners = root.join(".github/CODEOWNERS")
      codeowners.write(codeowners.read.sub(
        "/.github/CODEOWNERS @dannysauer",
        "/.github/CODEOWNERS @unexpected-owner",
      ))

      result, _output, errors = validate(root)

      refute result
      assert_includes errors, "differs from the canonical reviewed rule set"
    end
  end

  private

  def validate(root)
    result = nil
    output, errors = capture_io do
      result = RepositoryMetadataValidator.new(root).validate
    end
    [result, output, errors]
  end

  def with_repository_copy
    Dir.mktmpdir("vexcalibur-metadata-validator-test") do |temporary_directory|
      root = Pathname(temporary_directory)
      FileUtils.cp_r(REPOSITORY_ROOT.join(".github"), root.join(".github"))
      FileUtils.cp_r(
        REPOSITORY_ROOT.join("workflow-templates"),
        root.join("workflow-templates"),
      )
      FileUtils.cp(REPOSITORY_ROOT.join("renovate.json"), root.join("renovate.json"))
      yield root
    end
  end
end
