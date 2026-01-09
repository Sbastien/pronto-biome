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
      CONFIG_KEYS = %w[biome_executable files_to_lint cmd_line_opts].freeze

      # Default extensions supported by Biome (stable support only)
      # https://biomejs.dev/internals/language-support/
      DEFAULT_EXTENSIONS = %w[js ts jsx tsx mjs cjs json jsonc css graphql gql].freeze
      DEFAULT_FILES_TO_LINT = /\.(#{DEFAULT_EXTENSIONS.join('|')})$/

      attr_reader :biome_executable, :files_to_lint, :cmd_line_opts

      def initialize(repo_path)
        options = load_options(repo_path)

        @biome_executable = resolve_executable(options).freeze
        @files_to_lint = resolve_files_to_lint(options).freeze
        @cmd_line_opts = (options['cmd_line_opts'] || '').freeze

        freeze
      end

      # Returns true if the file path matches the lint pattern.
      def lint_file?(path) = files_to_lint.match?(path.to_s)

      # Returns the list of supported extensions (for documentation/debugging).
      def self.default_extensions = DEFAULT_EXTENSIONS

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

      # Converts files_to_lint to a Regexp.
      # Accepts: Regexp, string pattern (e.g., '\\.vue$'), or array of extensions (['js', 'ts'])
      def resolve_files_to_lint(options)
        value = options['files_to_lint']
        return DEFAULT_FILES_TO_LINT unless value

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
