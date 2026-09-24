# Modular & Hierarchical Rules Architecture

Antigravity uses a tiered rule discovery engine that combines repository-wide constraints with directory-specific and contextual rules.

---

## 1. Rule Discovery Hierarchy

Rules are discovered and merged in the following order of precedence (highest to lowest):

1. **Subdirectory Rules** (e.g. `lib/modules/native/AGENTS.md`): Overrides root rules for files within that specific subtree.
2. **Project Root Rules** (`<repo-root>/AGENTS.md` or `GEMINI.md`): Baseline project constraints applicable to all files.
3. **Workspace Rule Files** (`<repo-root>/.agents/rules/*.md`): Categorized modular rules (e.g., `git-workflow.md`, `coding-style.md`, `security.md`).
4. **Global User Rules** (`~/.gemini/config/rules/*.md` or `~/.claude/rules/*.md`): Machine-wide defaults.

---

## 2. Directory Rule File (`AGENTS.md` / `GEMINI.md`)

`AGENTS.md` and `GEMINI.md` are always-active rule files loaded when navigating a directory.

### Structure Best Practices:
```markdown
# Project Constraints & Rules

## 1. Core Architecture
- Specify State Management pattern (e.g. Riverpod, Bloc).
- No business logic inside build() methods.

## 2. Mandatory Verification Cycle
- Run linter/analyzer before reporting task completion:
  1. dart analyze
  2. dart format .
  3. flutter test

## 3. Response Format
- Always suggest actionable next-step prompts and corresponding skills at the end of each response.
```

---

## 3. Modular Contextual Rules (`.agents/rules/*.md`)

For large codebases, split rules into focused markdown files inside `.agents/rules/`:

```text
.agents/rules/
├── coding-style.md
├── git-workflow.md
├── security-checks.md
└── release-protocol.md
```

### Contextual Rule Loading Modes:
- **`always_on`** (Default for `AGENTS.md`): Injected unconditionally into every conversation turn.
- **`model_decision`**: Summarized in system prompt metadata and expanded only when relevant to the user request.
- **`file_pattern`**: Activated dynamically when files matching specific glob patterns (e.g., `*.dart`, `*.rs`, `pubspec.yaml`) are opened or edited.

---

## 4. Rule Deduplication Engine

Antigravity guarantees that duplicate rules referenced across multiple directories or symlinks are resolved to their canonical paths and injected **exactly once** per turn, preserving token context.
