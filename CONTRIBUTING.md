📄 PLIK 8/12: CONTRIBUTING.md

markdown
# Contributing to WSMS PRO

Thank you for your interest in contributing to WSMS PRO!

## Development Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/wp-server-management-system.git`
3. Create a feature branch: `git checkout -b feature/amazing-feature`

## Code Style

- Use 4 spaces for indentation (no tabs)
- Shell scripts must pass `shellcheck` validation
- Function names should be descriptive and use snake_case
- Include comments for complex logic
- All scripts must source `wsms-config.sh` for configuration
- Logs must go to appropriate category in `~/logs/wsms/[category]/`

### Script Template
```bash
#!/bin/bash
source "$HOME/scripts/wsms-config.sh"

# Use appropriate log file
LOG_FILE="$LOG_CATEGORY_DIR/script-name.log"
exec >> "$LOG_FILE" 2>&1

echo "=========================================================="
echo "SCRIPT NAME - $(date)"
echo "=========================================================="

# Your code here

echo "✅ COMPLETE - $(date)"
Testing

Before submitting a PR, test your changes:

bash
# Run shellcheck on all scripts
shellcheck scripts/*.sh

# Syntax check
for script in scripts/*.sh; do bash -n "$script" || exit 1; done

# Test installation on a clean Ubuntu VM
./installers/install.sh

# Verify all aliases work
source ~/.bashrc
wp-status
backup-list

# Run test suite
bash tests/test_suite.sh
Pull Request Process

Update documentation with details of changes
Update CHANGELOG.md following the existing format
Ensure all tests pass
The PR will be merged after review and approval
Adding New Scripts

New scripts should:

Be placed in ~/scripts/ (via installer)
Source wsms-config.sh
Use appropriate LOG_* variable
Be added to deploy() function in installers/install.sh
Have corresponding alias added to installer
Be documented in TECHNICAL_REFERENCE.md
Adding New Aliases

Add to both Bash and Fish sections in installer:

bash
# In PHASE 5 of install.sh
alias new-command='bash $SCRIPTS_DIR/new-script.sh'
Questions?

Open an issue or contact the maintainer.

Maintainer: Lukasz Malec | GitHub: maleclukas-prog

