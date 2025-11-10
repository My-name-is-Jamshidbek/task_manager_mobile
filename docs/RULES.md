# Documentation Rules

## Important Rules for Future Development

### Rule 1: No Auto-Generated Documentation
- **NEVER** create markdown (.md) documentation files as a result of code completion or fixes
- Do NOT generate summary docs after implementing features
- Do NOT create recap or report documents automatically

### Rule 2: Documentation Location
- If documentation MUST be created, it should ONLY be placed in the `/docs` folder
- Do NOT create .md files in the root directory
- Keep all documentation organized within this folder

### Rule 3: Documentation Exceptions
The following are acceptable reasons to create documentation:
- Architecture decisions and design patterns
- API integration guides
- Setup and configuration instructions
- User guides for complex features

---

## Current Documentation Structure

```
/docs/
├── RULES.md (this file)
├── README.md (overview and getting started)
└── [other documentation as needed]
```

## Implementation Notes

- All existing .md files in the root directory should eventually be moved here
- Future PRs should follow these documentation rules
- Developers should clean up auto-generated docs from previous work

---

**Last Updated**: 7 November 2025
**Enforced By**: Copilot Assistant
