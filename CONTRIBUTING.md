# Contributing to SR-OS AutoPost Remote Executor Node

Thank you for your interest in contributing to the SR-OS AutoPost Remote Executor Node! This document provides guidelines and best practices for contributing to this project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Documentation](#documentation)

## Code of Conduct

This project adheres to professional standards of conduct:

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other contributors

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/pulse-registry-system.git
   cd pulse-registry-system
   ```
3. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Setup

### Prerequisites

- Python 3.10 or higher
- pip (Python package manager)
- git

### Environment Setup

1. Create a virtual environment:
   ```bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Set up configuration:
   ```bash
   cp config.example.json config.json
   # Edit config.json with your test settings
   ```

4. Create necessary directories:
   ```bash
   mkdir -p watch_folder logs
   ```

## Coding Standards

### Python Style Guide

- Follow [PEP 8](https://www.python.org/dev/peps/pep-0008/) style guide
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 100 characters
- Use meaningful variable and function names
- Add docstrings to all functions and classes

### Example Function Structure

```python
def function_name(param1: str, param2: int) -> bool:
    """
    Brief description of function purpose.
    
    Args:
        param1: Description of param1
        param2: Description of param2
    
    Returns:
        Description of return value
    
    Raises:
        ValueError: Description of when this is raised
    """
    # Implementation
    pass
```

### Type Hints

- Use type hints for function parameters and return values
- Import types from `typing` module when needed
- Example:
  ```python
  from typing import Dict, List, Optional
  
  def process_files(files: List[Path]) -> Dict[str, bool]:
      pass
  ```

### Error Handling

- Use specific exception types
- Always log errors with context
- Provide actionable error messages
- Example:
  ```python
  try:
      data = load_config()
  except json.JSONDecodeError as e:
      self.log("ERROR", f"Invalid JSON in config: {e}")
      sys.exit(1)
  ```

### Logging Standards

- Use the standardized logging format
- Include timestamps in ISO 8601 format
- Use appropriate log levels: INFO, SUCCESS, WARNING, ERROR
- Log both to console and JSONL file

## Testing Requirements

### Running Tests

Run the test suite:

```bash
python -m pytest tests/
```

### Test Coverage

- All new features must include tests
- Maintain or improve existing test coverage
- Test both success and failure cases
- Test edge cases and boundary conditions

### Writing Tests

Example test structure:

```python
import pytest
from autopost_client import AutoPostClient

def test_config_loading():
    """Test configuration loading functionality"""
    client = AutoPostClient()
    assert client.config is not None
    assert "api_url" in client.config

def test_file_scanning():
    """Test file scanning logic"""
    # Setup
    # Execute
    # Assert
    pass
```

## Pull Request Process

### Before Submitting

1. **Update documentation** if you've made changes that affect usage
2. **Run tests** and ensure they pass
3. **Check code style** against PEP 8
4. **Update MASTER_PROMPT.md** if behavior changes
5. **Test on multiple platforms** if possible (Windows, Linux, macOS)

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to change)
- [ ] Documentation update

## Testing
- [ ] Tested on Windows
- [ ] Tested on Linux/macOS
- [ ] Unit tests added/updated
- [ ] Manual testing performed

## Checklist
- [ ] Code follows project style guidelines
- [ ] Documentation updated
- [ ] Tests pass locally
- [ ] No new warnings introduced
```

### Review Process

1. Submit your PR with a clear description
2. Respond to reviewer feedback promptly
3. Make requested changes in new commits
4. Once approved, your PR will be merged

## Issue Reporting

### Bug Reports

Use this template for bug reports:

```markdown
## Bug Description
Clear and concise description of the bug

## Steps to Reproduce
1. Step one
2. Step two
3. Step three

## Expected Behavior
What you expected to happen

## Actual Behavior
What actually happened

## Environment
- OS: [e.g., Windows 10, Ubuntu 22.04]
- Python version: [e.g., 3.10.5]
- Client version: [e.g., 1.0]

## Logs
Relevant log excerpts from logs/autopost_status.jsonl

## Additional Context
Any other relevant information
```

### Feature Requests

Use this template for feature requests:

```markdown
## Feature Description
Clear and concise description of the feature

## Use Case
Why is this feature needed? What problem does it solve?

## Proposed Solution
How you envision this feature working

## Alternatives Considered
Other approaches you've considered

## Additional Context
Any other relevant information
```

## Documentation

### Documentation Standards

- Keep documentation up-to-date with code changes
- Use clear, concise language
- Include examples where helpful
- Follow Markdown best practices

### Files to Update

When making changes, consider updating:

- `README.md` - User-facing documentation
- `MASTER_PROMPT.md` - Specification and behavior contract
- `COPILOT_AUTOPOST_AGENT.md` - Agent instructions
- Code comments and docstrings

### Documentation Structure

- **Overview**: Brief introduction
- **Installation**: Setup instructions
- **Usage**: How to use the feature
- **Examples**: Practical examples
- **Troubleshooting**: Common issues and solutions

## Commit Message Guidelines

### Format

```
type(scope): brief description

Detailed description (optional)

Fixes #issue-number (if applicable)
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Examples

```
feat(client): add retry logic for failed POST requests

Added exponential backoff retry logic to handle transient network errors.
Configurable via max_retries in config.json.

Fixes #123
```

```
fix(logging): correct timestamp format in JSONL output

Changed timestamp format to ISO 8601 with timezone for consistency
with MASTER_PROMPT.md specification.
```

## Platform-Specific Considerations

### Windows

- Use `pathlib.Path` for cross-platform path handling
- Test batch scripts and PowerShell scripts
- Verify Task Scheduler integration

### Linux/macOS

- Test bash scripts with proper shebang
- Verify systemd service functionality
- Check file permissions

### Cross-Platform

- Use `os.path.join()` or `pathlib.Path` for paths
- Avoid platform-specific commands
- Test on multiple platforms when possible

## Security Guidelines

- **Never commit credentials**: Use `config.json` (gitignored)
- **Validate input**: Sanitize file paths and user input
- **Size limits**: Enforce file size limits
- **Safe defaults**: Use secure defaults in configuration
- **Error messages**: Don't expose sensitive information in logs

## Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Documentation**: Check README.md and MASTER_PROMPT.md first

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to SR-OS AutoPost Remote Executor Node!
