# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pronto::Biome::Offense do
  describe '#valid?' do
    it 'is valid with span-based lint diagnostic' do
      offense = described_class.new(lint_diagnostic(line: 5))
      expect(offense.valid?).to be true
    end

    it 'is valid with format diagnostic' do
      offense = described_class.new(format_diagnostic)
      expect(offense.valid?).to be true
    end

    it 'is invalid without span or sourceCode' do
      offense = described_class.new({ 'category' => 'lint/test', 'location' => {} })
      expect(offense.valid?).to be false
    end

    it 'is invalid with span but no sourceCode' do
      offense = described_class.new({ 'location' => { 'span' => [0, 10] } })
      expect(offense.valid?).to be false
    end
  end

  describe '#line_range' do
    it 'extracts correct line from span' do
      offense = described_class.new(lint_diagnostic(line: 5))
      expect(offense.line_range).to eq(5..5)
    end

    it 'handles multi-line spans' do
      diagnostic = {
        'location' => {
          'span' => [7, 21],
          'sourceCode' => "line 1\nline 2\nline 3\nline 4\n"
        }
      }
      offense = described_class.new(diagnostic)
      expect(offense.line_range).to eq(2..4)
    end

    it 'defaults to line 1 for format diagnostic without diff' do
      diagnostic = { 'category' => 'format', 'location' => {}, 'advices' => { 'advices' => [] } }
      offense = described_class.new(diagnostic)
      expect(offense.line_range).to eq(1..1)
    end
  end

  describe '#level' do
    it 'maps Biome severities to Pronto levels' do
      expect(described_class.new(lint_diagnostic(line: 1, severity: 'fatal')).level).to eq(:fatal)
      expect(described_class.new(lint_diagnostic(line: 1, severity: 'error')).level).to eq(:error)
      expect(described_class.new(lint_diagnostic(line: 1, severity: 'warning')).level).to eq(:warning)
      expect(described_class.new(lint_diagnostic(line: 1, severity: 'information')).level).to eq(:info)
      expect(described_class.new(lint_diagnostic(line: 1, severity: 'hint')).level).to eq(:info)
    end

    it 'defaults unknown severity to :warning' do
      offense = described_class.new(lint_diagnostic(line: 1, severity: 'unknown'))
      expect(offense.level).to eq(:warning)
    end
  end

  describe '#message' do
    it 'formats lint message as "category: description"' do
      offense = described_class.new(lint_diagnostic(line: 1, category: 'lint/test', description: 'Bad'))
      expect(offense.message).to eq('lint/test: Bad')
    end

    it 'uses description only when no category' do
      diagnostic = lint_diagnostic(line: 1, description: 'Error')
      diagnostic.delete('category')
      expect(described_class.new(diagnostic).message).to eq('Error')
    end

    it 'describes format changes with actionable message' do
      offense = described_class.new(format_diagnostic(delete_text: ';'))
      expect(offense.message).to include('remove')
      expect(offense.message).to include('biome check --write')
    end

    it 'shows generic message for whitespace-only format changes' do
      offense = described_class.new(format_diagnostic(delete_text: '   '))
      expect(offense.message).to include('formatting')
    end
  end

  private

  def lint_diagnostic(line:, category: 'lint/test', description: 'Test error', severity: 'warning')
    source_lines = (1..line).map { |n| "line #{n};\n" }
    source_code = source_lines.join
    start_offset = source_lines[0...(line - 1)].join.length

    {
      'category' => category,
      'severity' => severity,
      'description' => description,
      'location' => {
        'span' => [start_offset, start_offset + 5],
        'sourceCode' => source_code
      }
    }
  end

  def format_diagnostic(delete_text: nil, insert_text: nil)
    ops = []
    dictionary = ''

    if delete_text
      ops << { 'diffOp' => { 'delete' => { 'range' => [0, delete_text.length] } } }
      dictionary = delete_text
    end

    if insert_text
      start = dictionary.length
      dictionary += insert_text
      ops << { 'diffOp' => { 'insert' => { 'range' => [start, dictionary.length] } } }
    end

    ops = [{ 'diffOp' => { 'insert' => { 'range' => [0, 1] } } }] if ops.empty?
    dictionary = 'x' if dictionary.empty?

    {
      'category' => 'format',
      'severity' => 'error',
      'location' => {},
      'advices' => { 'advices' => [{ 'diff' => { 'dictionary' => dictionary, 'ops' => ops } }] }
    }
  end
end
