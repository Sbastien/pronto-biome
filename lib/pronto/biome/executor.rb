# frozen_string_literal: true

require 'json'
require 'open3'
require 'shellwords'

module Pronto
  class Biome < Runner
    # Executes Biome in batch mode and parses its JSON output.
    #
    # Runs Biome once on all files and groups diagnostics by file path.
    # This is more efficient than running Biome separately for each file.
    #
    # Handles various edge cases:
    # - JSON wrapped in tool output (yarn, npx, etc.)
    # - Missing Biome executable
    # - Invalid JSON output
    # - Empty diagnostics
    class Executor
      def initialize(config, repo_path)
        @config = config
        @repo_path = repo_path
        @results = nil
      end

      # Runs Biome on all given files and returns a hash of {file_path => diagnostics}.
      # Results are cached - subsequent calls return the cached results.
      # Returns an empty hash on any error (missing executable, invalid JSON, etc.)
      def run(file_paths)
        @results ||= execute_biome(file_paths)
      end

      # Returns diagnostics for a specific file path.
      def diagnostics_for(file_path)
        return [] unless @results

        @results[file_path] || []
      end

      # Clears the result cache. Useful for testing.
      def clear_cache
        @results = nil
      end

      private

      def execute_biome(file_paths)
        return {} if file_paths.empty?

        Dir.chdir(@repo_path) { run_and_parse(file_paths) }
      rescue JSON::ParserError => e
        log_warning("Failed to parse Biome output: #{e.message}")
        {}
      rescue Errno::ENOENT => e
        log_warning("Biome executable not found (#{@config.biome_executable}): #{e.message}")
        {}
      end

      def run_and_parse(file_paths)
        stdout, stderr, status = Open3.capture3(*build_command(file_paths))

        log_warning("Biome stderr: #{stderr}") if stderr && !stderr.empty?

        if stdout.empty?
          log_warning("Biome exited with code #{status.exitstatus}") unless status.success?
          return {}
        end

        parse_output(stdout)
      end

      def build_command(file_paths)
        [
          *Shellwords.split(@config.biome_executable),
          'check',
          *Shellwords.split(@config.cmd_line_opts),
          '--reporter=json',
          *file_paths
        ].reject(&:empty?)
      end

      # Parses Biome JSON output and groups diagnostics by file path.
      #
      # When Biome is invoked through yarn/npx, the output may include
      # extra lines before/after the JSON. We find the JSON line by
      # looking for a line starting with '{'.
      def parse_output(output)
        output.lines.each do |line|
          next unless line.start_with?('{')

          result = JSON.parse(line)
          return group_by_file(result['diagnostics']) if result['diagnostics']

          log_warning('Biome output missing diagnostics key')
          return {}
        end
        {}
      end

      def group_by_file(diagnostics)
        diagnostics.each_with_object(Hash.new { |h, k| h[k] = [] }) do |diagnostic, grouped|
          path = diagnostic.dig('location', 'path', 'file')
          grouped[path] << diagnostic if path
        end
      end

      def log_warning(message) = warn "[pronto-biome] #{message}"
    end
  end
end
