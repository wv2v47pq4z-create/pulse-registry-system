# pulse-registry-system
Smart contracts for PulseRegistry and ZcashBridge - auto-registration and interoperability layer for Super Reality Studios blockchain ecosystem.

## Developer Automation Tools

This repository includes a **Master Automation Prompt** system for GitHub Copilot that helps generate optimized prompts for Perplexity AI.

### Using the Perplexity Automation Prompt

The automation prompt helps you convert raw context (code, diffs, issues, notes) into structured prompts for Perplexity AI that are optimized for:
- Code analysis and generation
- Repository-wide reasoning
- Build/CI tooling
- Product and workflow design

#### Two Ways to Use It:

1. **With GitHub Copilot Chat** (Automatic):
   - The `.github/copilot-instructions.md` file is automatically loaded by GitHub Copilot
   - Just start chatting with Copilot and paste your context
   - Copilot will generate a clean prompt you can paste directly into Perplexity

2. **As a Standalone Prompt File**:
   - Open `perplexity-automation.prompt.md` in your editor
   - Copy the entire content
   - Paste it into GitHub Copilot Chat or your AI assistant
   - Then provide your context, and it will generate the master prompt

#### Workflow:

1. Gather your context (code snippets, requirements, issues, etc.)
2. Paste into Copilot Chat (which has the automation prompt loaded)
3. Copilot will generate a structured master prompt
4. Copy that output and paste it directly into Perplexity AI
5. Get optimized responses from Perplexity with clear structure and constraints

The master prompt ensures Perplexity receives well-structured instructions including:
- Role and context
- Clear goals
- Available inputs
- Constraints and preferences
- Expected output format
- Interaction style
- Task-specific instructions
