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

      # Default extensions supported by Biome
      # https://biomejs.dev/internals/language-support/
      DEFAULT_EXTENSIONS = %w[js ts jsx tsx mjs cjs json jsonc].freeze
      DEFAULT_FILES_TO_LINT = /\.(#{DEFAULT_EXTENSIONS.join('|')})$/

      attr_reader :biome_executable, :files_to_lint, :cmd_line_opts

      def initialize(repo_path)
        @repo_path = repo_path
        @biome_executable = ENV.fetch('BIOME_EXECUTABLE', 'biome')
        @files_to_lint = DEFAULT_FILES_TO_LINT
        @cmd_line_opts = ''

        load_config
      end

      # Returns true if the file path matches the lint pattern.
      def lint_file?(path) = files_to_lint.match?(path.to_s)

      # Returns the list of supported extensions (for documentation/debugging).
      def self.default_extensions = DEFAULT_EXTENSIONS

      private

      def load_config
        merged_options.each do |key, value|
          next unless CONFIG_KEYS.include?(key.to_s)

          send(:"#{key}=", value)
        end
      end

      # Merge configs with priority: runner-specific file > global .pronto.yml
      def merged_options
        pronto_config.merge(runner_config)
      end

      # Global Pronto config from .pronto.yml
      def pronto_config
        @pronto_config ||= Pronto::ConfigFile.new.to_h['biome'] || {}
      end

      # Runner-specific config from .pronto_biome.yml
      def runner_config
        @runner_config ||= load_runner_config
      end

      def load_runner_config
        config_file = File.join(@repo_path, CONFIG_FILE)
        return {} unless File.exist?(config_file)

        YAML.safe_load_file(config_file, permitted_classes: [Regexp]) || {}
      end

      attr_writer :biome_executable, :cmd_line_opts

      # Converts files_to_lint to a Regexp.
      # Accepts:
      # - A Regexp directly
      # - A string regex pattern (e.g., '\\.vue$')
      # - An array of extensions (e.g., ['js', 'ts', 'vue'])
      def files_to_lint=(value)
        @files_to_lint = case value
                         when Regexp
                           value
                         when Array
                           extensions = value.map { |ext| ext.to_s.delete_prefix('.') }
                           Regexp.new("\\.(#{extensions.join('|')})$")
                         else
                           Regexp.new(value.to_s)
                         end
      end
    end
  end
end
