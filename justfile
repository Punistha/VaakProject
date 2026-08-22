set shell := ["bash", "-uc"]

### Variables

gradle := "./gradlew"
build_dir := "app/build"
apk_source := build_dir / "outputs/apk/debug/app-debug.apk"
apk_target := "./vaak.apk"
kover_xml := build_dir / "reports/kover/reportDebug.xml"
kover_html := build_dir / "reports/kover/htmlDebug/index.html"

# Release management

github_repo_url := "https://github.com/amanhigh/vaak"
release_branch := "master"

# Output sink for noisy commands, override with `just out=/dev/stdout cover`

out := "/dev/null"

# Colored `[Title] message` helper

title := '\033[32m'
reset_color := '\033[0m'

### Basic

# Show available recipes
default:
    @just --list

### Formatting & Quality

# Format all Kotlin files with Spotless/ktlint
format:
    @printf "{{ title }}[Format]{{ reset_color }} Formatting Kotlin files\n"
    @{{ gradle }} spotlessApply

# Run Detekt static analysis
lint:
    @printf "{{ title }}[Lint]{{ reset_color }} Running lint checks\n"
    @{{ gradle }} detekt

### Testing

# Run unit tests
test:
    @printf "{{ title }}[Test]{{ reset_color }} Running Unit Tests\n"
    @{{ gradle }} test

# Run tests and generate coverage reports (HTML + XML + console)
cover: test
    @printf "{{ title }}[Coverage]{{ reset_color }} Generating coverage reports\n"
    @{{ gradle }} koverHtmlReportDebug koverXmlReportDebug > {{ out }} 2>&1
    @echo ""
    @printf "{{ title }}[Coverage]{{ reset_color }} Package Summary\n"
    @./scripts/coverage-report.sh {{ kover_xml }}
    @echo ""
    @printf "{{ title }}[Reports]{{ reset_color }} Coverage reports generated\n"
    @echo "  HTML: file://$PWD/{{ kover_html }} (detailed class/package coverage)"
    @echo "  XML:  file://$PWD/{{ kover_xml }} (CI integration)"

### APK Build

# Format sources, then build the APK
build: format
    @printf "{{ title }}[Build]{{ reset_color }} Building APK\n"
    @{{ gradle }} build

# Copy the built APK to the repository root
copy-apk:
    @printf "{{ title }}[Copy]{{ reset_color }} Copying APK to Root\n"
    @cp {{ apk_source }} {{ apk_target }}

# Install the APK onto the connected device/emulator
adb-install:
    @printf "{{ title }}[Install]{{ reset_color }} Installing APK via adb\n"
    @adb install -r {{ apk_target }}

# Test, build and copy the APK to the repository root
setup: test build copy-apk

# Build the APK and install it onto the connected device/emulator
install: setup adb-install

### Clean

# Remove the APK from the repository root
remove-apk:
    @printf "{{ title }}[Remove]{{ reset_color }} Removing APK from Root\n"
    @rm -f {{ apk_target }}

# Clean Gradle build outputs
clean-gradle:
    @printf "{{ title }}[Clean]{{ reset_color }} Cleaning Gradle\n"
    @{{ gradle }} clean

# Remove the APK and clean Gradle build outputs
clean: remove-apk clean-gradle

# Clean everything, then rebuild and reinstall the APK
reset: clean setup

### Release Management

[private]
check-version ver:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! echo "{{ ver }}" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "Error: Invalid version format. Must be X.Y.Z"
        echo "Usage: just [release|unrelease] X.Y.Z"
        exit 1
    fi

[private]
check-branch:
    #!/usr/bin/env bash
    set -euo pipefail
    current=$(git branch --show-current)
    if [ "$current" != "{{ release_branch }}" ]; then
        echo "Error: Releases must be created from {{ release_branch }} branch"
        echo "Current branch: $current"
        exit 1
    fi

[private]
check-clean:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -n "$(git status --porcelain)" ]; then
        echo "Error: Working directory is not clean"
        echo "Please commit or stash changes first"
        exit 1
    fi

# Create and push a new release version tag, e.g. `just release 1.0.0`
release ver: (check-version ver) check-branch check-clean
    @echo "Creating release v{{ ver }}..."
    @git tag -a v{{ ver }} -m "Release v{{ ver }}"
    @git push origin v{{ ver }}
    @echo "Release tag v{{ ver }} created and pushed successfully"

# Delete a release version tag locally and remotely, e.g. `just unrelease 1.0.0`
unrelease ver: (check-version ver)
    #!/usr/bin/env bash
    set -euo pipefail
    if ! git tag | grep -q "^v{{ ver }}$"; then
        echo "Error: Tag v{{ ver }} does not exist"
        exit 1
    fi
    echo "Removing tag v{{ ver }} locally and remotely..."
    git tag -d v{{ ver }}
    git push origin :refs/tags/v{{ ver }}
    echo "Tag removed successfully"
    echo "Note: To complete cleanup, please delete the release at:"
    echo "{{ github_repo_url }}/releases/tag/v{{ ver }}"

### Misc

# Pack the repository into a single markdown file with repomix
pack:
    @printf "{{ title }}[Pack]{{ reset_color }} Repository\n"
    @repomix --style markdown . --ignore "LICENSE,gradlew,app/src/test"
