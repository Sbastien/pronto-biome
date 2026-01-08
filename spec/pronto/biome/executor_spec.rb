# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pronto::Biome::Executor do
  subject(:executor) { described_class.new(config, '/tmp/repo') }

  let(:config) do
    instance_double(
      Pronto::Biome::Config,
      biome_executable: biome_executable,
      cmd_line_opts: cmd_line_opts
    )
  end
  let(:biome_executable) { 'biome' }
  let(:cmd_line_opts) { '' }

  def diagnostic(file_path, category = 'lint/test')
    {
      'category' => category,
      'location' => { 'path' => { 'file' => file_path } }
    }
  end

  describe '#run' do
    before do
      allow(Dir).to receive(:chdir).and_yield
      allow(executor).to receive(:`).and_return(output)
    end

    context 'with diagnostics from multiple files' do
      let(:output) do
        {
          'diagnostics' => [
            diagnostic('/tmp/repo/app.js', 'lint/error1'),
            diagnostic('/tmp/repo/app.js', 'lint/error2'),
            diagnostic('/tmp/repo/utils.js', 'lint/error3')
          ]
        }.to_json
      end

      it 'groups diagnostics by file path' do
        result = executor.run(['/tmp/repo/app.js', '/tmp/repo/utils.js'])

        expect(result['/tmp/repo/app.js'].size).to eq(2)
        expect(result['/tmp/repo/utils.js'].size).to eq(1)
      end

      it 'provides diagnostics_for specific file' do
        executor.run(['/tmp/repo/app.js', '/tmp/repo/utils.js'])

        expect(executor.diagnostics_for('/tmp/repo/app.js').size).to eq(2)
        expect(executor.diagnostics_for('/tmp/repo/utils.js').size).to eq(1)
        expect(executor.diagnostics_for('/tmp/repo/unknown.js')).to eq([])
      end
    end

    context 'with yarn wrapper output' do
      let(:output) do
        <<~OUTPUT
          yarn run v1.22.22
          {"diagnostics":[#{diagnostic('/tmp/repo/app.js').to_json}]}
          Done in 0.15s.
        OUTPUT
      end

      it 'extracts JSON from wrapped output' do
        executor.run(['/tmp/repo/app.js'])
        expect(executor.diagnostics_for('/tmp/repo/app.js').size).to eq(1)
      end
    end

    context 'with empty output' do
      let(:output) { '' }

      it 'returns empty hash' do
        expect(executor.run(['/tmp/repo/app.js'])).to eq({})
      end
    end

    context 'with empty file list' do
      let(:output) { '' }

      it 'returns empty hash without executing' do
        expect(executor).not_to receive(:`)
        expect(executor.run([])).to eq({})
      end
    end

    context 'with output containing no JSON' do
      let(:output) { 'not json at all' }

      it 'returns empty hash' do
        expect(executor.run(['/tmp/repo/app.js'])).to eq({})
      end
    end

    context 'with invalid JSON structure' do
      let(:output) { '{invalid json}' }

      it 'returns empty hash and logs warning' do
        expect(executor).to receive(:warn).with(/Failed to parse Biome output/)
        expect(executor.run(['/tmp/repo/app.js'])).to eq({})
      end
    end

    context 'with no diagnostics key' do
      let(:output) { { 'other' => 'data' }.to_json }

      it 'returns empty hash and logs warning' do
        expect(executor).to receive(:warn).with(/Biome output missing diagnostics key/)
        expect(executor.run(['/tmp/repo/app.js'])).to eq({})
      end
    end

    context 'with empty diagnostics' do
      let(:output) { { 'diagnostics' => [] }.to_json }

      it 'returns empty hash' do
        expect(executor.run(['/tmp/repo/app.js'])).to eq({})
      end
    end
  end

  describe 'command building' do
    let(:valid_output) { { 'diagnostics' => [] }.to_json }

    before do
      allow(Dir).to receive(:chdir).and_yield
    end

    context 'with single file' do
      it 'builds correct command' do
        expect(executor).to receive(:`).with('biome check --reporter=json /tmp/repo/app.js 2>/dev/null').and_return(valid_output)
        executor.run(['/tmp/repo/app.js'])
      end
    end

    context 'with multiple files' do
      it 'includes all files in command' do
        expected = 'biome check --reporter=json /tmp/repo/app.js /tmp/repo/utils.js 2>/dev/null'
        expect(executor).to receive(:`).with(expected).and_return(valid_output)
        executor.run(['/tmp/repo/app.js', '/tmp/repo/utils.js'])
      end
    end

    context 'with yarn executable' do
      let(:biome_executable) { 'yarn --silent biome' }

      it 'builds correct command' do
        expected = 'yarn --silent biome check --reporter=json /tmp/repo/app.js 2>/dev/null'
        expect(executor).to receive(:`).with(expected).and_return(valid_output)
        executor.run(['/tmp/repo/app.js'])
      end
    end

    context 'with custom cmd_line_opts' do
      let(:cmd_line_opts) { '--config-path=custom.json' }

      it 'includes options in command' do
        expected = 'biome check --config-path=custom.json --reporter=json /tmp/repo/app.js 2>/dev/null'
        expect(executor).to receive(:`).with(expected).and_return(valid_output)
        executor.run(['/tmp/repo/app.js'])
      end
    end

    context 'with file paths containing spaces' do
      it 'escapes all file paths' do
        expected = 'biome check --reporter=json /tmp/repo/my\\ file.js /tmp/repo/other\\ file.js 2>/dev/null'
        expect(executor).to receive(:`).with(expected).and_return(valid_output)
        executor.run(['/tmp/repo/my file.js', '/tmp/repo/other file.js'])
      end
    end
  end

  describe 'caching' do
    let(:output) do
      { 'diagnostics' => [diagnostic('/tmp/repo/app.js')] }.to_json
    end

    before do
      allow(Dir).to receive(:chdir).and_yield
      allow(executor).to receive(:`).and_return(output)
    end

    it 'caches results after first run' do
      executor.run(['/tmp/repo/app.js'])
      executor.run(['/tmp/repo/app.js', '/tmp/repo/other.js'])

      # Should only call the command once (first run)
      expect(executor).to have_received(:`).once
    end

    it 'returns diagnostics_for after run' do
      executor.run(['/tmp/repo/app.js'])
      expect(executor.diagnostics_for('/tmp/repo/app.js').size).to eq(1)
    end

    it 'returns empty array for diagnostics_for before run' do
      expect(executor.diagnostics_for('/tmp/repo/app.js')).to eq([])
    end

    describe '#clear_cache' do
      it 'clears cached results' do
        executor.run(['/tmp/repo/app.js'])
        executor.clear_cache
        executor.run(['/tmp/repo/app.js'])

        expect(executor).to have_received(:`).twice
      end
    end
  end
end
