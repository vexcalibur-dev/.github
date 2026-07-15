# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

class RepositoryMetadataValidator
  REMOTE_ACTION = %r{\A[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:/[A-Za-z0-9_./-]+)?@[0-9a-f]{40}\z}
  PUBLIC_SCORECARD_PERMISSIONS = {
    "security-events" => "write",
  }.freeze
  TEMPLATE_SCORECARD_PERMISSIONS = {
    "actions" => "read",
    "checks" => "read",
    "contents" => "read",
    "issues" => "read",
    "pull-requests" => "read",
    "security-events" => "write",
  }.freeze
  DEPENDABOT_CONFIGURATION = {
    "version" => 2,
    "updates" => [
      {
        "package-ecosystem" => "github-actions",
        "directory" => "/",
        "schedule" => {
          "interval" => "weekly",
          "day" => "monday",
          "time" => "09:30",
        },
        "open-pull-requests-limit" => 5,
        "groups" => {
          "github-actions" => {
            "patterns" => ["*"],
          },
        },
      },
    ],
  }.freeze

  def initialize(root)
    @root = Pathname(root).expand_path
    @errors = []
    @yaml_documents = {}
  end

  def validate
    parse_structured_files
    validate_action_pins
    validate_scorecard_workflow
    validate_security_template
    validate_dependabot
    validate_code_ownership

    unless @errors.empty?
      warn @errors.map { |error| "ERROR: #{error}" }.join("\n")
      return false
    end

    puts "Repository metadata and security policy OK"
    true
  end

  private

  def relative(path)
    path.relative_path_from(@root).to_s
  end

  def parse_structured_files
    yaml_paths = [
      *@root.glob(".github/ISSUE_TEMPLATE/*.yml"),
      *@root.glob(".github/ISSUE_TEMPLATE/*.yaml"),
      *@root.glob(".github/workflows/*.yml"),
      *@root.glob(".github/workflows/*.yaml"),
      *@root.glob(".github/actions/**/action.yml"),
      *@root.glob(".github/actions/**/action.yaml"),
      *@root.glob("workflow-templates/*.yml"),
      *@root.glob("workflow-templates/*.yaml"),
      @root.join(".github/dependabot.yml"),
      @root.join("action.yml"),
      @root.join("action.yaml"),
    ].select(&:file?).uniq.sort

    yaml_paths.each do |path|
      name = relative(path)
      @yaml_documents[name] = YAML.safe_load_file(
        path,
        permitted_classes: [],
        permitted_symbols: [],
        aliases: false,
      )
      puts "YAML OK #{name}"
    rescue Psych::Exception => error
      @errors << "#{name} is not valid safe YAML: #{error.message}"
    end

    @root.glob("workflow-templates/*.json").sort.each do |path|
      name = relative(path)
      JSON.parse(path.read)
      puts "JSON OK #{name}"
    rescue JSON::ParserError => error
      @errors << "#{name} is not valid JSON: #{error.message}"
    end
  end

  def validate_action_pins
    action_files = [
      *@root.glob(".github/workflows/*.yml"),
      *@root.glob(".github/workflows/*.yaml"),
      *@root.glob("workflow-templates/*.yml"),
      *@root.glob("workflow-templates/*.yaml"),
      *@root.glob(".github/actions/**/action.yml"),
      *@root.glob(".github/actions/**/action.yaml"),
      @root.join("action.yml"),
      @root.join("action.yaml"),
    ].select(&:file?).uniq.sort

    action_files.each do |path|
      document = @yaml_documents[relative(path)]
      next unless document

      each_action_reference(document) do |reference, location|
        unless reference.is_a?(String)
          @errors << "#{relative(path)} #{location} uses value must be a string"
          next
        end
        if reference.start_with?("./")
          validate_local_action_reference(reference, path, location)
          next
        end
        next if reference.match?(%r{\Adocker://[^@\s]+@sha256:[0-9a-f]{64}\z})
        next if reference.match?(REMOTE_ACTION)

        @errors << "#{relative(path)} #{location} must pin uses: #{reference} to a full commit SHA"
      end
    end
  end

  def each_action_reference(value, location = "$", &block)
    case value
    when Hash
      value.each do |key, child|
        child_location = "#{location}.#{key}"
        if key == "uses"
          yield child, child_location
        else
          each_action_reference(child, child_location, &block)
        end
      end
    when Array
      value.each_with_index do |child, index|
        each_action_reference(child, "#{location}[#{index}]", &block)
      end
    end
  end

  def validate_local_action_reference(reference, source_path, location)
    relative_target = reference.delete_prefix("./")
    clean_target = Pathname(relative_target.empty? ? "." : relative_target).cleanpath.to_s
    unless relative_target.empty? || clean_target == relative_target
      @errors << "#{relative(source_path)} #{location} local uses path must be normalized: #{reference}"
      return
    end

    if relative_target.empty?
      validate_local_action_directory(@root, reference, source_path, location)
      return
    end

    if relative_target.start_with?(".github/actions/")
      validate_local_action_directory(
        @root.join(relative_target),
        reference,
        source_path,
        location,
      )
      return
    end

    if relative_target.start_with?(".github/workflows/") && relative_target.match?(/[.]ya?ml\z/)
      target = @root.join(relative_target)
      unless target.file? && path_without_symlinks?(target)
        @errors << "#{relative(source_path)} #{location} local workflow must be a regular file without symbolic-link traversal: #{reference}"
      end
      return
    end

    @errors << "#{relative(source_path)} #{location} local uses reference must target ./, ./.github/actions/, or ./.github/workflows/: #{reference}"
  end

  def validate_local_action_directory(target, reference, source_path, location)
    unless target.directory? && path_without_symlinks?(target)
      @errors << "#{relative(source_path)} #{location} local action directory must exist without symbolic-link traversal: #{reference}"
      return
    end

    metadata_files = [target.join("action.yml"), target.join("action.yaml")].select do |candidate|
      candidate.file? && path_without_symlinks?(candidate)
    end
    unless metadata_files.length == 1
      @errors << "#{relative(source_path)} #{location} local action must contain exactly one regular action.yml or action.yaml: #{reference}"
    end
  end

  def path_without_symlinks?(path)
    path.realpath == path.expand_path
  rescue SystemCallError
    false
  end

  def validate_scorecard_workflow
    name = ".github/workflows/scorecard.yml"
    workflow = @yaml_documents[name]
    unless workflow.is_a?(Hash)
      @errors << "#{name} is missing or did not parse as a mapping"
      return
    end

    triggers = workflow["on"] || workflow[true]
    unless triggers.is_a?(Hash)
      @errors << "#{name} must define mapping-style triggers"
      return
    end

    unless triggers.keys.sort == %w[push schedule]
      @errors << "#{name} must use only the supported push and schedule triggers"
    end

    @errors << "#{name} push trigger must target only main" unless triggers["push"] == {"branches" => ["main"]}
    expected_schedule = [{"cron" => "47 7 * * 1"}]
    @errors << "#{name} weekly schedule changed from the reviewed value" unless triggers["schedule"] == expected_schedule

    @errors << "#{name} top-level permissions must be empty" unless workflow["permissions"] == {}
    @errors << "#{name} must not define top-level env" if workflow.key?("env")
    @errors << "#{name} must not define top-level defaults" if workflow.key?("defaults")

    job = workflow.dig("jobs", "scorecard")
    unless workflow["jobs"].is_a?(Hash) && workflow["jobs"].keys == ["scorecard"]
      @errors << "#{name} must contain only jobs.scorecard"
    end
    unless job.is_a?(Hash)
      @errors << "#{name} must define jobs.scorecard"
      return
    end

    @errors << "#{name} scorecard job name changed from Scorecard" unless job["name"] == "Scorecard"
    @errors << "#{name} scorecard job must use ubuntu-latest" unless job["runs-on"] == "ubuntu-latest"
    @errors << "#{name} scorecard timeout must remain 15 minutes" unless job["timeout-minutes"] == 15
    expected_job_keys = %w[name permissions runs-on steps timeout-minutes]
    unless job.keys.sort == expected_job_keys.sort
      @errors << "#{name} scorecard job contains unreviewed controls"
    end
    unless job["permissions"] == PUBLIC_SCORECARD_PERMISSIONS
      @errors << "#{name} scorecard permissions changed from the reviewed public-repository set"
    end

    steps = job["steps"]
    unless steps.is_a?(Array)
      @errors << "#{name} scorecard job must define steps"
      return
    end
    unless steps.length == 3 && steps.all? { |step| step.is_a?(Hash) && step["uses"].is_a?(String) }
      @errors << "#{name} scorecard job must contain only the three reviewed action steps"
    end
    expected_steps = [
      ["Checkout", "actions/checkout@", {"persist-credentials" => false}],
      [
        "Run OpenSSF Scorecard",
        "ossf/scorecard-action@",
        {
          "results_file" => "scorecard.sarif",
          "results_format" => "sarif",
          "publish_results" => false,
        },
      ],
      [
        "Upload Scorecard SARIF",
        "github/codeql-action/upload-sarif@",
        {"sarif_file" => "scorecard.sarif"},
      ],
    ]
    unless steps.zip(expected_steps).all? do |step, expected|
      next false unless expected

      expected_name, prefix, expected_inputs = expected
      step.is_a?(Hash) &&
        step.keys.sort == %w[name uses with] &&
        step["name"] == expected_name &&
        step["uses"].is_a?(String) &&
        step["uses"].start_with?(prefix) &&
        step["with"] == expected_inputs
    end
      @errors << "#{name} scorecard action sequence changed from the reviewed boundary"
    end

    checkout = action_step(steps, "actions/checkout@")
    scorecard = action_step(steps, "ossf/scorecard-action@")
    upload = action_step(steps, "github/codeql-action/upload-sarif@")
    @errors << "#{name} must use actions/checkout" unless checkout
    @errors << "#{name} must use ossf/scorecard-action" unless scorecard
    @errors << "#{name} must use github/codeql-action/upload-sarif" unless upload

    if checkout && checkout.dig("with", "persist-credentials") != false
      @errors << "#{name} checkout must disable persisted credentials"
    end
    if scorecard
      inputs = scorecard.fetch("with", {})
      @errors << "#{name} Scorecard results_file must be scorecard.sarif" unless inputs["results_file"] == "scorecard.sarif"
      @errors << "#{name} Scorecard results_format must be sarif" unless inputs["results_format"] == "sarif"
      unless [false, "false"].include?(inputs["publish_results"])
        @errors << "#{name} must keep public Scorecard API publication disabled"
      end
      @errors << "#{name} must use the workflow token, not a custom repo_token" if inputs.key?("repo_token")
    end
    if upload && upload.dig("with", "sarif_file") != "scorecard.sarif"
      @errors << "#{name} SARIF upload must use scorecard.sarif"
    end
  end

  def action_step(steps, prefix)
    steps.find do |step|
      step.is_a?(Hash) && step["uses"].is_a?(String) && step["uses"].start_with?(prefix)
    end
  end

  def validate_security_template
    name = "workflow-templates/security-analysis.yml"
    template = @yaml_documents[name]
    unless template.is_a?(Hash)
      @errors << "#{name} is missing or did not parse as a mapping"
      return
    end

    triggers = template["on"] || template[true]
    expected_triggers = {
      "pull_request" => {"branches" => ["$default-branch"]},
      "push" => {"branches" => ["$default-branch"]},
      "schedule" => [{"cron" => "41 8 * * 1"}],
      "workflow_dispatch" => nil,
    }
    unless triggers == expected_triggers
      @errors << "#{name} triggers changed from the reviewed event boundary"
    end

    job = template.dig("jobs", "scorecard")
    unless job.is_a?(Hash)
      @errors << "#{name} must define jobs.scorecard"
      return
    end

    expected_job_keys = %w[if name permissions runs-on steps timeout-minutes]
    unless job.keys.sort == expected_job_keys.sort
      @errors << "#{name} Scorecard job contains unreviewed controls"
    end
    expected_if = "github.event_name == 'push' || github.event_name == 'schedule'"
    @errors << "#{name} Scorecard job name changed" unless job["name"] == "OpenSSF Scorecard"
    @errors << "#{name} Scorecard job must use ubuntu-latest" unless job["runs-on"] == "ubuntu-latest"
    @errors << "#{name} Scorecard job must run only on supported events" unless job["if"] == expected_if
    @errors << "#{name} Scorecard timeout must remain 15 minutes" unless job["timeout-minutes"] == 15
    unless job["permissions"] == TEMPLATE_SCORECARD_PERMISSIONS
      @errors << "#{name} Scorecard permissions changed from the reviewed private-compatible set"
    end
    scorecard = action_step(job["steps"], "ossf/scorecard-action@") if job["steps"].is_a?(Array)
    unless scorecard
      @errors << "#{name} must use ossf/scorecard-action"
      return
    end

    expected_steps = [
      ["Checkout", "actions/checkout@", {"persist-credentials" => false}],
      [
        "Run OpenSSF Scorecard",
        "ossf/scorecard-action@",
        {
          "results_file" => "scorecard.sarif",
          "results_format" => "sarif",
          "publish_results" => false,
        },
      ],
      [
        "Upload Scorecard SARIF",
        "github/codeql-action/upload-sarif@",
        {"sarif_file" => "scorecard.sarif"},
      ],
    ]
    unless job["steps"].length == expected_steps.length && job["steps"].zip(expected_steps).all? do |step, expected|
      expected_name, prefix, expected_inputs = expected
      step.is_a?(Hash) &&
        step.keys.sort == %w[name uses with] &&
        step["name"] == expected_name &&
        step["uses"].is_a?(String) &&
        step["uses"].start_with?(prefix) &&
        step["with"] == expected_inputs
    end
      @errors << "#{name} Scorecard action sequence changed from the reviewed boundary"
    end

    publish_results = scorecard.fetch("with", {})["publish_results"]
    unless [false, "false"].include?(publish_results)
      @errors << "#{name} must keep public Scorecard API publication disabled"
    end

    checkout = action_step(job["steps"], "actions/checkout@")
    upload = action_step(job["steps"], "github/codeql-action/upload-sarif@")
    @errors << "#{name} checkout must disable persisted credentials" if checkout&.dig("with", "persist-credentials") != false
    @errors << "#{name} must upload Scorecard SARIF" unless upload&.dig("with", "sarif_file") == "scorecard.sarif"
  end

  def validate_dependabot
    name = ".github/dependabot.yml"
    configuration = @yaml_documents[name]
    unless configuration.is_a?(Hash)
      @errors << "#{name} is missing or did not parse as a mapping"
      return
    end

    unless configuration == DEPENDABOT_CONFIGURATION
      @errors << "#{name} differs from the canonical reviewed GitHub Actions update policy"
    end
  end

  def validate_code_ownership
    codeowners = @root.join(".github/CODEOWNERS")
    unless codeowners.file?
      @errors << ".github/CODEOWNERS is missing"
      return
    end

    rules = codeowners.each_line.filter_map do |line|
      stripped = line.strip
      stripped unless stripped.empty? || stripped.start_with?("#")
    end
    expected_rules = [
      "* @dannysauer",
      "/.github/CODEOWNERS @dannysauer",
      "/.github/ISSUE_TEMPLATE/ @dannysauer",
      "/.github/PULL_REQUEST_TEMPLATE.md @dannysauer",
      "/profile/ @dannysauer",
      "/workflow-templates/ @dannysauer",
      "/CODE_OF_CONDUCT.md @dannysauer",
      "/SECURITY.md @dannysauer",
      "/.github/dependabot.yml @dannysauer",
      "/.github/scripts/ @dannysauer",
      "/.github/workflows/ @dannysauer",
    ]
    unless rules == expected_rules
      @errors << ".github/CODEOWNERS differs from the canonical reviewed rule set"
    end
  end
end

if $PROGRAM_NAME == __FILE__
  root = Pathname(__dir__).join("../..").expand_path
  exit(RepositoryMetadataValidator.new(root).validate ? 0 : 1)
end
