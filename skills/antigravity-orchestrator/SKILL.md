---
name: antigravity-orchestrator
description: Specialist skill for architecting, delegating, and orchestrating multi-subagent swarms, workspace isolation modes, dynamic model routing, and asynchronous background tasks in Google Antigravity. Use when breaking down complex engineering tasks into parallel subagents, configuring branch/share workspaces, or coordinating autonomous task execution.
---

# Antigravity Multi-Subagent Orchestrator

This skill provides operational patterns, templates, and execution runbooks for coordinating multi-agent workflows within Google Antigravity.

---

## 1. Subagent Delegation Matrix

When initiating a multi-part engineering initiative, decompose tasks according to the delegation matrix:

| Task Phase | Subagent Role | Model Tier | Workspace Mode | Tool Permissions |
| :--- | :--- | :--- | :--- | :--- |
| **1. Research & Analysis** | `Codebase Researcher` | `flash` | `inherit` | Read-only (`enable_write_tools: false`) |
| **2. Architecture & Design** | `System Architect` | `pro` | `inherit` | Read + Artifacts planning |
| **3. Implementation** | `Core Developer` | `pro` | `inherit` (or `branch`) | Full write tools (`enable_write_tools: true`) |
| **4. Testing & Verification** | `Test & Build Runner` | `flash` | `inherit` | Command runner + analyzer |
| **5. Code Review & Lint** | `Security & Code Reviewer` | `pro` | `inherit` | Read-only diff inspector |

---

## 2. Standard Orchestration Runbook

### Step 1: Parallel Invocation

Spawn parallel agents in a single invocation to execute independent research and validation simultaneously:

```json
{
  "Subagents": [
    {
      "TypeName": "research",
      "Role": "API Researcher",
      "Model": "flash",
      "Workspace": "inherit",
      "Prompt": "Analyze the state management bindings in lib/modules/ and report state lifecycle patterns."
    },
    {
      "TypeName": "research",
      "Role": "Dependency Inspector",
      "Model": "flash_lite",
      "Workspace": "inherit",
      "Prompt": "Check pubspec.yaml and verify null-safety and version compatibility of all third-party plugins."
    }
  ]
}
```

---

### Step 2: Dynamic Custom Subagent Definition

If a specialized task requires custom instructions (e.g. isolated build error resolver):

```json
{
  "name": "isolated_compiler_fixer",
  "description": "Fixes compile errors on an isolated branch workspace.",
  "system_prompt": "You are a dedicated compile error resolver. Fix syntax and type issues reported by dart analyze. Make minimal diffs.",
  "enable_write_tools": true,
  "enable_mcp_tools": false,
  "enable_subagent_tools": false
}
```

Then invoke with `Workspace: 'branch'`:

```json
{
  "Subagents": [
    {
      "TypeName": "isolated_compiler_fixer",
      "Role": "Branch Fixer",
      "Model": "pro",
      "Workspace": "branch",
      "Prompt": "Run flutter analyze and fix type errors in lib/modules/native/."
    }
  ]
}
```

---

### Step 3: Asynchronous Wakeup & Message Coordination

- Do **not** loop on `manage_subagents(Action='list')`.
- When subagents complete their assignments, Antigravity automatically delivers their return payloads into context.
- Use `send_message` with the existing `conversationId` to follow up or request refinements.

---

## 3. Background Task Watchdog Pattern

For long-running compilations or background services:

1. Launch process with `run_command` setting `WaitMsBeforeAsync: 1000`.
2. Schedule a one-shot watchdog timer with `TimerCondition: '<task-id>'`:
   ```json
   {
     "DurationSeconds": 600,
     "Prompt": "Check build status if not completed yet",
     "TimerCondition": "task-102"
   }
   ```
3. Proceed with other editing or research work. If the task completes early, the timer automatically self-cancels.
