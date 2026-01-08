# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pronto::Biome::Config do
  subject(:config) { described_class.new('/tmp/repo') }

  let(:pronto_config) { {} }

  before do
    allow(Pronto::ConfigFile).to receive(:new).and_return(
      instance_double(Pronto::ConfigFile, to_h: pronto_config)
    )
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(false)
  end

  describe 'defaults' do
    it 'has default biome_executable' do
      expect(config.biome_executable).to eq('biome')
    end

    it 'has default files_to_lint' do
      expect(config.files_to_lint).to eq(/\.(js|ts|jsx|tsx|mjs|cjs|json|jsonc)$/)
    end

    it 'has default cmd_line_opts' do
      expect(config.cmd_line_opts).to eq('')
    end
  end

  describe '.default_extensions' do
    it 'returns the list of supported extensions' do
      expect(described_class.default_extensions).to eq(%w[js ts jsx tsx mjs cjs json jsonc])
    end
  end

  describe 'loading from .pronto.yml' do
    let(:pronto_config) do
      {
        'biome' => {
          'biome_executable' => 'npx biome',
          'cmd_line_opts' => '--config-path=biome.json'
        }
      }
    end

    it 'reads biome_executable from pronto config' do
      expect(config.biome_executable).to eq('npx biome')
    end

    it 'reads cmd_line_opts from pronto config' do
      expect(config.cmd_line_opts).to eq('--config-path=biome.json')
    end
  end

  describe 'loading from .pronto_biome.yml' do
    let(:runner_yaml) do
      <<~YAML
        biome_executable: ./node_modules/.bin/biome
        files_to_lint: '\\.vue$'
      YAML
    end

    before do
      allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
      allow(File).to receive(:read).with('/tmp/repo/.pronto_biome.yml').and_return(runner_yaml)
    end

    it 'reads biome_executable from runner config' do
      expect(config.biome_executable).to eq('./node_modules/.bin/biome')
    end

    it 'converts string files_to_lint to Regexp' do
      expect(config.files_to_lint).to eq(/\.vue$/)
    end
  end

  describe 'files_to_lint with array of extensions' do
    let(:runner_yaml) do
      <<~YAML
        files_to_lint:
          - js
          - ts
          - vue
      YAML
    end

    before do
      allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
      allow(File).to receive(:read).with('/tmp/repo/.pronto_biome.yml').and_return(runner_yaml)
    end

    it 'converts array to Regexp' do
      expect(config.files_to_lint).to eq(/\.(js|ts|vue)$/)
    end

    it 'matches files with those extensions' do
      expect(config.lint_file?('app.js')).to be true
      expect(config.lint_file?('app.ts')).to be true
      expect(config.lint_file?('app.vue')).to be true
      expect(config.lint_file?('app.css')).to be false
    end
  end

  describe 'files_to_lint with dotted extensions in array' do
    let(:runner_yaml) do
      <<~YAML
        files_to_lint:
          - .js
          - .ts
      YAML
    end

    before do
      allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
      allow(File).to receive(:read).with('/tmp/repo/.pronto_biome.yml').and_return(runner_yaml)
    end

    it 'strips leading dots from extensions' do
      expect(config.lint_file?('app.js')).to be true
      expect(config.lint_file?('app.ts')).to be true
    end
  end

  describe 'config priority' do
    let(:pronto_config) do
      {
        'biome' => {
          'biome_executable' => 'from-pronto',
          'cmd_line_opts' => '--from-pronto'
        }
      }
    end

    let(:runner_yaml) do
      <<~YAML
        biome_executable: from-runner
      YAML
    end

    before do
      allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
      allow(File).to receive(:read).with('/tmp/repo/.pronto_biome.yml').and_return(runner_yaml)
    end

    it 'runner config overrides pronto config' do
      expect(config.biome_executable).to eq('from-runner')
    end

    it 'pronto config is used when runner config does not specify option' do
      expect(config.cmd_line_opts).to eq('--from-pronto')
    end
  end

  describe '#lint_file?' do
    it 'returns true for matching files' do
      expect(config.lint_file?('/path/to/file.js')).to be true
      expect(config.lint_file?('/path/to/file.ts')).to be true
      expect(config.lint_file?('/path/to/file.json')).to be true
    end

    it 'returns false for non-matching files' do
      expect(config.lint_file?('/path/to/file.css')).to be false
      expect(config.lint_file?('/path/to/file.rb')).to be false
    end
  end
end
