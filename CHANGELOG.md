# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed

- Support Biome 2.x `location.path` format (plain string) in addition to the
  legacy 1.x format (`{ "file" => "..." }`). Previously, running against
  Biome 2.x raised `TypeError: String does not have #dig method`.

## [0.1.1] - 2026-01-12

### Fixed

- Suppress Biome's non-actionable stderr warnings (e.g., "--json option is unstable")

## [0.1.0] - 2026-01-09

### Added

- Pronto runner for Biome linter
- Support for JS, TS, JSX, TSX, JSON files
- Configuration via `.pronto.yml` or `.pronto_biome.yml`
- `BIOME_EXECUTABLE` environment variable
