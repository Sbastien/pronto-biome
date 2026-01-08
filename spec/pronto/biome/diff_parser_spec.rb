# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pronto::Biome::DiffParser do
  describe '#valid?' do
    it 'is valid with complete diff structure' do
      parser = described_class.new(format_diagnostic(delete_text: ';'))
      expect(parser.valid?).to be true
    end

    it 'is invalid without diff' do
      parser = described_class.new({ 'advices' => { 'advices' => [] } })
      expect(parser.valid?).to be false
    end
  end

  describe '#first_change_line' do
    it 'defaults to 1 without diff' do
      parser = described_class.new({})
      expect(parser.first_change_line).to eq(1)
    end

    it 'accounts for equalLines before change' do
      parser = described_class.new(format_diagnostic(equal_lines: 10, delete_text: ';'))
      expect(parser.first_change_line).to eq(12) # 1 + 10 + 1
    end
  end

  describe '#changes' do
    it 'describes deletions' do
      parser = described_class.new(format_diagnostic(delete_text: ';'))
      expect(parser.changes).to eq(['remove `;`'])
    end

    it 'describes insertions' do
      parser = described_class.new(format_diagnostic(insert_text: 'const'))
      expect(parser.changes).to eq(['add `const`'])
    end

    it 'ignores whitespace-only changes' do
      parser = described_class.new(format_diagnostic(delete_text: '   '))
      expect(parser.changes).to be_empty
    end

    it 'limits to MAX_CHANGES and dedupes' do
      diagnostic = {
        'advices' => {
          'advices' => [{
            'diff' => {
              'dictionary' => ';;;;',
              'ops' => (0..3).map { |i| { 'diffOp' => { 'delete' => { 'range' => [i, i + 1] } } } }
            }
          }]
        }
      }
      parser = described_class.new(diagnostic)
      expect(parser.changes).to eq(['remove `;`']) # deduped
    end
  end

  private

  def format_diagnostic(equal_lines: 0, delete_text: nil, insert_text: nil)
    ops = []
    dictionary = ''

    ops << { 'equalLines' => { 'line_count' => equal_lines } } if equal_lines.positive?

    if delete_text
      ops << { 'diffOp' => { 'delete' => { 'range' => [dictionary.length, dictionary.length + delete_text.length] } } }
      dictionary += delete_text
    end

    if insert_text
      ops << { 'diffOp' => { 'insert' => { 'range' => [dictionary.length, dictionary.length + insert_text.length] } } }
      dictionary += insert_text
    end

    { 'advices' => { 'advices' => [{ 'diff' => { 'dictionary' => dictionary, 'ops' => ops } }] } }
  end
end
