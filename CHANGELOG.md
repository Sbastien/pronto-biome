# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Support both Biome 1.x and 2.x JSON diagnostic formats
- Normalize absolute and relative diagnostic paths before matching changed files
- Correct line resolution for multibyte UTF-8 source code with Biome 1.x
- Disable Biome's default 20-diagnostic output limit

## [0.1.1] - 2026-01-12

### Fixed

- Suppress Biome's non-actionable stderr warnings (e.g., "--json option is unstable")

## [0.1.0] - 2026-01-09

### Added

- Pronto runner for Biome linter
- Support for JS, TS, JSX, TSX, JSON files
- Configuration via `.pronto.yml` or `.pronto_biome.yml`
- `BIOME_EXECUTABLE` environment variable
