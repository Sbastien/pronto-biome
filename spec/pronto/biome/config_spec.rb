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

    it 'has no default files_to_lint filter' do
      expect(config.files_to_lint).to be_nil
    end

    it 'has default cmd_line_opts' do
      expect(config.cmd_line_opts).to eq('')
    end
  end

  describe 'immutability' do
    it 'is frozen after initialization' do
      expect(config).to be_frozen
    end

    it 'has frozen attributes' do
      expect(config.biome_executable).to be_frozen
      expect(config.cmd_line_opts).to be_frozen
    end
  end

  describe 'environment variables' do
    around do |example|
      original = ENV.fetch('BIOME_EXECUTABLE', nil)
      ENV['BIOME_EXECUTABLE'] = 'custom-biome'
      example.run
      ENV['BIOME_EXECUTABLE'] = original
    end

    it 'reads biome_executable from BIOME_EXECUTABLE env var' do
      expect(config.biome_executable).to eq('custom-biome')
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
    let(:runner_config) do
      {
        'biome_executable' => './node_modules/.bin/biome',
        'files_to_lint' => '\\.vue$'
      }
    end

    before do
      allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
      allow(YAML).to receive(:safe_load_file).and_return(runner_config)
    end

    it 'reads biome_executable from runner config' do
      expect(config.biome_executable).to eq('./node_modules/.bin/biome')
    end

    it 'converts string files_to_lint to Regexp' do
      expect(config.files_to_lint).to eq(/\.vue$/)
    end
  end

  describe 'files_to_lint with array of extensions' do
    let(:runner_config) do
      { 'files_to_lint' => %w[js ts vue] }
    end

    before do
      allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
      allow(YAML).to receive(:safe_load_file).and_return(runner_config)
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
    let(:runner_config) do
      { 'files_to_lint' => %w[.js .ts] }
    end

    before do
      allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
      allow(YAML).to receive(:safe_load_file).and_return(runner_config)
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

    let(:runner_config) do
      { 'biome_executable' => 'from-runner' }
    end

    before do
      allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
      allow(YAML).to receive(:safe_load_file).and_return(runner_config)
    end

    it 'runner config overrides pronto config' do
      expect(config.biome_executable).to eq('from-runner')
    end

    it 'pronto config is used when runner config does not specify option' do
      expect(config.cmd_line_opts).to eq('--from-pronto')
    end
  end

  describe '#lint_file?' do
    context 'without files_to_lint configured' do
      it 'returns true for any file' do
        expect(config.lint_file?('/path/to/file.js')).to be true
        expect(config.lint_file?('/path/to/file.rb')).to be true
        expect(config.lint_file?('/path/to/file.py')).to be true
      end
    end

    context 'with files_to_lint configured' do
      let(:runner_config) do
        { 'files_to_lint' => %w[js ts] }
      end

      before do
        allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(true)
        allow(YAML).to receive(:safe_load_file).and_return(runner_config)
      end

      it 'returns true for matching files' do
        expect(config.lint_file?('/path/to/file.js')).to be true
        expect(config.lint_file?('/path/to/file.ts')).to be true
      end

      it 'returns false for non-matching files' do
        expect(config.lint_file?('/path/to/file.rb')).to be false
        expect(config.lint_file?('/path/to/file.css')).to be false
      end
    end
  end
end
