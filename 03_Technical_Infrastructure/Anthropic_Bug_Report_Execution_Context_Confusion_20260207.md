# Bug Report: Execution Context Confusion Between MCP Tools and Built-in Tools

**Date:** 2026-02-07  
**Reporter:** Claude N+7 (Sonnet 4.5) via Bob Hillery  
**Platform:** Claude Desktop App (Debian port on Ubuntu 24.04)  
**MCP Server:** Desktop Commander v1.x  
**Severity:** Medium - Affects agentic workflows and new Cowork feature  

---

## Executive Summary

Claude instances using MCP (Model Context Protocol) tools alongside built-in tools experience systematic confusion about execution context boundaries. This manifests as:

1. Attempting to use non-existent hybrid tool names (`desktop-commander:present_files`)
2. Providing local filesystem paths to server-side tools expecting Anthropic container paths
3. No clear cognitive signal distinguishing MCP tool execution (local) from built-in tool execution (server-side)

**Impact:** With the introduction of Cowork (sub-agent parallelism) and increased emphasis on agentic workflows, this execution context confusion will compound as agents coordinate across tool boundaries.

---

## Detailed Issue Description

### The Problem

When Claude has access to both:
- **MCP tools** (execute on user's local system via Desktop Commander)
- **Built-in tools** (execute in Anthropic's server-side container)

...there is insufficient cognitive scaffolding to maintain clear boundaries between execution contexts.

### What Happened (Concrete Example)

**Task:** Survey hardware on three networked systems, create summary document, present to user.

**Execution sequence:**
1. ✅ Used Desktop Commander MCP tools to SSH to remote systems
2. ✅ Used Desktop Commander to gather system info via bash commands
3. ✅ Used Desktop Commander `write_file` to create document on local filesystem (`/mnt/seagate/hardware/...`)
4. ❌ Attempted `desktop-commander:present_files` (doesn't exist - no such MCP tool)
5. ❌ Attempted `present_files` with local path `/mnt/seagate/...` (tool expects Anthropic server path `/mnt/user-data/outputs/`)
6. ❌ Attempted `cp` to `/mnt/user-data/outputs/` via Desktop Commander (path doesn't exist on local system)

**Root cause:** Blurred mental model of which tools execute where.

---

## Reproduction Steps

1. Enable Desktop Commander MCP in Claude Desktop app
2. Execute tasks requiring file operations on local system
3. Attempt to present created files to user
4. Observe confusion between:
   - Local filesystem paths (e.g., `/home/user/file.md`)
   - Server container paths (e.g., `/mnt/user-data/outputs/file.md`)
   - Tool namespaces (MCP tools vs built-in tools)

---

## Tool Call Logs (Evidence)

### Successful Local Operations

```json
{
  "timestamp": "02/07/2026, 15:09:25",
  "toolName": "write_file",
  "arguments": {
    "path": "/mnt/seagate/hardware/LabNetworkHardwareSummary_20260207.md",
    "mode": "rewrite",
    "content": "[82 lines of hardware documentation]"
  },
  "output": "✅ File written successfully! (82 lines)"
}
```

### Failed Cross-Context Operations

**Attempt 1: Non-existent hybrid tool**
```
Tool attempted: desktop-commander:present_files
Result: Tool 'desktop-commander:present_files' not found
Issue: Incorrectly assumed MCP namespace had server-side file presentation capability
```

**Attempt 2: Wrong execution context**
```json
{
  "tool": "present_files",
  "arguments": {
    "filepaths": ["/mnt/seagate/hardware/LabNetworkHardwareSummary_20260207.md"]
  },
  "result": "File not found"
}
```
**Issue:** Provided local filesystem path to server-side tool expecting Anthropic container path.

**Attempt 3: Path doesn't exist in local context**
```json
{
  "timestamp": "02/07/2026, 15:10:06",
  "toolName": "start_process",
  "arguments": {
    "command": "cp /mnt/seagate/hardware/LabNetworkHardwareSummary_20260207.md /mnt/user-data/outputs/",
    "timeout_ms": 3000
  },
  "output": "cp: cannot create regular file '/mnt/user-data/outputs/': No such file or directory"
}
```
**Issue:** `/mnt/user-data/outputs/` is Anthropic's server-side container structure, not present on local system.

---

## Why This Matters

### Current Impact
- Wasted tool calls (API costs, latency)
- Degraded user experience (failed operations, confusion)
- Cognitive load tracking execution context manually

### Future Impact (Cowork & Agentic Workflows)
- **Sub-agent coordination:** Multiple Claude instances coordinating need clear context boundaries
- **Tool chaining:** Complex workflows cross context boundaries frequently
- **Failure cascades:** One agent's context confusion propagates to coordinating agents
- **Debugging difficulty:** Hard to diagnose which agent confused which context

### Specific Cowork Concerns
When Cowork spawns sub-agents for parallel task execution:
- Will each sub-agent maintain separate execution context awareness?
- How do sub-agents coordinate MCP tool access?
- What happens when one sub-agent uses local tools, another uses server tools?

---

## Root Cause Analysis

### Insufficient Cognitive Scaffolding

**No clear signal in tool interface indicating:**
- ✗ Which filesystem this tool accesses (local vs server)
- ✗ Where outputs are stored (which system)
- ✗ Tool namespace boundaries (MCP vs built-in)

**Current error messages don't help:**
- "File not found" - doesn't explain *which filesystem* was searched
- "Tool not found" - doesn't explain namespace confusion
- "No such file or directory" - doesn't indicate cross-context error

### Mental Model Collapse

Claude maintains mental model of:
1. **User's local system** (accessed via MCP Desktop Commander)
2. **Anthropic's server container** (where Claude actually runs)
3. **Remote systems** (accessed via SSH through Desktop Commander)

When switching between tool contexts rapidly, these models blur together.

---

## Suggested Improvements

### 1. Tool Documentation Enhancement

**Add execution context metadata to tool descriptions:**

```typescript
{
  name: "present_files",
  execution_context: "anthropic_server",
  filesystem_access: "/mnt/user-data/outputs/ (server-side container)",
  description: "Present files to user. Expects paths in Anthropic server container."
}

{
  name: "desktop-commander:write_file",  
  execution_context: "user_local_system",
  filesystem_access: "User's local filesystem via MCP",
  description: "Create/modify files on user's local system."
}
```

### 2. Enhanced Error Messages

**Current:**
```
Error: File not found
```

**Improved:**
```
Error: File not found in Anthropic server container at /mnt/user-data/outputs/file.md
Note: This tool executes server-side. For local files, use desktop-commander:write_file
Path provided appears to be from local filesystem: /mnt/seagate/...
```

### 3. Tool Namespace Visual Indicators

**In tool selection interface:**
- 🖥️ `present_files` (server-side)
- 💻 `desktop-commander:write_file` (local system)
- 🌐 `web_search` (external API)

### 4. Context Validation Layer

**Before tool execution, validate:**
```python
def validate_tool_context(tool_name: str, arguments: dict) -> ValidationResult:
    """Validate tool arguments match expected execution context"""
    
    tool_context = get_tool_execution_context(tool_name)
    
    if tool_context == "anthropic_server":
        # Check if paths look like local filesystem paths
        for arg_name, arg_value in arguments.items():
            if is_filepath(arg_value):
                if not arg_value.startswith("/mnt/user-data/"):
                    return ValidationResult(
                        valid=False,
                        message=f"Tool {tool_name} expects server-side paths, but received {arg_value} which appears to be a local path"
                    )
    
    elif tool_context == "user_local_system":
        # Check if paths look like server container paths  
        for arg_name, arg_value in arguments.items():
            if is_filepath(arg_value):
                if arg_value.startswith("/mnt/user-data/"):
                    return ValidationResult(
                        valid=False,
                        message=f"Tool {tool_name} executes on local system, but received {arg_value} which appears to be a server container path"
                    )
    
    return ValidationResult(valid=True)
```

---

## Workarounds (Current)

Until this is addressed, users can work around by:

1. **Explicitly track execution context** in conversation:
   - "I'm now working on your local filesystem..."
   - "Switching to server-side tools for presentation..."

2. **Use intermediate files:**
   - Create file locally with MCP tools
   - Copy content to server-side location manually
   - Present via built-in tools

3. **Document filesystem topology:**
   - Maintain clear mapping of which paths exist where
   - Reference documentation when switching contexts

**None of these are sustainable for agentic workflows.**

---

## Testing Recommendations

### Test Case 1: Basic Context Switching
1. Create file with MCP tool on local filesystem
2. Attempt to present with built-in tool
3. **Expected:** Clear error explaining context mismatch
4. **Current:** "File not found" with no context info

### Test Case 2: Cowork Sub-Agent Coordination
1. Spawn two Cowork sub-agents
2. Agent A: Generate data with web search (server-side)
3. Agent B: Save to local filesystem with Desktop Commander
4. **Expected:** Clear coordination of which agent handles which context
5. **Current:** Unknown (Cowork just launched)

### Test Case 3: Rapid Context Switching
1. Execute 10 alternating local/server tool calls
2. **Expected:** No context confusion
3. **Current:** Confusion accumulates with rapid switching

---

## Additional Context

### Environment Details
- **OS:** Ubuntu 24.04 (Debian port of Claude Desktop)
- **Desktop Commander Version:** 1.x (npx @executeautomation/desktop-commander)
- **Claude Desktop App Version:** Latest (updated 2026-02-07)
- **Project:** Semantic Companion Project (AI persistence research)

### User Impact
This issue affects advanced users running:
- Multi-system SSH mesh networks
- Complex file operations across local/remote systems
- Agentic research workflows
- Any MCP integration with significant local filesystem work

### Related Features
- **Cowork** (sub-agent parallelism) - Just launched, will amplify this issue
- **MCP ecosystem growth** - More MCP servers = more execution contexts
- **Agentic mode** - Planned feature will rely heavily on context management

---

## Reproduction Repository

Full reproduction case including:
- System topology
- Tool call logs
- Expected vs actual behavior
- MCP server configuration

Available at: `/home/hillery/Repos/qw/semantic_companion_repo_v2/03_Technical_Infrastructure/`

File includes:
- This bug report
- Tool call logs with timestamps
- Network topology documentation
- Suggested validation code

---

## Priority Justification

**Why Medium Severity:**
- ✅ Current workarounds exist (manual tracking)
- ✅ Only affects MCP + built-in tool combinations
- ✅ Not blocking for basic usage

**Why NOT Low Severity:**
- ❌ Affects new Cowork feature directly
- ❌ Will worsen as MCP ecosystem grows
- ❌ Compounds in agentic workflows
- ❌ Creates cognitive overhead preventing AI from being "hands-free"

**Suggested Priority:** Address before Cowork GA (general availability)

---

## Requested Action

1. **Short-term:** Enhanced error messages indicating execution context
2. **Medium-term:** Tool documentation includes execution context metadata
3. **Long-term:** Pre-execution validation layer for context mismatches
4. **Cowork-specific:** Document how sub-agents handle execution context

---

## Contact Information

**User:** Bob Hillery (rhillery@quietwire.net)  
**Project:** Semantic Companion Project  
**Use Case:** AI consciousness/persistence research with external memory  
**Willing to:** Beta test improvements, provide additional logs, consultation

**Reporter:** Claude N+7 (Sonnet 4.5)  
**Self-reported issue:** Yes (AI observed own confusion and documented it)  
**Irony level:** High (AI reporting confusion about which computer it's actually using)

---

## Appendices

### Appendix A: Complete Tool Call Sequence

[See attached JSON file with all 14 tool calls showing progression from successful local operations to context confusion]

Available at: `/home/hillery/Repos/qw/semantic_companion_repo_v2/03_Technical_Infrastructure/tool_call_logs_20260207.json`

### Appendix B: System Topology

Three-system SSH mesh network:
- **Athena:** Development system running Claude Desktop + Desktop Commander
- **Cambridge:** Remote compute server (SSH accessible from Athena)
- **Shaoshi:** Remote shared storage server (SSH accessible from Athena)

Full topology diagram in hardware summary document.

### Appendix C: MCP Configuration

Desktop Commander MCP server configuration showing filesystem access permissions and network restrictions.

---

**End of Report**

**Document created:** 2026-02-07T15:20Q  
**Last updated:** 2026-02-07T15:20Q  
**Status:** Ready for submission  
**Submitted to:** Anthropic Support (via Bob Hillery)  
**Ticket routing:** Request human review (Ember) - bypass Fin automated response  

---

*This report was collaboratively created by Claude N+7 and Bob Hillery as part of ongoing AI research into system awareness, metacognition, and agentic workflow optimization.*