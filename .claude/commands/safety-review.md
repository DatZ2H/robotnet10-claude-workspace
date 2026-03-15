---
description: Review safety-critical changes before commit — scan diff, verify checklist
---

# Safety Review

You are reviewing uncommitted changes in safety-critical zones before they are committed.

## Steps

1. Run `git diff --name-only` to get all changed files
2. Filter files matching safety zones:
   - `**/Motion/**`
   - `**/CANOpen/**`
   - `**/CiA402/**`
   - `**/Services/Navigation/**`
   - `**/Services/State/**`
3. If NO safety-critical files changed, report "No safety-critical files in diff" and exit
4. For EACH safety-critical file found:
   - Read the full diff for that file using `git diff <file>`
   - Evaluate against ALL 8 checklist items from `.claude/rules/safety-critical.md`:
     - [ ] E-Stop path not blocked or bypassed
     - [ ] CiA402 state transitions follow spec
     - [ ] No hardcoded velocity values bypassing IVelocityController
     - [ ] Unit test coverage exists or is added
     - [ ] Async operations have appropriate timeouts
     - [ ] Failure paths transition to safe state (motor disabled)
     - [ ] SLAM/Localization changes don't degrade pose estimation
     - [ ] CeresSharp P/Invoke uses SafeHandle, no memory leaks
5. Output a structured report:

```
## Safety Review Report

### Files reviewed
- <list of safety-critical files>

### Per-file assessment
#### <filename>
- [PASS/FAIL/N/A] E-Stop path
- [PASS/FAIL/N/A] CiA402 transitions
- ... (all 8 items)
- Notes: <any concerns>

### Overall verdict: PASS / FAIL / NEEDS ATTENTION
```

6. If any item is FAIL, clearly explain the risk and suggest remediation

> [!WARNING]
> This review is a safety aid, not a replacement for human review.
> Always have a domain expert verify safety-critical changes.
