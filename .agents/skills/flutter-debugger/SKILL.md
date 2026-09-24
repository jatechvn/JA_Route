---
name: flutter-debugger
description: A bug-fixing skill based on the Hypothesis-Driven Debugging method. Activates when there is a critical error, an unclear error, or when repeated fix attempts have failed.
---

# Flutter Debugger Skill (Hypothesis-Driven)

This skill applies systematic debugging thinking — instead of guessing at the code, it focuses on identifying the Root Cause of the error in a Flutter project.

## Execution Process (For the Agent)
1. **Gather Data (Context):** Do not fix the code right away. If the user only provides a short error message, ask them to provide the full Stack Trace or the content of the relevant file.
2. **Analyze:** Automatically run the `flutter analyze` command or carefully read the Stack Trace to trace the called functions (Call Stack).
3. **Form a Hypothesis:**
   - Think step-by-step about the data flow that causes the error.
   - Clearly state at least 2 POSSIBLE root causes.
4. **Propose and Fix:**
   - Based on the most plausible hypothesis, proceed to fix the source code.
   - **Assume Wrong Rule:** If the user reports that the fix did not work, the Agent MUST assume the previous approach was wrong. Completely discard the old direction and move on to the second hypothesis.
5. **Guard Against Future Issues:** After the fix is complete, remind the user about Edge Cases (null data, network errors, etc.) that could break this logic in the future.
