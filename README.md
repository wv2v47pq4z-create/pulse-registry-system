# pulse-registry-system

Smart contracts for PulseRegistry and ZcashBridge - auto-registration and interoperability layer for Super Reality Studios blockchain ecosystem.

## 🤖 Autonomous Research Pipeline

This repository includes a comprehensive Python-based autonomous research pipeline for automatically fetching, categorizing, and storing research papers using Claude AI and Airtable.

### Features

- **Automated Paper Categorization**: Uses Claude AI to analyze and categorize research papers
- **Smart Deduplication**: Intelligent duplicate detection using Elicit ID or Title/Year matching
- **Airtable Integration**: Seamless storage and management in Airtable
- **Idempotent Execution**: Safe to run multiple times without creating duplicates
- **Docker Support**: Containerized deployment for easy scaling
- **Make.com Compatible**: Includes guides for no-code automation

### Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Configure environment
cp .env.example .env
# Edit .env with your API keys

# Run the pipeline
python main.py
```

### Documentation

- **[Pipeline Documentation](PIPELINE_README.md)** - Complete guide to the Python implementation
- **[Make.com Integration](MAKECOM_INTEGRATION.md)** - No-code automation setup guide

### Architecture

The pipeline consists of three main modules:

1. **Data Models** (`models.py`) - Pydantic models for strict validation
2. **Claude API** (`claude_api.py`) - AI categorization integration
3. **Core Pipeline** (`pipeline.py`) - Orchestration and Airtable integration

### Requirements

- Python 3.11+
- Airtable account with API access
- Claude API key (Anthropic)
- Research paper data source

See [PIPELINE_README.md](PIPELINE_README.md) for detailed documentation.
