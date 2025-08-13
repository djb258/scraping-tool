# HEIR Agent Library

This directory contains all available agent definitions. Each agent is a markdown file with specific instructions for Claude Code.

## Directory Structure
```
agents/
├── orchestrators/          # Level 1: Strategic (30,000ft)
├── managers/              # Level 2: Tactical (20,000ft)  
├── specialists/           # Level 3: Execution (10,000ft)
└── templates/            # Templates for custom agents
```

## Agent Storage Rules
- **Global agents**: Live in this repo - reusable across all projects
- **Project-specific agents**: Created in `.claude/agents/` within each project
- **Custom agents**: Can be created by extending templates

## Agent Naming Convention
- `{domain}-{role}.md` - e.g., `stripe-payment-handler.md`
- Use kebab-case for filenames
- Include domain context in specialist agents