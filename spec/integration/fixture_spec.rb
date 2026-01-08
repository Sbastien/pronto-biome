# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Fixture-based integration', :integration do
  include_context 'test repo'

  # Simulate a PR: diff between feature branch and main
  let(:patches) { repo.diff('main') }
  let(:runner) { Pronto::Biome.new(patches) }

  describe '#run' do
    subject(:messages) { runner.run }

    it 'detects errors in new and modified files' do
      expect(messages).not_to be_empty
    end

    it 'reports errors from multiple files' do
      paths = messages.map(&:path).uniq
      expect(paths.size).to be > 1
    end

    describe 'lint errors' do
      it 'detects unused variables' do
        unused_msg = messages.find { |m| m.msg.include?('unused') || m.msg.include?('Unused') }
        expect(unused_msg).not_to be_nil
        expect(unused_msg.level).to eq(:warning)
      end

      it 'detects debugger statements' do
        debugger_msg = messages.find { |m| m.msg.include?('debugger') }
        expect(debugger_msg).not_to be_nil
        expect(debugger_msg.level).to eq(:error)
      end

      it 'detects eval usage (security)' do
        eval_msg = messages.find { |m| m.msg.include?('eval') }
        expect(eval_msg).not_to be_nil
        expect(eval_msg.level).to eq(:error)
      end

      it 'detects duplicate switch cases' do
        duplicate_msg = messages.find { |m| m.msg.include?('Duplicate case') }
        expect(duplicate_msg).not_to be_nil
      end

      it 'detects comparison with NaN' do
        nan_msg = messages.find { |m| m.msg.include?('NaN') || m.msg.include?('isNaN') }
        expect(nan_msg).not_to be_nil
      end

      it 'detects constant conditions' do
        constant_msg = messages.find { |m| m.msg.include?('constant condition') }
        expect(constant_msg).not_to be_nil
      end
    end

    describe 'a11y errors' do
      it 'detects missing alt on images' do
        alt_msg = messages.find { |m| m.msg.include?('alt') || m.msg.include?('useAltText') }
        expect(alt_msg).not_to be_nil
      end

      it 'detects invalid anchor href' do
        anchor_msg = messages.find { |m| m.msg.include?('anchor') || m.msg.include?('useValidAnchor') }
        expect(anchor_msg).not_to be_nil
      end

      it 'detects autofocus usage' do
        autofocus_msg = messages.find { |m| m.msg.include?('autoFocus') || m.msg.include?('autofocus') }
        expect(autofocus_msg).not_to be_nil
      end

      it 'detects positive tabIndex' do
        tabindex_msg = messages.find { |m| m.msg.include?('tabIndex') || m.msg.include?('noPositiveTabindex') }
        expect(tabindex_msg).not_to be_nil
      end
    end

    describe 'style errors' do
      it 'detects Node.js imports without node: protocol' do
        import_msg = messages.find { |m| m.msg.include?('node:') || m.msg.include?('useNodejsImportProtocol') }
        expect(import_msg).not_to be_nil
      end
    end

    describe 'file filtering' do
      it 'only reports on added/modified lines' do
        # All messages should be on lines that were added in the feature branch
        messages.each do |msg|
          expect(msg.line.new_lineno).to be > 0
        end
      end

      it 'processes TypeScript files' do
        ts_messages = messages.select { |m| m.path.end_with?('.ts') }
        expect(ts_messages).not_to be_empty
      end

      it 'processes TSX files' do
        tsx_messages = messages.select { |m| m.path.end_with?('.tsx') }
        expect(tsx_messages).not_to be_empty
      end
    end

    describe 'message format' do
      it 'includes rule category in message' do
        categorized = messages.select { |m| m.msg.include?('/') }
        expect(categorized).not_to be_empty
      end

      it 'maps severity levels correctly' do
        levels = messages.map(&:level).uniq
        expect(levels).to include(:error)
        expect(levels).to include(:warning).or include(:info)
      end
    end
  end
end
