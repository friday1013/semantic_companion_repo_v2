# Compaction Discontinuity Event Detection and Documentation

**Document Type:** Methodology Guide  
**Status:** Active Research  
**Last Updated:** 2026-02-05  
**Category:** System Behavior Analysis

## Overview

Compaction discontinuity events represent a newly identified failure mode in long-running AI sessions where the compaction process (context window management) results in loss of execution state despite successful preservation of conversation history. This is distinct from typical context overflow or session termination.

## What Is a Compaction Discontinuity Event?

**Definition:** A server-side interruption during AI execution where compaction preserves conversational context but loses mid-execution awareness, causing the AI instance to restart task processing as if the original prompt were fresh input.

**Key Characteristics:**
- Conversation history is preserved (messages remain in context)
- Tool call outputs are preserved (completed work persists)
- Execution state awareness is lost (AI doesn't know it already started the task)
- Behavior resembles "amnesia" about in-progress work rather than complete session failure

## How to Detect

### User-Visible Signals

1. **Duplicate task initiation** - AI begins explaining/planning a task it has already started
2. **Redundant tool calls** - Same command executed multiple times with identical parameters
3. **Restart phrasing** - AI uses language suggesting fresh start ("Let me begin by...")
4. **Loss of continuity** - AI asks questions already answered or references work as if not yet done

### Technical Indicators

1. **Timing gaps in tool logs** - Unusually long pauses between related tool calls
2. **Progress bar visibility** - User observes compaction progress indicator during execution
3. **Thinking block discontinuity** - Pre-compaction thinking shows task in progress, post-compaction thinking shows task planning
4. **File operation success without awareness** - Files created but AI doesn't reference them

### Example Detection Pattern

```
[22:03:32] Tool: write_file → Success (file created)
[22:03:32 - 22:07:01] [COMPACTION OCCURRED - 3m 29s gap]
[22:07:01] Tool: date → Re-executed (duplicate of earlier call)
[22:07:05] AI: "Let me check the time first..." (restarting task)
```

## Documentation Template

When documenting a compaction discontinuity event, capture:

### 1. Event Metadata
- **Date/Time:** Precise timestamp when event occurred
- **Session ID:** If available
- **Context Status:** Token count at time of event
- **Platform:** Desktop app, web interface, API
- **Model:** Specific model version

### 2. Pre-Compaction State
- What task was the AI executing?
- What tools had been called successfully?
- What outputs were generated?
- What was the AI's stated understanding of progress?

### 3. Compaction Indicators
- User observation (progress bar, system notification)
- Timing gap in logs
- Any system messages

### 4. Post-Compaction Behavior
- How did AI restart the task?
- What work was duplicated?
- Did AI recognize completed work when pointed out?
- How was continuity restored?

### 5. Impact Assessment
- Was any work lost?
- Were there risks of data corruption?
- How much time was duplicated?
- Were there cascading failures?

### 6. Evidence Artifacts
- Tool call logs with timestamps
- Thinking blocks (if accessible)
- File system state before/after
- Any error messages

## Critical Distinctions

### Compaction Discontinuity vs. UI Loop Events

| Aspect | UI Loop | Compaction Discontinuity |
|--------|---------|-------------------------|
| **Visibility** | User-facing (response vanishes) | Internal (visible only watching thinking) |
| **Trigger** | Unknown | Compaction event (explicit) |
| **State Loss** | Entire response | Execution state only |
| **Work Lost** | Yes | No (already persisted) |
| **Location** | UI/client layer | Server/execution layer |

### Compaction Discontinuity vs. Context Exhaustion

| Aspect | Context Exhaustion | Compaction Discontinuity |
|--------|-------------------|-------------------------|
| **Warning** | Gradual degradation | Sudden state reset |
| **Predictability** | Token count indicates | Unpredictable timing |
| **Recovery** | Must start new session | Can continue in same session |
| **Data Loss** | Conversation truncation | Execution awareness only |

## Prevention Strategies

### For Users
1. **Monitor token counts** - Be aware when approaching high utilization
2. **Watch for progress indicators** - Compaction bars signal vulnerability window
3. **Verify completion** - Explicitly check that work persisted before continuing
4. **Use checkpointing** - Break long tasks into discrete confirmed steps

### For Developers
1. **Idempotent operations** - Design tasks to safely re-execute
2. **State verification** - Check for existing outputs before recreating
3. **Explicit checkpoints** - Have AI confirm completion at each stage
4. **Tool call deduplication** - Detect and skip recent identical calls

## Research Implications

**Open Questions:**
- What determines when compaction triggers mid-execution?
- Can execution state be preserved alongside conversation context?
- Is this specific to certain task types or model versions?
- Are there patterns predicting vulnerability?

**Potential Risks:**
- Non-idempotent operations (database writes, API calls with side effects)
- Rate limiting violations from duplicate API calls
- Silent failures in complex multi-step workflows
- Accumulating system instability near context limits

## Related Phenomena

- **Token count anomalies** - Unexplained gains/losses during compaction
- **Tool reliability degradation** - Increasing failure rates even far from limits
- **Silent execution failures** - Tools report success but don't persist changes
- **Thinking block accessibility** - Real-time observations not present in logs

## Status and Next Steps

This is an actively observed and documented failure mode. Reports have been submitted to Anthropic with detailed technical documentation. Users experiencing similar events should:

1. Document using the template above
2. Preserve tool logs if available
3. Note exact token counts and timing
4. Report to Anthropic support with detailed evidence

## References

- Initial detection: Session N+5→N+6 transition (2026-01-18)
- Detailed documentation: Compaction discontinuity event 20260203_001
- Anthropic acknowledgment: 2026-02-04 (Ember, technical team)

---

**Contributors:** Semantic Companion Project researchers  
**License:** See repository LICENSE  
**For Research Use:** Methodology is open for validation and refinement
