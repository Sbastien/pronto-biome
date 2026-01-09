# frozen_string_literal: true

module Pronto
  class Biome < Runner
    # Finds the first added line within a given line range in a patch.
    #
    # When Biome reports a diagnostic spanning multiple lines, we need to
    # find the first added line within that range to attach the Pronto message.
    # We search from the end of the range to find the most relevant line
    # (typically where the error actually occurs).
    class AddedLineResolver
      def initialize(patch)
        @patch = patch
        @added_lines_by_lineno = index_added_lines
      end

      # Finds the first added line within the given range.
      # Returns nil if no added line exists in the range.
      def find_in_range(line_range)
        line_range.to_a.reverse_each do |lineno|
          line = @added_lines_by_lineno[lineno]
          return line if line
        end
        nil
      end

      private

      def index_added_lines
        @patch.added_lines.each_with_object({}) do |line, hash|
          hash[line.new_lineno] = line
        end
      end
    end
  end
end
