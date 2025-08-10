# Makefile for chezmoi brew bundle tests

# Default bats binary location
BATS ?= bats

# Test files
TEST_FILES = $(wildcard *.bats)

# Default target
.PHONY: all
all: test

# Run all tests
.PHONY: test
test: check-deps
	$(BATS) $(TEST_FILES)

# Run tests with verbose output
.PHONY: test-verbose
test-verbose: check-deps
	$(BATS) --verbose $(TEST_FILES)

# Run tests with tap output
.PHONY: test-tap
test-tap: check-deps
	$(BATS) --tap $(TEST_FILES)

# Run specific test file
.PHONY: test-template
test-template: check-deps
	$(BATS) brew_bundle_template.bats

.PHONY: test-files
test-files: check-deps
	$(BATS) chezmoi_files.bats

# Check if required dependencies are available
.PHONY: check-deps
check-deps:
	@echo "Checking dependencies..."
	@command -v chezmoi >/dev/null 2>&1 || { echo "chezmoi is required but not installed. Aborting." >&2; exit 1; }
	@command -v $(BATS) >/dev/null 2>&1 || { echo "bats is required but not installed. Run 'make install-bats' to install it. Aborting." >&2; exit 1; }
	@echo "All dependencies found."

# Install bats if not available
.PHONY: install-bats
install-bats:
	@echo "Installing bats..."
	@if command -v git >/dev/null 2>&1; then \
		git clone https://github.com/bats-core/bats-core.git /tmp/bats-core && \
		cd /tmp/bats-core && \
		./install.sh /usr/local && \
		rm -rf /tmp/bats-core; \
	else \
		echo "git is required to install bats. Please install git first."; \
		exit 1; \
	fi

# Install shellcheck for additional linting
.PHONY: install-shellcheck
install-shellcheck:
	@echo "Installing shellcheck..."
	@if command -v apt-get >/dev/null 2>&1; then \
		sudo apt-get update && sudo apt-get install -y shellcheck; \
	elif command -v brew >/dev/null 2>&1; then \
		brew install shellcheck; \
	elif command -v pacman >/dev/null 2>&1; then \
		sudo pacman -S shellcheck; \
	else \
		echo "Please install shellcheck manually for your distribution."; \
	fi

# Clean up temporary files
.PHONY: clean
clean:
	@echo "Cleaning up..."
	@find . -name "*.tmp" -delete
	@find . -name "*.bak" -delete
	@rm -rf /tmp/bats-*

# Show help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  test          - Run all tests"
	@echo "  test-verbose  - Run tests with verbose output"
	@echo "  test-tap      - Run tests with TAP output"
	@echo "  test-template - Run template tests only"
	@echo "  test-files    - Run file validation tests only"
	@echo "  check-deps    - Check if required dependencies are installed"
	@echo "  install-bats  - Install bats testing framework"
	@echo "  install-shellcheck - Install shellcheck for linting"
	@echo "  clean         - Clean up temporary files"
	@echo "  help          - Show this help message"
