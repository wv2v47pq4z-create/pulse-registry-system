# Make.com Integration Guide

This guide provides the exact JSON payloads and configurations needed to build the Autonomous Research Pipeline in Make.com.

## 🎯 Overview

Make.com is a no-code automation platform that can replicate the Python pipeline functionality using visual workflows (scenarios).

## 🔧 Scenario Structure

Your Make.com scenario should follow this flow:

```
1. HTTP Module (Fetch Papers)
   ↓
2. Iterator (Process Each Paper)
   ↓
3. Airtable Search (Check Duplicates)
   ↓
4. Router (New vs Existing)
   ↓
5. Anthropic/Claude API (Categorize)
   ↓
6. JSON Parser (Validate Response)
   ↓
7. Airtable Create/Update (Store Results)
```

## 📦 Module Configurations

### 1. HTTP Module - Fetch Papers

**Settings:**
- URL: `{{your_elicit_data_url}}`
- Method: GET
- Parse response: Yes

**Output Mapping:**
- Store the array of papers for iteration

---

### 2. Iterator

**Settings:**
- Array: Select the papers array from HTTP module output

---

### 3. Airtable Search Records

**Settings:**
- Base: Select your Airtable base
- Table: `Pulse Systems Research`
- Formula: 
  ```
  OR(
    {Elicit ID} = '{{iterator.elicit_id}}',
    AND({Title} = '{{iterator.title}}', {Year} = {{iterator.year}})
  )
  ```
- Max records: 1

**Purpose:** Check for duplicates before processing

---

### 4. Router with Filter

Create two routes:

**Route 1: Process New Papers**
- Filter: `Airtable Search Total Number of Bundles = 0`

**Route 2: Skip Duplicates**
- Filter: `Airtable Search Total Number of Bundles > 0`
- Action: Tools → Set Variable (for tracking)

---

### 5. Anthropic/Claude API Module (Route 1)

**Critical Configuration:**

**Connection Settings:**
- API Key: Your Claude API key
- Model: `claude-3-5-sonnet-20241022`

**Request Body (JSON):**
```json
{
  "model": "claude-3-5-sonnet-20241022",
  "max_tokens": 4000,
  "messages": [
    {
      "role": "user",
      "content": "You are an expert research analyst specializing in technology, blockchain, and AI systems. Your task is to analyze the following research paper and provide a structured categorization.\n\n**Paper Details:**\n- Title: {{iterator.title}}\n- Year: {{iterator.year}}\n- Authors: {{iterator.authors}}\n- Abstract: {{iterator.abstract}}\n\n**Your Task:**\nAnalyze this paper and provide a structured JSON response with the following fields:\n\n1. **category**: Choose ONE from: \"Core Technology\", \"Use Case\", \"Market Research\", \"Regulatory\", \"Competitive Analysis\", \"Other\"\n2. **priority**: Choose ONE from: \"High\", \"Medium\", \"Low\" (based on relevance and potential impact)\n3. **relevance_score**: Rate from 0-10 how relevant this is to blockchain/AI systems\n4. **potential_impact**: Brief description (10-500 chars) of potential impact\n5. **key_idea**: Main idea or insight from the paper (10-1000 chars)\n6. **technical_approach**: Technical approach or methodology (10-1000 chars)\n7. **implementation_notes**: Notes on implementation possibilities (10-1000 chars)\n8. **related_technologies**: Comma-separated list of related technologies\n9. **actionable_insights**: Specific actionable insights or next steps (10-1000 chars)\n10. **confidence_level**: Choose ONE from: \"High\", \"Medium\", \"Low\" (your confidence in this categorization)\n11. **summary**: Comprehensive summary of the paper (20-2000 chars)\n\nRespond ONLY with valid JSON matching this exact structure. Do not include any markdown formatting or code blocks."
    }
  ]
}
```

**Variable Mapping in Make.com:**
- `{{iterator.title}}` - Maps to current paper title
- `{{iterator.year}}` - Maps to current paper year
- `{{iterator.authors}}` - Maps to current paper authors
- `{{iterator.abstract}}` - Maps to current paper abstract

---

### 6. JSON Parser Module

**Settings:**
- JSON string: Extract text content from Claude response
- Data structure: Define based on the expected fields

**Transformation (if needed):**

Add a "Text Parser" module before JSON if Claude wraps response in markdown:

```
Pattern: ```json\n(.*?)\n```
Group: 1
```

This extracts the JSON from markdown code blocks.

---

### 7. Airtable Create/Update Record

**Settings:**
- Base: Select your Airtable base
- Table: `Pulse Systems Research`
- Operation: Create or Update

**Field Mappings:**

```javascript
{
  "Title": "{{iterator.title}}",
  "Year": {{iterator.year}},
  "Elicit ID": "{{iterator.elicit_id}}",
  "Authors": "{{iterator.authors}}",
  "Abstract": "{{iterator.abstract}}",
  "URL": "{{iterator.url}}",
  "AI_Raw_JSON": "{{claude.content[0].text}}",
  "Category": "{{parsed_json.category}}",
  "Priority": "{{parsed_json.priority}}",
  "Relevance": {{parsed_json.relevance_score}},
  "Potential": "{{parsed_json.potential_impact}}",
  "Key Idea": "{{parsed_json.key_idea}}",
  "Technical Approach": "{{parsed_json.technical_approach}}",
  "Implementation Notes": "{{parsed_json.implementation_notes}}",
  "Related Technologies": "{{parsed_json.related_technologies}}",
  "Actionable Insights": "{{parsed_json.actionable_insights}}",
  "Confidence Level": "{{parsed_json.confidence_level}}",
  "Summary": "{{parsed_json.summary}}",
  "Processing Status": "Completed"
}
```

---

## 🔄 Error Handling in Make.com

### Add Error Handler Route

After each critical module (Claude API, Airtable), add an error handler:

**Error Handler Module:**
1. Click on the wrench icon on the module
2. Enable "Error handler"
3. Add route with these modules:
   - Tools → Set Variable (error details)
   - Airtable → Create Record (log failure)

**Failure Record Fields:**
```javascript
{
  "Title": "{{iterator.title}}",
  "Processing Status": "Failed",
  "Failure_Reason": "{{error.message}}"
}
```

---

## ⏰ Scheduling

### Option 1: Schedule Trigger

1. Use "Schedule" as the first module instead of HTTP
2. Set interval (e.g., daily at 2 AM)
3. Add HTTP module as second step

### Option 2: Webhook Trigger

1. Use "Webhooks" → "Custom Webhook"
2. Get the webhook URL
3. Call from external system (CI/CD, cron job, etc.)

---

## 📊 Data Source Format

Your Elicit data URL should return JSON in this format:

```json
[
  {
    "title": "Paper Title",
    "year": 2024,
    "abstract": "Paper abstract text...",
    "elicit_id": "unique-id-123",
    "authors": "Author 1, Author 2",
    "url": "https://example.com/paper"
  }
]
```

Or CSV with headers:
```csv
title,year,abstract,elicit_id,authors,url
"Paper Title",2024,"Abstract text","id-123","Authors","URL"
```

---

## 🎨 Advanced Configuration

### Parallel Processing

For faster execution with large datasets:

1. Replace Iterator with "Array Aggregator"
2. Set batch size (e.g., 5 papers at once)
3. Use "Flow Control" → "Router" for parallel branches
4. Add "Tools" → "Sleep" between batches to avoid rate limits

### Rate Limiting

Add between Claude API calls:

**Tools → Sleep:**
- Delay: 2 seconds (adjust based on your Claude API tier)

### Deduplication Optimization

Instead of searching Airtable for each paper:

1. Add "Airtable" → "List Records" at the start
2. Get all Elicit IDs and Titles
3. Use "Tools" → "Set Variable" to create a map
4. In Iterator, check against the map (faster than API calls)

---

## 🧪 Testing Your Scenario

### Test Data

Create a test JSON file with sample papers:

```json
[
  {
    "title": "Test Paper on Blockchain",
    "year": 2024,
    "abstract": "This is a test abstract about blockchain technology and its applications in modern systems.",
    "elicit_id": "test-001",
    "authors": "John Doe, Jane Smith",
    "url": "https://example.com/test"
  }
]
```

### Test Steps

1. Run scenario once with test data
2. Verify Airtable record is created
3. Check all fields are populated correctly
4. Test duplicate detection (run again with same data)
5. Verify no duplicate records are created

---

## 💡 Best Practices

### 1. Environment-Specific Webhooks

Create separate scenarios for:
- Development (test with sample data)
- Production (real data source)

### 2. Logging

Add "Tools" → "Set Variable" modules throughout to log:
- Papers processed
- Duplicates found
- Errors encountered
- Total execution time

### 3. Notifications

Add at the end:
- Email notification with summary stats
- Slack/Discord webhook with results
- Custom dashboard updates

### 4. Cost Optimization

- Batch papers to reduce Claude API calls
- Cache Airtable records to reduce reads
- Use filters to skip obviously irrelevant papers

---

## 🔑 Required API Keys

Store these in Make.com's data stores or connections:

1. **Airtable**
   - Personal Access Token
   - Base ID (in module config)

2. **Claude/Anthropic**
   - API Key (in HTTP module or Anthropic connection)

3. **Data Source**
   - API key if required by your Elicit endpoint

---

## 📈 Monitoring

### Track These Metrics

1. Papers processed per run
2. Duplicates detected
3. Categorization failures
4. Average processing time per paper
5. Claude API token usage

### Make.com Operations Dashboard

Use Make.com's built-in features:
- Scenario execution history
- Error logs
- Data throughput
- Execution time graphs

---

## 🚀 Deployment Checklist

- [ ] All API keys configured
- [ ] Airtable base and table created with correct schema
- [ ] Data source URL accessible
- [ ] Test scenario with sample data
- [ ] Error handlers configured
- [ ] Schedule or webhook trigger set up
- [ ] Notifications configured
- [ ] Rate limiting in place
- [ ] Cost monitoring enabled
- [ ] Documentation updated

---

## 🆘 Troubleshooting

### "Invalid JSON from Claude"

**Solution:** Add Text Parser module to strip markdown:
```
Pattern: ```json\n(.*?)\n```
Flags: s (single line mode)
```

### "Airtable Rate Limit"

**Solution:** Add delays between operations:
```
Tools → Sleep: 0.5 seconds between Airtable calls
```

### "Claude API Timeout"

**Solution:** Increase timeout in HTTP settings:
```
Timeout: 120 seconds (max in Make.com)
```

### "Missing Required Fields"

**Solution:** Add fallback values:
```javascript
{
  "Year": "{{if(iterator.year, iterator.year, 0)}}",
  "Abstract": "{{if(iterator.abstract, iterator.abstract, 'No abstract available')}}"
}
```

---

## 📞 Support

For Make.com-specific issues:
- Check Make.com documentation
- Visit Make.com community forum
- Contact Make.com support

For pipeline logic issues:
- Refer to PIPELINE_README.md
- Review Python implementation
- Check Pydantic model definitions

---

**Happy Automating! 🎉**
