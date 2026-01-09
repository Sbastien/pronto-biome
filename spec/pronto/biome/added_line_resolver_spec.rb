# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pronto::Biome::AddedLineResolver do
  subject(:resolver) { described_class.new(patch) }

  let(:patch) { instance_double(Pronto::Git::Patch, added_lines: added_lines) }

  def line(lineno)
    instance_double(Pronto::Git::Line, new_lineno: lineno)
  end

  describe '#find_in_range' do
    context 'with multiple added lines' do
      let(:early_line) { line(5) }
      let(:middle_line) { line(10) }
      let(:late_line) { line(15) }
      let(:added_lines) { [early_line, middle_line, late_line] }

      it 'returns line when range contains single added line' do
        expect(resolver.find_in_range(9..11)).to eq(middle_line)
      end

      it 'returns last added line in range (searches from end)' do
        expect(resolver.find_in_range(5..15)).to eq(late_line)
      end

      it 'returns nil when no added line in range' do
        expect(resolver.find_in_range(6..9)).to be_nil
      end

      it 'returns line when range is exact match' do
        expect(resolver.find_in_range(10..10)).to eq(middle_line)
      end
    end

    context 'with no added lines' do
      let(:added_lines) { [] }

      it 'returns nil for any range' do
        expect(resolver.find_in_range(1..100)).to be_nil
      end
    end

    context 'with single added line' do
      let(:single_line) { line(7) }
      let(:added_lines) { [single_line] }

      it 'returns line when in range' do
        expect(resolver.find_in_range(1..10)).to eq(single_line)
      end

      it 'returns nil when out of range' do
        expect(resolver.find_in_range(8..10)).to be_nil
      end
    end

    context 'with consecutive added lines' do
      let(:first_line) { line(1) }
      let(:second_line) { line(2) }
      let(:third_line) { line(3) }
      let(:added_lines) { [first_line, second_line, third_line] }

      it 'returns last line in consecutive block' do
        expect(resolver.find_in_range(1..3)).to eq(third_line)
      end

      it 'returns middle line when range excludes last' do
        expect(resolver.find_in_range(1..2)).to eq(second_line)
      end
    end
  end
end
