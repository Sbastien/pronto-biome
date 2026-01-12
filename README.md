# pronto-biome

[![Gem Version](https://badge.fury.io/rb/pronto-biome.svg)](https://badge.fury.io/rb/pronto-biome)
[![CI](https://github.com/Sbastien/pronto-biome/actions/workflows/ci.yml/badge.svg)](https://github.com/Sbastien/pronto-biome/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

[Pronto](https://github.com/prontolabs/pronto) runner for [Biome](https://biomejs.dev/). Reports lint errors only on the lines you changed — perfect for gradual adoption in legacy codebases.

## Installation

Add to your Gemfile:

```ruby
gem 'pronto-biome'
```

Then install dependencies:

```bash
bundle install
npm install -D @biomejs/biome  # or: pnpm add -D @biomejs/biome
```

## Usage

```bash
pronto run -c origin/main --runner biome
```

## Configuration

### Option 1: `.pronto.yml` (recommended)

```yaml
biome:
  biome_executable: npx biome
  cmd_line_opts: '--config-path=custom-biome.json'
```

### Option 2: `.pronto_biome.yml` (takes priority)

```yaml
biome_executable: ./node_modules/.bin/biome
```

### Options

| Option             | Description                    | Default  |
|--------------------|--------------------------------|----------|
| `biome_executable` | Command to run Biome           | `biome`  |
| `cmd_line_opts`    | Additional Biome CLI options   | *(none)* |

> **Note:** File filtering is handled by Biome's own configuration (`biome.json`). Use Biome's `include`/`exclude` options to control which files are linted.

### Environment Variables

| Variable           | Description                                      |
|--------------------|--------------------------------------------------|
| `BIOME_EXECUTABLE` | Override the Biome executable (useful for CI/CD) |

## Requirements

| Dependency | Version     |
|------------|-------------|
| Ruby       | >= 3.1      |
| Pronto     | ~> 0.11.0   |
| Biome      | Any version |

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/Sbastien/pronto-biome).

## License

[MIT License](LICENSE)
