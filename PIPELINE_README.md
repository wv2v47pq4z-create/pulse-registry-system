# Autonomous Research Pipeline

A comprehensive Python-based pipeline for automatically fetching, categorizing, and storing research papers using Claude AI and Airtable.

## 🎯 Overview

This pipeline implements an autonomous research database system that:

1. **Fetches** research papers from external data sources (Elicit or custom APIs)
2. **Deduplicates** by checking existing Airtable records
3. **Categorizes** papers using Claude AI with structured output
4. **Stores** results in Airtable with full metadata and AI analysis

## 🏗️ Architecture

The pipeline consists of three main modules:

### Block 1: Data Models and Claude API (`models.py` + `claude_api.py`)

- **`models.py`**: Pydantic models for strict data validation
  - `PaperInput`: Input validation for research papers
  - `PaperCategorizationResponse`: Output validation for Claude AI responses
  
- **`claude_api.py`**: Claude API integration
  - `build_claude_prompt()`: Generates structured prompts
  - `call_claude_api()`: Robust API calls with error handling and JSON parsing

### Block 2: Core Pipeline (`pipeline.py`)

- `run_autonomous_pipeline()`: Main orchestration function
  - Environment variable loading
  - Idempotent execution with duplicate detection
  - Batch processing with individual error handling
  
- `fetch_papers_from_elicit()`: Fetch papers from external sources
- `check_duplicate_in_airtable()`: Smart deduplication logic
- `process_single_paper()`: Single paper processing workflow
- `update_airtable_record()`: Create or update Airtable records

### Block 3: Entry Point (`main.py`)

- Environment variable validation
- CLI argument parsing
- Progress reporting and statistics
- Results export to JSON

## 📋 Airtable Schema

The pipeline expects the following fields in your Airtable base:

| Field Name | Type | Description |
|------------|------|-------------|
| `Title` | Single line text | Paper title (required) |
| `Year` | Number | Publication year |
| `Elicit ID` | Single line text | Unique external identifier |
| `AI_Raw_JSON` | Long text | **CRITICAL**: Raw Claude API response |
| `Category` | Single select | Primary category |
| `Priority` | Single select | Priority level (High/Medium/Low) |
| `Relevance` | Number | Relevance score (0-10) |
| `Potential` | Long text | Potential impact description |
| `Key Idea` | Long text | Main idea or insight |
| `Technical Approach` | Long text | Technical methodology |
| `Implementation Notes` | Long text | Implementation possibilities |
| `Related Technologies` | Long text | Comma-separated technologies |
| `Actionable Insights` | Long text | Actionable next steps |
| `Confidence Level` | Single select | AI confidence (High/Medium/Low) |
| `Summary` | Long text | Comprehensive summary |
| `Processing Status` | Single select | Status (Completed/Failed) |
| `Failure_Reason` | Long text | Error message if failed |
| `Authors` | Long text | Paper authors (optional) |
| `Abstract` | Long text | Paper abstract (optional) |
| `URL` | URL | Link to paper (optional) |

## 🚀 Quick Start

### Prerequisites

- Python 3.11 or higher
- Airtable account with API access
- Claude API key (Anthropic)
- Research paper data source URL

### Installation

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd pulse-registry-system
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your actual credentials
   ```

4. **Run the pipeline**:
   ```bash
   python main.py
   ```

### Environment Variables

Create a `.env` file with the following variables:

```bash
# Airtable Configuration
AIRTABLE_API_KEY=your_airtable_api_key
AIRTABLE_BASE_ID=your_base_id
AIRTABLE_TABLE_NAME=Pulse Systems Research

# Claude API Configuration
CLAUDE_API_KEY=your_claude_api_key

# Data Source
ELICIT_DATA_URL=https://your-data-source.com/papers.json
```

## 🐳 Docker Deployment

### Build and run with Docker

```bash
# Build the image
docker build -t research-pipeline .

# Run with environment variables
docker run --env-file .env research-pipeline
```

### Run with Docker Compose

```bash
# Start the service
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the service
docker-compose down
```

### Scheduled Execution

For scheduled runs, uncomment the command section in `docker-compose.yml`:

```yaml
command: >
  sh -c "while true; do
    python main.py;
    echo 'Pipeline completed. Waiting 24 hours...';
    sleep 86400;
  done"
```

## 🔧 Advanced Usage

### Validate Environment Only

```bash
python main.py --validate-only
```

### Export Results to JSON

```bash
python main.py --output results.json
```

### Custom Configuration

You can override environment variables programmatically:

```python
from pipeline import run_autonomous_pipeline

result = run_autonomous_pipeline(
    airtable_api_key="custom_key",
    airtable_base_id="custom_base",
    claude_api_key="custom_claude_key",
    elicit_data_url="https://custom-url.com/papers.json"
)

print(result)
```

## 🛡️ Features

### Idempotency

The pipeline is fully idempotent:
- Checks for existing records before processing
- Prioritizes matching on `Elicit ID`
- Falls back to `Title` and `Year` matching
- Safe to run multiple times without duplicates

### Error Handling

- Individual paper failures don't stop the pipeline
- Failed papers are recorded in Airtable with error details
- Network errors are caught and logged
- Invalid API responses are handled gracefully

### Data Validation

- Pydantic models ensure data integrity
- Claude responses are validated against strict schemas
- Input data is sanitized before processing
- JSON parsing with fallback strategies

## 📊 Data Flow

```
┌─────────────────┐
│  Elicit / Data  │
│     Source      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Fetch Papers    │
│ (CSV/JSON)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Check Airtable  │
│  for Duplicates │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Call Claude    │
│  API for        │
│  Categorization │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Validate with   │
│ Pydantic Models │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Update Airtable │
│ with Results    │
└─────────────────┘
```

## 🔌 Integration with Make.com

For Make.com integration, use this JSON payload structure for the Anthropic/Claude API module:

```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 4000,
  "messages": [
    {
      "role": "user",
      "content": "You are an expert research analyst... [full prompt with {{title}}, {{abstract}}, etc.]"
    }
  ]
}
```

Map variables from your Make.com data flow:
- `{{title}}` → Paper title
- `{{year}}` → Publication year
- `{{abstract}}` → Paper abstract
- `{{authors}}` → Author list

## 🧪 Testing

### Manual Testing

1. Create a test data source with sample papers
2. Set up a test Airtable base
3. Run the pipeline with test credentials
4. Verify records are created correctly

### Python Testing

```python
from models import PaperInput, PaperCategorizationResponse

# Test input validation
paper = PaperInput(
    title="Test Paper",
    year=2024,
    abstract="Test abstract"
)

# Test output validation
response = PaperCategorizationResponse(
    category="Core Technology",
    priority="High",
    relevance_score=9,
    # ... other fields
)
```

## 📝 Logging

The pipeline uses Python's built-in logging:

```python
import logging
logging.basicConfig(level=logging.INFO)
```

Logs include:
- Pipeline start/completion
- Paper processing progress
- Duplicate detection
- API calls and responses
- Errors and exceptions

## 🔐 Security Best Practices

1. **Never commit `.env` files** - Use `.env.example` as template
2. **Rotate API keys regularly** - Both Airtable and Claude
3. **Use environment-specific keys** - Separate dev/staging/prod
4. **Monitor API usage** - Track Claude API costs
5. **Validate input data** - Pydantic models prevent injection

## 🐛 Troubleshooting

### Common Issues

**"Missing required environment variables"**
- Ensure `.env` file exists and has all required variables
- Check for typos in variable names

**"Claude API request timed out"**
- Check internet connectivity
- Verify Claude API key is valid
- Consider increasing timeout in `claude_api.py`

**"Airtable connection failed"**
- Verify API key has correct permissions
- Check base ID is correct
- Ensure table name matches exactly

**"JSON parsing failed"**
- Claude sometimes returns markdown-wrapped JSON
- The pipeline handles this automatically
- Check logs for raw response

## 🤝 Contributing

To extend the pipeline:

1. Add new Pydantic models in `models.py`
2. Extend Claude prompt in `claude_api.py`
3. Add new fields to Airtable schema
4. Update `pipeline.py` to handle new fields
5. Test thoroughly before deploying

## 📚 References

- [Pydantic Documentation](https://docs.pydantic.dev/)
- [PyAirtable Documentation](https://pyairtable.readthedocs.io/)
- [Claude API Documentation](https://docs.anthropic.com/)
- [Docker Documentation](https://docs.docker.com/)

## 📄 License

See LICENSE file in the repository root.

## 🆘 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review logs for specific error messages
3. Open an issue in the repository
4. Contact the development team

---

**Built with ❤️ for autonomous research management**
