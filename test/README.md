# Chezmoi Brew Bundle Tests

This directory contains comprehensive tests for the chezmoi brew bundle integration using the [Bats](https://github.com/bats-core/bats-core) testing framework.

## Overview

The tests validate:
- Template rendering on different operating systems
- Shell syntax correctness of rendered scripts
- ShellCheck compliance (when available)
- Error handling and edge cases
- Integration with actual chezmoi files

## Test Files

- `test_helper.bash` - Common setup and helper functions
- `brew_bundle_template.bats` - Tests for template functionality
- `chezmoi_files.bats` - Tests for actual chezmoi files
- `Makefile` - Convenient commands for running tests

## Prerequisites

- `chezmoi` - The chezmoi dotfile manager
- `bats` - The Bats testing framework
- `shellcheck` - For shell script linting (optional but recommended)

## Quick Start

1. **Install dependencies:**
   ```bash
   make install-bats
   make install-shellcheck  # Optional but recommended
   ```

2. **Run all tests:**
   ```bash
   make test
   ```

3. **Run tests with verbose output:**
   ```bash
   make test-verbose
   ```

## Available Commands

```bash
# Run all tests
make test

# Run tests with verbose output
make test-verbose

# Run tests with TAP output (for CI)
make test-tap

# Run specific test suites
make test-template  # Template functionality tests
make test-files     # File validation tests

# Install dependencies
make install-bats
make install-shellcheck

# Check dependencies
make check-deps

# Clean up
make clean

# Show help
make help
```

## Test Coverage

### Template Functionality (`brew_bundle_template.bats`)

- ✅ Template renders correctly on Darwin with packages
- ✅ Template renders empty on non-Darwin systems
- ✅ Template handles missing packages data gracefully
- ✅ Rendered script has valid shell syntax
- ✅ Rendered script passes shellcheck
- ✅ Template includes proper error handling
- ✅ Template handles empty brew and cask lists

### File Validation (`chezmoi_files.bats`)

- ✅ Actual packages.yaml file is valid YAML
- ✅ Actual template file exists and is readable
- ✅ Actual template renders with actual packages data
- ✅ Actual template renders empty on Linux
- ✅ Actual rendered script passes shellcheck
- ✅ Actual rendered script has valid shell syntax
- ✅ packages.yaml contains expected font package
- ✅ Template file has correct chezmoi attributes

## Testing on Different Operating Systems

The tests use chezmoi's template system to simulate different operating systems:

- **Darwin (macOS)**: Tests that the script renders correctly and includes Homebrew commands
- **Linux**: Tests that the script renders empty (no Darwin condition met)

## Continuous Integration

The tests are designed to work in CI environments:

```bash
# Run tests with TAP output for CI
make test-tap
```

## Troubleshooting

### Bats not found
```bash
make install-bats
```

### ShellCheck not found
```bash
make install-shellcheck
```

### Chezmoi not found
Install chezmoi according to the [official documentation](https://chezmoi.io/getting-started/install/).

### Test failures
1. Check that all dependencies are installed: `make check-deps`
2. Run tests with verbose output: `make test-verbose`
3. Check the specific test file for more details

## Contributing

When adding new tests:

1. Follow the existing naming conventions
2. Add appropriate test descriptions
3. Include both positive and negative test cases
4. Test edge cases and error conditions
5. Update this README if adding new test categories
