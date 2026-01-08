# frozen_string_literal: true

module Pronto
  class Biome < Runner
    # Parses Biome's diff structure and provides access to line numbers and changes.
    #
    # Biome diff structure:
    #   {
    #     "dictionary" => "const x = 1;\n",
    #     "ops" => [
    #       { "equalLines" => { "line_count" => 10 } },
    #       { "diffOp" => { "delete" => { "range" => [0, 5] } } }
    #     ]
    #   }
    class DiffParser
      MAX_CHANGES = 3

      attr_reader :first_change_line, :changes

      def initialize(diagnostic)
        @diff = diagnostic.dig('advices', 'advices', 0, 'diff')
        @first_change_line = 1
        @changes = []
        @found_first_change = false

        parse if valid?
      end

      def valid? = !@diff.nil? && @diff.key?('dictionary') && @diff.key?('ops')

      private

      def parse
        @current_line = 1
        @diff['ops'].each { |op| process(op) }
      end

      def process(op)
        if (count = op.dig('equalLines', 'line_count'))
          @current_line += count
        elsif (range = op.dig('diffOp', 'equal', 'range'))
          @current_line += newline_count(range)
        elsif (range = op.dig('diffOp', 'delete', 'range'))
          handle_change(:delete, range)
        elsif (range = op.dig('diffOp', 'insert', 'range'))
          handle_change(:insert, range)
        end
      end

      def handle_change(type, range)
        unless @found_first_change
          @first_change_line = @current_line + 1
          @found_first_change = true
        end
        record_change(type, range)
      end

      def newline_count(range)
        text = dictionary_text(range)
        text&.count("\n") || 0
      end

      def record_change(type, range)
        return if @changes.size >= MAX_CHANGES

        text = dictionary_text(range)
        return unless text && !text.strip.empty?

        label = type == :delete ? 'remove' : 'add'
        change = "#{label} `#{text.inspect[1..-2]}`"
        @changes << change unless @changes.include?(change)
      end

      def dictionary_text(range) = @diff['dictionary'][range[0]...range[1]]
    end
  end
end
