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
    # - cmd_line_opts: Additional CLI options for Biome
    class Config
      CONFIG_FILE = '.pronto_biome.yml'

      attr_reader :biome_executable, :cmd_line_opts

      def initialize(repo_path)
        options = load_options(repo_path)

        @biome_executable = resolve_executable(options).freeze
        @cmd_line_opts = (options['cmd_line_opts'] || '').freeze

        freeze
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
    end
  end
end
