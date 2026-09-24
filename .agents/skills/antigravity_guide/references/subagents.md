# Antigravity Subagents Reference

Antigravity features a native, hierarchical multi-agent orchestration engine. The primary agent can dynamically define custom subagents, invoke specialized worker agents in parallel, allocate isolated workspaces, route model tiers, and coordinate tasks via asynchronous message passing.

---

## 1. Subagent Lifecycle & Tool Suite

The multi-subagent system is governed by four core tools:

1. **`define_subagent`**: Dynamically creates a new subagent type during runtime.
   - `name`: Unique type name for invoking.
   - `description`: Purpose and trigger condition.
   - `system_prompt`: Specialized system instructions.
   - `enable_write_tools`: Grants file editing and terminal command execution.
   - `enable_mcp_tools`: Grants access to Model Context Protocol servers.
   - `enable_subagent_tools`: Allows recursive subagent creation and spawning.

2. **`invoke_subagent`**: Spawns one or more subagents concurrently.
   - `TypeName`: The registered or built-in subagent type (e.g., `research`, `self`, or custom defined).
   - `Role`: Human-readable title (e.g., `Codebase Researcher`, `Compiler Debugger`).
   - `Prompt`: Actionable instructions for the subagent.
   - `Model`: Target model tier (`inherit`, `flash_lite`, `flash`, `pro`).
   - `Workspace`: Workspace isolation mode (`inherit`, `branch`, `share`).

3. **`manage_subagents`**: Controls active subagents.
   - `Action: 'list'`: Reports active conversation IDs, lifecycle states (`running`, `idle`, `waiting_for_input`, `waiting_for_dependents`, `waiting_for_message`, `canceling`, `errored`), and current tool execution context.
   - `Action: 'kill'`: Terminates specific subagents and deletes branched workspaces.
   - `Action: 'kill_all'`: Terminates all subagents and descendants.

4. **`send_message`**: Sends instructions or queries directly to a subagent's `conversationId`.

---

## 2. Workspace Isolation Modes

When spawning subagents, choose the workspace mode that fits the subagent's blast radius:

| Workspace Mode | Behavior | Best Use Case |
| :--- | :--- | :--- |
| **`inherit`** (Default) | Operates in the exact same directory as the parent agent. Edits affect the live workspace immediately. | Read-only analysis, in-place refactoring, direct code updates. |
| **`branch`** | Clones/branches a completely isolated workspace copy. Discarded if the subagent is killed or fails. | Experimental refactoring, breaking dependency upgrades, untrusted code execution. |
| **`share`** | Shares underlying repository object storage (similar to `git worktree` / `hg share`) with an independent working branch. | Multi-branch feature development without duplicating disk space. |

---

## 3. Dynamic Model Routing & Cost Tiering

To maximize speed and optimize token efficiency, route subtasks to the appropriate model tier:

* **`flash_lite`**: Ultra-lightweight and fastest. Ideal for quick string parsing, simple regex scans, or single file evaluations.
* **`flash`**: Balanced speed and intelligence. Best for codebase research, directory exploration, reading multiple files, and running test commands.
* **`pro`**: Maximum reasoning power and deep context synthesis. Best for architectural refactoring, complex bug debugging, and multi-file logic design.
* **`inherit`**: Uses the same model configured on the parent agent.

---

## 4. Reactive Inter-Agent Messaging (No Polling)

Subagents communicate with the parent agent and peer agents asynchronously:

* **No Busy-Waiting**: The parent agent does **not** need to poll `manage_subagents` in a loop. When a subagent completes its task or sends a message, the system automatically wakes up the parent agent with the full message content.
* **Continuous Continuation**: If a subagent finishes a task but is still relevant, send subsequent prompts using `send_message` with its `conversationId` rather than spawning a new subagent.
