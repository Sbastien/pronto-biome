# pronto-biome

[![Gem Version](https://badge.fury.io/rb/pronto-biome.svg)](https://badge.fury.io/rb/pronto-biome)
[![CI](https://github.com/Sbastien/pronto-biome/actions/workflows/ci.yml/badge.svg)](https://github.com/Sbastien/pronto-biome/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[Pronto](https://github.com/prontolabs/pronto) runner for [Biome](https://biomejs.dev/).

## Why pronto-biome?

Unlike `biome check --changed` which reports all errors in changed files, pronto-biome only reports errors on the **actual lines you modified**. Perfect for legacy codebases and gradual Biome adoption.

## Installation

```ruby
# Gemfile
gem 'pronto-biome'
```

```bash
bundle install
npm install -D @biomejs/biome
```

## Usage

```bash
pronto run -c origin/main            # Changes since origin/main
pronto run --staged                  # Staged changes only
pronto run -c origin/main -f github_pr  # GitHub PR comments
```

## Configuration

Configure in `.pronto.yml` (recommended):

```yaml
biome:
  biome_executable: npx biome
  files_to_lint: '\.(js|ts|jsx|tsx|vue)$'
  cmd_line_opts: '--config-path=custom-biome.json'
```

Or in `.pronto_biome.yml` (takes priority):

```yaml
biome_executable: ./node_modules/.bin/biome
files_to_lint: '\.(js|ts|jsx|tsx)$'
```

**Options:**

- `biome_executable` - Command to run Biome (default: `biome`)
- `files_to_lint` - Regex for files to lint (default: JS/TS/JSON extensions)
- `cmd_line_opts` - Additional Biome CLI options

## Supported Files

`.js`, `.ts`, `.jsx`, `.tsx`, `.mjs`, `.cjs`, `.json`, `.jsonc`

## Requirements

- Ruby >= 2.7
- Pronto ~> 0.11.0
- Biome

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/Sbastien/pronto-biome).

## License

[MIT License](LICENSE)
