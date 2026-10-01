# frozen_string_literal: true

require_relative 'diff_parser'

module Pronto
  class Biome < Runner
    # Converts a Biome diagnostic into an offense with line range, level, and message.
    #
    # Biome diagnostics come in two flavors:
    # 1. Lint errors: Have a span (byte offsets) pointing to the exact location
    # 2. Format errors: No span, but have a diff structure showing what changed
    class Offense
      SEVERITY_MAP = {
        'fatal' => :fatal,
        'error' => :error,
        'warning' => :warning,
        'information' => :info,
        'hint' => :info
      }.freeze
      DEFAULT_SEVERITY = :warning

      attr_reader :line_range, :level, :message

      def initialize(diagnostic)
        @diagnostic = diagnostic
        @diff_parser = nil # Lazy loaded only for format diagnostics
        @line_range = compute_line_range
        @level = compute_level
        @message = compute_message
      end

      def valid? = file_wide? || !@line_range.nil?

      def file_wide? = @file_wide == true

      private

      def compute_line_range
        positioned_range = line_range_from_position if position
        return positioned_range if positioned_range
        return line_range_from_span if span
        return line_range_from_diff if format_diagnostic?

        nil
      end

      def span = @diagnostic.dig('location', 'span')

      def source_code = @diagnostic.dig('location', 'sourceCode')

      def position = @diagnostic.dig('location', 'start')

      def format_diagnostic? = @diagnostic['category'] == 'format'

      def diff_parser
        @diff_parser ||= DiffParser.new(@diagnostic)
      end

      # Converts byte offsets to line numbers by counting newlines.
      def line_range_from_span
        return nil unless source_code

        start_offset, end_offset = span
        start_line = source_code.byteslice(0...start_offset).count("\n") + 1
        end_line = source_code.byteslice(0...end_offset).count("\n") + 1

        start_line..end_line
      end

      def line_range_from_position
        start_line = position['line']
        end_line = @diagnostic.dig('location', 'end', 'line') || start_line
        return nil unless start_line.is_a?(Integer) && start_line.positive?

        end_line = start_line unless end_line.is_a?(Integer) && end_line.positive?
        start_line..[start_line, end_line].max
      end

      def line_range_from_diff
        if diff_parser.valid?
          line = diff_parser.first_change_line
          line..line
        else
          @file_wide = true
          nil
        end
      end

      def compute_level = SEVERITY_MAP.fetch(@diagnostic['severity'], DEFAULT_SEVERITY)

      def compute_message = format_diagnostic? ? format_message : lint_message

      def lint_message
        category = @diagnostic['category'] || ''
        description = @diagnostic['description'] || @diagnostic['message'] || ''
        category.empty? ? description : "#{category}: #{description}"
      end

      def format_message
        changes = diff_parser.changes
        return 'File needs formatting. Run `biome check --write` to fix.' if changes.empty?

        "Formatting: #{changes.join(', ')}. Run `biome check --write` to fix."
      end
    end
  end
end
