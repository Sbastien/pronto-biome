# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pronto::Biome do
  subject(:runner) { described_class.new(patches) }

  let(:patches) { nil }
  let(:repo) { instance_double(Pronto::Git::Repository, path: '/tmp/repo') }
  let(:pronto_config) { {} }

  before do
    allow(Pronto::ConfigFile).to receive(:new).and_return(
      instance_double(Pronto::ConfigFile, to_h: pronto_config)
    )
  end

  describe '#run' do
    context 'when patches is nil' do
      it 'returns empty array' do
        expect(runner.run).to eq([])
      end
    end

    context 'when patches is empty' do
      let(:patches) { [] }

      it 'returns empty array' do
        expect(runner.run).to eq([])
      end
    end

    context 'with patch that has no additions' do
      let(:patch) do
        instance_double(
          Pronto::Git::Patch,
          additions: 0,
          new_file_full_path: Pathname.new('/tmp/repo/app.js'),
          repo: repo
        )
      end
      let(:patches) { [patch] }

      it 'skips patches without additions' do
        expect(runner.run).to eq([])
      end
    end

    context 'with non-JS file' do
      let(:patch) do
        instance_double(
          Pronto::Git::Patch,
          additions: 1,
          new_file_full_path: Pathname.new('/tmp/repo/style.css'),
          repo: repo
        )
      end
      let(:patches) { [patch] }

      before { stub_runner_config(false) }

      it 'skips non-JS files' do
        expect(runner.run).to eq([])
      end
    end

    %w[js ts jsx tsx mjs cjs json jsonc].each do |ext|
      context "with .#{ext} file" do
        let(:patch) { create_patch("app.#{ext}") }
        let(:patches) { [patch] }
        let(:biome_output) { biome_json_with_offense(line: 5) }

        before { stub_biome(biome_output) }

        it "processes .#{ext} files" do
          expect(runner.run.size).to eq(1)
        end
      end
    end

    context 'when offense is on an added line' do
      let(:patch) { create_patch('app.js', added_lines: [5, 6, 7]) }
      let(:patches) { [patch] }
      let(:biome_output) { biome_json_with_offense(line: 6) }

      before { stub_biome(biome_output) }

      it 'reports the offense' do
        messages = runner.run

        expect(messages.size).to eq(1)
        expect(messages.first.line.new_lineno).to eq(6)
      end
    end

    context 'when offense is NOT on an added line' do
      let(:patch) { create_patch('app.js', added_lines: [10, 11, 12]) }
      let(:patches) { [patch] }
      let(:biome_output) { biome_json_with_offense(line: 5) }

      before { stub_biome(biome_output) }

      it 'does not report the offense' do
        expect(runner.run).to eq([])
      end
    end

    context 'with multi-line offense' do
      let(:patch) { create_patch('app.js', added_lines: [5, 6, 7, 8]) }
      let(:patches) { [patch] }
      let(:biome_output) do
        {
          'diagnostics' => [offense_hash_multiline(start_line: 5, end_line: 8)]
        }.to_json
      end

      before { stub_biome(biome_output) }

      it 'reports using the last added line in range' do
        messages = runner.run

        expect(messages.size).to eq(1)
        expect(messages.first.line.new_lineno).to eq(8)
      end
    end

    context 'with multi-line offense partially on added lines' do
      let(:patch) { create_patch('app.js', added_lines: [6, 7]) }
      let(:patches) { [patch] }
      let(:biome_output) do
        {
          'diagnostics' => [offense_hash_multiline(start_line: 5, end_line: 8)]
        }.to_json
      end

      before { stub_biome(biome_output) }

      it 'reports if any line in range is added' do
        messages = runner.run

        expect(messages.size).to eq(1)
        expect(messages.first.line.new_lineno).to eq(7)
      end
    end

    context 'with multiple offenses' do
      let(:patch) { create_patch('app.js', added_lines: [5, 10, 15]) }
      let(:patches) { [patch] }
      let(:file) { 'app.js' }
      let(:biome_output) do
        {
          'diagnostics' => [
            offense_hash(line: 5, category: 'lint/error1', file: file),
            offense_hash(line: 8, category: 'lint/error2', file: file),
            offense_hash(line: 10, category: 'lint/error3', file: file),
            offense_hash(line: 20, category: 'lint/error4', file: file)
          ]
        }.to_json
      end

      before { stub_biome(biome_output) }

      it 'reports only offenses on added lines' do
        messages = runner.run

        expect(messages.size).to eq(2)
        expect(messages.map { |m| m.line.new_lineno }).to contain_exactly(5, 10)
      end
    end

    context 'with different severity levels' do
      let(:patch) { create_patch('app.js', added_lines: [5, 10, 15, 20, 25]) }
      let(:patches) { [patch] }
      let(:file) { 'app.js' }
      let(:biome_output) do
        {
          'diagnostics' => [
            offense_hash(line: 5, severity: 'fatal', file: file),
            offense_hash(line: 10, severity: 'error', file: file),
            offense_hash(line: 15, severity: 'warning', file: file),
            offense_hash(line: 20, severity: 'information', file: file),
            offense_hash(line: 25, severity: 'hint', file: file)
          ]
        }.to_json
      end

      before { stub_biome(biome_output) }

      it 'maps severity levels correctly' do
        messages = runner.run

        expect(messages.map(&:level)).to contain_exactly(:fatal, :error, :warning, :info, :info)
      end
    end

    context 'with unknown severity level' do
      let(:patch) { create_patch('app.js', added_lines: [5]) }
      let(:patches) { [patch] }
      let(:file) { 'app.js' }
      let(:biome_output) do
        {
          'diagnostics' => [
            offense_hash(line: 5, severity: 'unknown_level', file: file)
          ]
        }.to_json
      end

      before { stub_biome(biome_output) }

      it 'defaults to warning severity' do
        messages = runner.run

        expect(messages.first.level).to eq(:warning)
      end
    end

    context 'when biome returns empty output' do
      let(:patch) { create_patch('app.js') }
      let(:patches) { [patch] }

      before { stub_biome('') }

      it 'returns empty array' do
        expect(runner.run).to eq([])
      end
    end

    context 'when biome returns invalid JSON' do
      let(:patch) { create_patch('app.js') }
      let(:patches) { [patch] }

      before { stub_biome('not valid json') }

      it 'returns empty array without raising' do
        expect(runner.run).to eq([])
      end
    end

    context 'when biome returns no diagnostics' do
      let(:patch) { create_patch('app.js') }
      let(:patches) { [patch] }
      let(:biome_output) { { 'diagnostics' => [] }.to_json }

      before { stub_biome(biome_output) }

      it 'returns empty array' do
        expect(runner.run).to eq([])
      end
    end
  end

  describe 'message format' do
    let(:patch) { create_patch('app.js') }
    let(:patches) { [patch] }

    context 'with category and description' do
      let(:biome_output) do
        biome_json_with_offense(
          line: 5,
          category: 'lint/correctness/useParseIntRadix',
          description: 'Missing radix parameter'
        )
      end

      before { stub_biome(biome_output) }

      it 'includes category and description in message' do
        message = runner.run.first

        expect(message.msg).to eq('lint/correctness/useParseIntRadix: Missing radix parameter')
      end
    end

    context 'with only description' do
      let(:biome_output) do
        {
          'diagnostics' => [
            {
              'severity' => 'error',
              'description' => 'Some error',
              'location' => location_for_line(5)
            }
          ]
        }.to_json
      end

      before { stub_biome(biome_output) }

      it 'uses description as message' do
        message = runner.run.first

        expect(message.msg).to eq('Some error')
      end
    end
  end

  describe 'VERSION' do
    it 'has a version number' do
      expect(Pronto::BiomeVersion::VERSION).not_to be_nil
    end

    it 'follows semantic versioning' do
      expect(Pronto::BiomeVersion::VERSION).to match(/^\d+\.\d+\.\d+$/)
    end
  end

  # Helper methods

  def create_patch(filename, added_lines: [5])
    delta = delta_for(filename)
    lines = added_lines.map do |lineno|
      line_patch = instance_double(Pronto::Git::Patch, delta: delta)
      instance_double(Pronto::Git::Line, new_lineno: lineno, patch: line_patch, commit_sha: 'abc123')
    end

    instance_double(
      Pronto::Git::Patch,
      additions: added_lines.size,
      new_file_full_path: Pathname.new("/tmp/repo/#{filename}"),
      delta: delta,
      added_lines: lines,
      repo: repo
    )
  end

  def delta_for(filename)
    instance_double(Rugged::Diff::Delta, new_file: { path: filename })
  end

  def stub_runner_config(exists)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/tmp/repo/.pronto_biome.yml').and_return(exists)
  end

  def stub_biome(output)
    stub_runner_config(false)
    allow(Dir).to receive(:chdir).and_yield
    allow_any_instance_of(Pronto::Biome::Executor).to receive(:`).and_return(output)
  end

  def biome_json_with_offense(line:, category: 'lint/test', description: 'Test error', severity: 'warning', file: nil)
    # Use relative path to match Biome's output format
    file ||= patch.delta.new_file[:path]
    {
      'diagnostics' => [offense_hash(line: line, category: category, description: description, severity: severity, file: file)]
    }.to_json
  end

  def offense_hash(line:, category: 'lint/test', description: 'Test error', severity: 'warning', file: 'app.js')
    {
      'category' => category,
      'severity' => severity,
      'description' => description,
      'location' => location_for_line(line, file)
    }
  end

  def offense_hash_multiline(start_line:, end_line:, category: 'lint/test', description: 'Test error', severity: 'warning',
                             file: 'app.js')
    {
      'category' => category,
      'severity' => severity,
      'description' => description,
      'location' => location_for_range(start_line, end_line, file)
    }
  end

  def location_for_line(line, file = 'app.js')
    location_for_range(line, line, file)
  end

  def location_for_range(start_line, end_line, file = 'app.js')
    # Build source code with enough lines
    max_line = [start_line, end_line].max
    source_lines = (1..max_line).map { |n| "line #{n};\n" }
    source_code = source_lines.join

    # Calculate offsets - end_offset should be within the end_line, not past it
    start_offset = source_lines[0...(start_line - 1)].join.length
    # Point to middle of end_line (before the newline)
    end_offset = source_lines[0...(end_line - 1)].join.length + 5

    {
      'path' => { 'file' => file },
      'span' => [start_offset, end_offset],
      'sourceCode' => source_code
    }
  end
end
