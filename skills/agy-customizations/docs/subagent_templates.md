# Custom Subagent Templates & Definition Guide

Antigravity allows defining specialized subagent types either dynamically at runtime via `define_subagent` or declaratively inside plugins and skill packages.

---

## 1. Dynamic Subagent Definition (`define_subagent`)

When a complex task requires a specialized persona or restricted permissions, call `define_subagent`:

```json
{
  "name": "dart_compiler_agent",
  "description": "Specialized subagent that analyzes Dart build failures, runs flutter analyze, and repairs type errors.",
  "system_prompt": "You are a specialized Dart/Flutter compiler expert. Focus exclusively on fixing compiler errors with minimal diffs. Do not perform architectural refactoring.",
  "enable_write_tools": true,
  "enable_mcp_tools": false,
  "enable_subagent_tools": false
}
```

### Configuration Parameters

| Parameter | Type | Purpose |
| :--- | :--- | :--- |
| **`name`** | String | Identifier used to spawn instances via `invoke_subagent`. |
| **`description`** | String | Description of subagent specialization and trigger criteria. |
| **`system_prompt`** | String | Specific instructions, behavioral constraints, and tool usage rules. |
| **`enable_write_tools`** | Boolean | Grants file modification (`replace_file_content`, `write_to_file`) and shell execution (`run_command`). Default: `false`. |
| **`enable_mcp_tools`** | Boolean | Grants access to MCP server tools. Default: `false`. |
| **`enable_subagent_tools`** | Boolean | Allows the subagent to recursively define and spawn its own child subagents. Default: `false`. |

---

## 2. Declarative Subagents in Plugins (`subagents.json`)

To bundle reusable subagents with your project or team plugin:

Create `plugins/<plugin_name>/subagents.json`:

```json
{
  "subagents": [
    {
      "name": "security_auditor",
      "description": "Audits dependencies and code changes for security vulnerabilities.",
      "system_prompt": "You are a security auditor. Inspect code for OWASP vulnerabilities, credential leaks, and insecure packages.",
      "enable_write_tools": false,
      "enable_mcp_tools": true,
      "enable_subagent_tools": false
    }
  ]
}
```

---

## 3. Best Practices for Subagent Design

1. **Least Privilege**: Only enable `enable_write_tools` or `enable_subagent_tools` if strictly necessary.
2. **Model Selection on Invocation**:
   - Use `Model: 'flash'` for read-heavy research or unit test runners.
   - Use `Model: 'pro'` for code generation, architectural restructuring, or multi-step logic.
3. **Workspace Scoping**: Use `Workspace: 'branch'` when testing experimental code modifications to avoid corrupting the working tree.
