# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Biome output integration', :integration do
  let(:temp_dir) { Dir.mktmpdir('pronto-biome-test') }
  let(:biome_executable) { ENV.fetch('BIOME_EXECUTABLE', 'biome') }

  after { FileUtils.remove_entry(temp_dir) }

  def run_biome(file_content, filename: 'test.js')
    file_path = File.join(temp_dir, filename)
    File.write(file_path, file_content)

    output = `#{biome_executable} check --reporter=json #{file_path} 2>/dev/null`
    return nil if output.empty?

    JSON.parse(output)
  rescue JSON::ParserError
    nil
  end

  describe 'lint error output structure' do
    let(:code_with_unused_var) do
      <<~JS
        const unused = 42;
        console.log("hello");
      JS
    end

    it 'produces diagnostics with expected structure' do
      result = run_biome(code_with_unused_var)
      skip 'Biome not available' if result.nil?

      expect(result).to have_key('diagnostics')
      expect(result['diagnostics']).to be_an(Array)
    end

    it 'includes location with span and sourceCode' do
      result = run_biome(code_with_unused_var)
      skip 'Biome not available' if result.nil?
      skip 'No diagnostics returned' if result['diagnostics'].empty?

      diagnostic = result['diagnostics'].first
      expect(diagnostic).to have_key('location')
      expect(diagnostic['location']).to have_key('span')
      expect(diagnostic['location']).to have_key('sourceCode')
    end

    it 'span is an array of two integers' do
      result = run_biome(code_with_unused_var)
      skip 'Biome not available' if result.nil?
      skip 'No diagnostics returned' if result['diagnostics'].empty?

      span = result['diagnostics'].first.dig('location', 'span')
      expect(span).to be_an(Array)
      expect(span.length).to eq(2)
      expect(span).to all(be_an(Integer))
    end

    it 'is parseable by our Offense class' do
      result = run_biome(code_with_unused_var)
      skip 'Biome not available' if result.nil?
      skip 'No diagnostics returned' if result['diagnostics'].empty?

      offense = Pronto::Biome::Offense.new(result['diagnostics'].first)
      expect(offense.valid?).to be true
      expect(offense.line_range).not_to be_nil
      expect(offense.level).to be_a(Symbol)
      expect(offense.message).to be_a(String)
    end
  end

  describe 'format error output structure' do
    let(:code_with_format_issue) do
      # Intentionally badly formatted
      'const x=1;const y=2;'
    end

    it 'produces format diagnostics with diff structure' do
      # Need biome.json to enable formatting checks
      biome_config = File.join(temp_dir, 'biome.json')
      File.write(biome_config, '{"formatter":{"enabled":true}}')

      result = run_biome(code_with_format_issue)
      skip 'Biome not available' if result.nil?

      format_diagnostic = result['diagnostics']&.find { |d| d['category'] == 'format' }
      skip 'No format diagnostic returned' if format_diagnostic.nil?

      expect(format_diagnostic).to have_key('advices')
      expect(format_diagnostic.dig('advices', 'advices')).to be_an(Array)
    end
  end

  describe 'severity mapping' do
    let(:code_with_error) do
      # debugger statement is typically an error
      <<~JS
        debugger;
        console.log("test");
      JS
    end

    it 'maps Biome severity to Pronto level' do
      result = run_biome(code_with_error)
      skip 'Biome not available' if result.nil?
      skip 'No diagnostics returned' if result['diagnostics'].empty?

      diagnostic = result['diagnostics'].first
      offense = Pronto::Biome::Offense.new(diagnostic)

      # Verify severity is properly mapped
      expect(%i[fatal error warning info]).to include(offense.level)
    end
  end

  describe 'multiple file types' do
    {
      'js' => "const x = 1;\nconsole.log(x);\n",
      'ts' => "const x: number = 1;\nconsole.log(x);\n",
      'jsx' => "const App = () => <div>Hello</div>;\nexport default App;\n",
      'tsx' => "const App = (): JSX.Element => <div>Hello</div>;\nexport default App;\n",
      'mjs' => "const x = 1;\nconsole.log(x);\n",
      'cjs' => "const x = 1;\nconsole.log(x);\n"
    }.each do |ext, code|
      context "with .#{ext} file" do
        it "successfully lints .#{ext} files" do
          result = run_biome(code, filename: "test.#{ext}")
          skip 'Biome not available' if result.nil?

          expect(result).to have_key('diagnostics')
        end
      end
    end
  end

  describe 'JSON linting' do
    let(:invalid_json) do
      # JSON with trailing comma (invalid)
      '{"key": "value",}'
    end

    let(:valid_json) do
      # Properly formatted JSON (with newline at end)
      <<~JSON
        { "key": "value" }
      JSON
    end

    it 'reports errors in invalid JSON' do
      result = run_biome(invalid_json, filename: 'test.json')
      skip 'Biome not available' if result.nil?

      # Biome should report an error for trailing comma
      expect(result['diagnostics']).not_to be_empty
    end

    it 'reports no lint errors for valid JSON' do
      result = run_biome(valid_json, filename: 'test.json')
      skip 'Biome not available' if result.nil?

      # Filter out format-only diagnostics (we only care about lint errors here)
      lint_errors = result['diagnostics'].reject { |d| d['category'] == 'format' }
      expect(lint_errors).to be_empty
    end
  end

  describe 'line number calculation' do
    let(:code_with_error_on_line_three) do
      <<~JS
        const a = 1;
        const b = 2;
        const unused = 3;
        console.log(a, b);
      JS
    end

    it 'correctly calculates line number from span' do
      result = run_biome(code_with_error_on_line_three)
      skip 'Biome not available' if result.nil?

      unused_diagnostic = result['diagnostics']&.find do |d|
        d['description']&.include?('unused') || d['category']&.include?('noUnused')
      end
      skip 'No unused variable diagnostic returned' if unused_diagnostic.nil?

      offense = Pronto::Biome::Offense.new(unused_diagnostic)

      # The 'unused' variable is on line 3
      expect(offense.line_range).to cover(3)
    end
  end
end
