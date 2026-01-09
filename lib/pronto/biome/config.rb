# frozen_string_literal: true

require 'yaml'

module Pronto
  class Biome < Runner
    # Configuration management for pronto-biome.
    #
    # Configuration sources (in priority order):
    # 1. Environment variables (highest priority)
    # 2. .pronto_biome.yml - Runner-specific config
    # 3. .pronto.yml under 'biome' key - Global Pronto config
    # 4. Built-in defaults
    #
    # Environment variables:
    # - BIOME_EXECUTABLE: Command to run Biome
    #
    # Available options:
    # - biome_executable: Command to run Biome (default: 'biome')
    # - files_to_lint: Regex or list of extensions to lint
    # - cmd_line_opts: Additional CLI options for Biome
    class Config
      CONFIG_FILE = '.pronto_biome.yml'

      attr_reader :biome_executable, :files_to_lint, :cmd_line_opts

      def initialize(repo_path)
        options = load_options(repo_path)

        @biome_executable = resolve_executable(options).freeze
        @files_to_lint = resolve_files_to_lint(options)
        @cmd_line_opts = (options['cmd_line_opts'] || '').freeze

        freeze
      end

      # Returns true if the file path matches the lint pattern (or no filter is set).
      def lint_file?(path)
        return true unless @files_to_lint

        @files_to_lint.match?(path.to_s)
      end

      private

      def load_options(repo_path)
        pronto_config.merge(load_runner_config(repo_path))
      end

      # Global Pronto config from .pronto.yml
      def pronto_config
        Pronto::ConfigFile.new.to_h['biome'] || {}
      end

      # Runner-specific config from .pronto_biome.yml
      def load_runner_config(repo_path)
        config_file = File.join(repo_path, CONFIG_FILE)
        return {} unless File.exist?(config_file)

        YAML.safe_load_file(config_file, permitted_classes: [Regexp]) || {}
      end

      def resolve_executable(options)
        ENV.fetch('BIOME_EXECUTABLE', nil) || options['biome_executable'] || 'biome'
      end

      # Converts files_to_lint to a Regexp if provided.
      # Accepts: Regexp, string pattern (e.g., '\\.vue$'), or array of extensions (['js', 'ts'])
      # Returns nil if not configured (all files sent to Biome).
      def resolve_files_to_lint(options)
        value = options['files_to_lint']
        return nil unless value

        case value
        when Regexp then value
        when Array then array_to_regexp(value)
        else Regexp.new(value.to_s)
        end
      end

      def array_to_regexp(extensions)
        normalized = extensions.map { |ext| ext.to_s.delete_prefix('.') }
        Regexp.new("\\.(#{normalized.join('|')})$")
      end
    end
  end
end
