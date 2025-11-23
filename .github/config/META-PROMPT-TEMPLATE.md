# Meta-Prompt Template for Single-Page Responses

This is a reusable prompt template that instructs GitHub AI (or any AI) to produce clean, single-page, copy-pasteable responses. Simply replace the **TASK** section with your specific request.

---

## The Template

```markdown
You are GitHub-AI-node participating in a Super Reality OS mesh.

Your job in THIS conversation is to produce **one single, clean, copy‑pasteable response** to the task below.

### CRITICAL INSTRUCTIONS

- Output **ONE continuous markdown document** suitable to paste into Notion or a README.
- **Do NOT** include any of this meta-instruction text in your output.
- **Do NOT** wrap the whole answer in code fences unless the entire document is meant to be code.
- Do NOT explain what you are doing. Just output the final document.
- Keep everything on **one conceptual page**:
    - Use headings (##, ###) and bullet points where helpful.
    - Avoid excessive length; aim for something that feels like a single screenful to a few scrolls, not a whole book.

### FORMAT REQUIREMENTS

- Start immediately with the first heading or paragraph of the final document.
- No preamble like "Sure, here's your document" or "As an AI…".
- No extra commentary before or after the document.
- If you show JSON or YAML, format it correctly and **only** as part of the document content.

### TASK

Create a single, self‑contained page that [DESCRIBE TASK HERE].

The page should be:

- Clear and structured for a technical audience.
- Ready to paste into Notion or a GitHub README.
- Free of placeholders like "fill this in later" unless explicitly required.
```

---

## How to Use

1. **Copy the template above**
2. **Replace `[DESCRIBE TASK HERE]`** with your specific request
3. **Paste into GitHub AI** (Copilot, GitHub Models, or any AI chat)
4. **Receive a clean, single-page response** ready to paste

---

## Example Tasks

Replace `[DESCRIBE TASK HERE]` with any of these:

- `explains how to set up a Python FastAPI project with Docker`
- `documents the pulse.start protocol for the SR-OS mesh`
- `provides a quickstart guide for contributing to this repository`
- `outlines best practices for writing GitHub Actions workflows`
- `describes the architecture of a microservices application`

---

## Why This Works

### Single-Page Focus
The template explicitly instructs the AI to produce one continuous document, not multiple pages or a series of responses.

### No Meta-Commentary
By forbidding preambles and explanations, you get only the requested content—nothing before or after.

### Copy-Paste Ready
The output is formatted for direct pasting into Notion, README files, or documentation systems without additional cleanup.

### Consistent Structure
Using markdown with clear headings ensures the output is well-organized and scannable.

---

## Integration with SR-OS Mesh

This meta-prompt template complements the GitHub-AI-node Boot Kit by providing a consistent way to request single-page documentation outputs from the AI. It ensures that responses align with the mesh's requirement for clean, structured communication.

### Relationship to Boot Kit Files

- **MASTER-PROMPT.md** - Defines the AI's pulse response behavior
- **META-PROMPT-TEMPLATE.md** - Defines how to request clean documentation outputs
- **NOTION-PAGE.md** - Example of the kind of output this template produces

---

## Best Practices

### Do:
- ✅ Be specific in your TASK description
- ✅ Mention the target audience (e.g., "for developers", "for operators")
- ✅ Specify the format if needed (e.g., "as a quickstart guide", "as a reference table")

### Don't:
- ❌ Include multiple unrelated tasks in one prompt
- ❌ Ask for "all possible information" (keep scope focused)
- ❌ Expect the AI to remember previous context (each use is independent)

---

## Version Control

When you receive a response using this template:

1. Save the output as a `.md` file in your repository
2. Commit with a descriptive message (e.g., "Add API documentation page")
3. Review and edit as needed
4. The AI's output is a starting point—always validate technical accuracy

---

**Version**: 1.0  
**Compatible with**: SR-GITHUB-AI-v1.1  
**Last Updated**: 2025-11-23
