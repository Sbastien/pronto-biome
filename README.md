# pronto-biome

[![Gem Version](https://badge.fury.io/rb/pronto-biome.svg)](https://badge.fury.io/rb/pronto-biome)
[![CI](https://github.com/Sbastien/pronto-biome/actions/workflows/ci.yml/badge.svg)](https://github.com/Sbastien/pronto-biome/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> [Pronto](https://github.com/prontolabs/pronto) runner for [Biome](https://biomejs.dev/) — lint only the lines you changed.

---

## Why pronto-biome?

Traditional linters report **all errors** in modified files. This creates noise in legacy codebases and slows down code reviews.

**pronto-biome** only reports errors on the **exact lines you modified**, making it perfect for:

- 🎯 **Gradual adoption** — Introduce Biome without fixing thousands of pre-existing issues
- 🔍 **Focused reviews** — See only what matters in your PR
- 🚀 **CI integration** — Post inline comments directly on GitHub PRs

---

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

---

## Usage

```bash
# Lint changes since origin/main
pronto run -c origin/main --runner biome

# Lint staged changes only
pronto run --staged --runner biome

# Post comments on GitHub PR
pronto run -c origin/main -f github_pr --runner biome
```

---

## Configuration

### Option 1: `.pronto.yml` (recommended)

```yaml
biome:
  biome_executable: npx biome
  files_to_lint: '\.(js|ts|jsx|tsx|vue)$'
  cmd_line_opts: '--config-path=custom-biome.json'
```

### Option 2: `.pronto_biome.yml` (takes priority)

```yaml
biome_executable: ./node_modules/.bin/biome
files_to_lint: '\.(js|ts|jsx|tsx)$'
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `biome_executable` | Command to run Biome | `biome` |
| `files_to_lint` | Regex pattern for files to lint | JS/TS/JSON extensions |
| `cmd_line_opts` | Additional Biome CLI options | *(none)* |

### Environment Variables

| Variable | Description |
|----------|-------------|
| `BIOME_EXECUTABLE` | Override the Biome executable (useful for CI/CD) |

---

## Supported Files

By default, pronto-biome lints files with these extensions:

`.js` · `.ts` · `.jsx` · `.tsx` · `.mjs` · `.cjs` · `.json` · `.jsonc` · `.css` · `.graphql` · `.gql`

---

## Requirements

| Dependency | Version |
|------------|---------|
| Ruby | >= 3.1 |
| Pronto | ~> 0.11.0 |
| Biome | Any version |

---

## Contributing

Bug reports and pull requests are welcome on [GitHub](https://github.com/Sbastien/pronto-biome).

## License

[MIT License](LICENSE)
