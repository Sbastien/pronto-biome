# frozen_string_literal: true

require 'fileutils'
require 'pronto/biome'

RSpec.shared_context 'test repo' do
  let(:repo_path) { 'spec/fixtures/test.git' }
  let(:repo_path_git) { "#{repo_path}/git" }
  let(:repo_path_dot_git) { "#{repo_path}/.git" }
  let(:repo) { Pronto::Git::Repository.new(repo_path) }

  before { FileUtils.mv(repo_path_git, repo_path_dot_git) }
  after { FileUtils.mv(repo_path_dot_git, repo_path_git) }
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random

  Kernel.srand config.seed
end
