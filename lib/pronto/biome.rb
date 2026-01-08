# frozen_string_literal: true

require 'pronto'
require_relative 'biome/version'
require_relative 'biome/config'
require_relative 'biome/executor'
require_relative 'biome/offense'

module Pronto
  # Pronto runner for Biome - a fast linter/formatter for JavaScript, TypeScript, and JSON.
  #
  # Runs Biome in batch mode on all changed files and reports diagnostics
  # only for lines that were added in the current diff.
  class Biome < Runner
    def run
      return [] if @patches.nil? || @patches.none?

      patches_to_lint = @patches.select do |patch|
        patch.additions.positive? && biome_config.lint_file?(patch.new_file_full_path)
      end

      return [] if patches_to_lint.empty?

      # Run Biome once on all files (batch mode)
      # Use relative paths so Biome returns relative paths in diagnostics
      file_paths = patches_to_lint.map { |p| p.delta.new_file[:path] }
      executor.run(file_paths)

      patches_to_lint.flat_map { |patch| inspect(patch) }.compact
    end

    private

    def biome_config
      @biome_config ||= Config.new(repo_path)
    end

    def executor
      @executor ||= Executor.new(biome_config, repo_path)
    end

    def repo_path
      @repo_path ||= @patches.first.repo.path
    end

    def inspect(patch)
      # Use relative path to match Biome's output format
      relative_path = patch.delta.new_file[:path]
      diagnostics = executor.diagnostics_for(relative_path)

      diagnostics.flat_map do |diagnostic|
        offense = Offense.new(diagnostic)
        next unless offense.valid?

        added_line = find_added_line(patch, offense.line_range)
        next unless added_line

        new_message(offense, added_line)
      end
    end

    def find_added_line(patch, line_range)
      patch.added_lines.reverse_each.find { |line| line_range.cover?(line.new_lineno) }
    end

    def new_message(offense, line)
      path = line.patch.delta.new_file[:path]

      Message.new(path, line, offense.level, offense.message, nil, self.class)
    end
  end
end
