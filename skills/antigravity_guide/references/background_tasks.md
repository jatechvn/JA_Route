# Antigravity Background Tasks & Schedulers Reference

Antigravity enables non-blocking, asynchronous execution of long-running operations and recurring jobs directly within the agent workflow.

---

## 1. Asynchronous Terminal Commands (`run_command` & `manage_task`)

When terminal commands (such as dev servers, long builds, or test suites) take significant time:

### Command Execution Modes
- **Synchronous Execution**: Set `WaitMsBeforeAsync` to a high value (up to 10,000ms) if the command should finish within that window and return output immediately.
- **Asynchronous Detachment**: If the command takes longer than `WaitMsBeforeAsync`, Antigravity detaches it into a background task and returns a `TaskId`.
- **Daemon Processes (`IsDaemon: true`)**: Used for persistent background servers (e.g. `npm run dev`, `flutter run`) that do not exit on their own.

### Task Management (`manage_task`)
- **`Action: 'list'`**: Lists all running background tasks.
- **`Action: 'status'`**: Checks current status and fetches log file location.
- **`Action: 'send_input'`**: Sends standard input (stdin) to an interactive process.
- **`Action: 'kill'`**: Terminates a running task.

> [!IMPORTANT]
> **Zero-Polling Principle**: Do **not** poll `manage_task(Action='status')` in a loop. When a background task completes or outputs critical logs, Antigravity automatically triggers a reactive wakeup and delivers the notification to the agent.

---

## 2. Advanced Schedulers (`schedule`)

Antigravity provides native scheduling capabilities for one-shot timers and recurring cron triggers without relying on OS `sleep` loops.

### Mode A: One-Shot Timers (`DurationSeconds`)

Used for delayed notifications or watchdog timeouts.

```json
{
  "DurationSeconds": 300,
  "Prompt": "Check build status if not completed yet",
  "TimerCondition": "task-xyz"
}
```

**`TimerCondition` Rules**:
- **`never`** (Default): Fires unconditionally after `DurationSeconds`.
- **`any`**: Cancels early if *any* message from any subagent or background task is received before the timer expires.
- **`<sender-id>`**: Cancels early only if a message arrives from the specific `conversationId` or `TaskId`.

### Mode B: Recurring Cron Jobs (`CronExpression`)

Used for periodic health checks, sync routines, or telemetry.

```json
{
  "CronExpression": "*/5 * * * *",
  "MaxIterations": 12,
  "IsDaemon": false,
  "Prompt": "Run health check and analyze system status"
}
```

- **`CronExpression`**: Standard 5-field cron syntax (`minute hour dom month dow`).
- **`MaxIterations`**: Optional limit on execution cycles.
- **`IsDaemon`**:
  - `false`: Active part of the current agent conversation task.
  - `true`: Standing independent job that continues running in the background after the current agent conversation completes.
