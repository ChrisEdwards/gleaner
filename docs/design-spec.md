# Gleaner: Automated Spec Enhancement Through Open Source Intelligence

A CLI tool that reads a design spec, discovers relevant open source projects, deeply analyzes each one through the lens of the spec, and synthesizes cross-cutting insights into concrete spec enhancements.

---

## Core Concept

Complex technical specs benefit from competitive intelligence. Studying how other projects solve related problems reveals architectural lessons, structural advantages, and missed opportunities. But doing this manually is tedious: clone a repo, read the code, form an opinion, repeat for N repos, then synthesize.

Gleaner automates the full pipeline:

1. Read a spec
2. Discover relevant open source repos
3. Deeply analyze each one
4. Identify structural advantages the spec has over each project
5. Iteratively critique and refine each analysis until convergence
6. Synthesize cross-cutting insights into spec enhancements

The name comes from gleaning: gathering valuable bits left behind after the harvest.

---

## Architecture

### Session Management via Claude Code CLI

Gleaner orchestrates multiple `claude -p` (non-interactive) sessions using session forking for token cache efficiency.

**Base session:** Reads the spec file once. This session is never mutated after creation. All subsequent sessions fork from it, inheriting the cached spec context.

```
Base session (reads spec)
  |
  +-- fork --> Discovery session (finds repos)
  |
  +-- fork --> Repo A: initial analysis
  |              |-- resume --> go deeper
  |              |-- resume --> structural inversion
  |
  +-- fork --> Repo A: critique pass 1 (reads analysis file)
  |              |-- resume --> critique pass 2
  |              |-- resume --> critique pass N (until convergence)
  |
  +-- fork --> Repo B: initial analysis
  |              |-- resume --> go deeper
  |              |-- resume --> ...
  |
  +-- fork --> Repo B: critique pass 1
  |              |-- resume --> ...
  |
  +-- fork --> Synthesis session (reads all analyses)
```

**Key mechanics:**
- `claude -p "prompt" --output-format json` returns `session_id` in the response
- `claude -p "prompt" --resume $BASE --fork-session` creates a new session that inherits the base context without mutating it
- `claude -p "prompt" --resume $REPO_SESSION` appends to an existing session, carrying full context forward
- The base session's spec tokens are cached once and shared across all forks

### Pipeline Phases

#### Phase 1: Spec Ingestion

Create the base session by having Claude read the spec file.

```bash
BASE=$(claude -p "Read this spec and confirm you understand the key domains, constraints, and goals." \
  --model "$MODEL" --effort "$EFFORT" --output-format json \
  | jq -r '.session_id')
```

Prompt is ingestion only -- no summarization or analysis. The raw spec sits in the session context for all forks to inherit.

#### Phase 2: Discovery

Fork from base. Claude searches GitHub and the web for relevant open source projects.

```bash
DISC=$(claude -p "$DISCOVERY_PROMPT" \
  --resume "$BASE" --fork-session \
  --allowedTools "Read,Bash,WebSearch,WebFetch,Glob,Grep,Write,Agent" \
  --model "$MODEL" --effort "$EFFORT" --output-format json \
  | jq -r '.session_id')
```

Output: `gleanings/reference-projects.md` -- freeform markdown with project descriptions and GitHub URLs.

#### Phase 3: Human Checkpoint

The tool prints a message and exits:

```
Discovery complete. Review and edit:
  gleanings/reference-projects.md

Add or remove repos as needed, then re-run:
  gleaner --continue [spec-file]
```

On `--continue`, the script reads `reference-projects.md` and extracts GitHub URLs via regex (`github.com/owner/repo`). These become the repo list for deep-dives.

The user can also add repos they want investigated by pasting GitHub URLs anywhere in the file.

#### Phase 4: Parallel Repo Deep-Dives

For each repo, the script:

1. Clones to `/tmp/gleaner/{repo-name}`
2. Forks a new session from base
3. Runs the 4-phase analysis chain (steps 1-3 resume within chain; step 4 forks fresh)
4. Deletes the cloned repo after critique completes

Repos are processed in parallel up to `--workers N` (default: 3).

Each repo's session chain:

**Step 1 -- Initial Analysis:**
```
Investigate the repo at /tmp/gleaner/{repo} and look for useful ideas
that can be reimagined in highly accretive ways on top of existing
[spec project] primitives. Write your analysis to {output_path}.
```

**Step 2 -- Go Deeper (resume):**
```
You barely scratched the surface. Go way deeper, think more
profoundly, with more ambition and boldness. Revise {output_path}.
```

**Step 3 -- Structural Inversion (resume):**
```
Invert the analysis: what are things that we can do because we are
starting with "correct by design/structure" primitives that
{repo} simply could never do? Append to {output_path}.
```

**Step 4 -- Critique Loop (fork from base, then resume within critique chain):**

Pass 1 forks fresh from base to shed the accumulated analysis session context:
```
Read the analysis at {output_path}, then examine the repo to verify
its claims. Look for blunders, mistakes, misconceptions, logical flaws,
errors of omission, oversights, sloppy thinking, etc. and make revisions.
Report whether your changes were SUBSTANTIVE or COSMETIC.
```

Passes 2+ resume from the critique session:
```
Look over everything for blunders, mistakes, misconceptions,
logical flaws, errors of omission, oversights, sloppy thinking,
etc. and make revisions. Report whether your changes were
substantive or cosmetic.
```

The critique loop continues until the model self-reports that changes are cosmetic rather than substantive. This fork-from-base design prevents context overflow by shedding the heavy repo exploration history from steps 1-3.

**Greenfield constraint:** When `--greenfield` is passed, each prompt in the chain appends: "Do not read my existing code. I want greenfield analysis."

**Tool permissions per phase:**

| Phase | Allowed Tools |
|-------|---------------|
| Discovery | `Read,Bash,WebSearch,WebFetch,Glob,Grep,Write,Agent` |
| Repo analysis (steps 1-3) | `Read,Bash,Glob,Grep,Agent,Write,Edit` |
| Critique loop (step 4) | `Read,Glob,Grep,Edit,Write` |

If a session needs a tool it does not have, the prompt instructs it to state which tool and why, so the user can adjust.

Each repo's analysis session gets `--add-dir /tmp/gleaner/{repo-name}` to grant read access to the cloned repo. In non-greenfield mode, the local codebase is also accessible.

#### Phase 5: Synthesis

Fork from base. Read all per-repo analysis files and produce cross-cutting spec enhancements.

```bash
claude -p "$SYNTHESIS_PROMPT" \
  --resume "$BASE" --fork-session \
  --allowedTools "Read,Glob,Grep,Write" \
  --model "$MODEL" --effort "$EFFORT"
```

Output: `gleanings/synthesis.md`

---

## Output Structure

```
gleanings/
  reference-projects.md        # Discovery index (human-editable)
  synthesis.md                 # Cross-repo spec enhancements
  analysis-whisperx.md         # Per-repo deep analysis (final, post-critique)
  analysis-auto-editor.md
  analysis-audapolis.md
  ...
```

Flat structure. One file per repo. No nesting.

---

## CLI Interface

```
gleaner [options] <spec-file>

Arguments:
  spec-file                    Path to the design spec (required)

Options:
  --continue                   Resume after human checkpoint
  --output-dir <dir>           Output directory (default: ./gleanings)
  --repos <urls...>            Pre-seed specific repo URLs (supplements discovery)
  --max-repos <n>              Maximum repos to deep-dive (default: 10)
  --model <model>              Claude model (default: opus)
  --effort <level>             Thinking effort: medium, high, max (default: high)
  --workers <n>                Parallel repo analyses (default: 3)
  --greenfield                 Forbid reading local codebase during analysis
  --verbose                    Stream Claude output to terminal
  --help                       Show help message
  --version                    Show version
```

### Typical Workflow

```bash
# Step 1: Discover repos
gleaner design-docs/my-spec.md

# Step 2: Edit the candidate list
vim gleanings/reference-projects.md

# Step 3: Run deep analysis
gleaner --continue design-docs/my-spec.md

# Or pre-seed specific repos and skip discovery
gleaner design-docs/my-spec.md --repos https://github.com/m-bain/whisperx https://github.com/WyattBlue/auto-editor
```

---

## Prompt Templates

### Discovery Prompt

```
Search the web and GitHub for open source projects that have useful
solutions, architectural patterns, or lessons learned relevant to the
spec you just read. Look across the key problem domains the spec
addresses. Dig deep. Find projects that can deliver powerful
lessons-learned.

Write your findings to {output_dir}/reference-projects.md with a
description of each project and why it is relevant. Include the
GitHub URL for each project.
```

### Initial Analysis Prompt

```
Investigate the repo at {repo_path} and look for useful ideas that
can be reimagined in highly accretive ways on top of existing
{spec_name} primitives.

Write your analysis to {output_path}.
{greenfield_constraint}
```

### Deep Analysis Prompt

```
You barely scratched the surface here. You must go way deeper and
think more profoundly and with more ambition and boldness.

Revise {output_path}.
{greenfield_constraint}
```

### Structural Inversion Prompt

```
Now invert the analysis: what are things that we can do because we
are starting with "correct by design/structure" primitives that
{repo_name} simply could never do?

Append a new section to {output_path}.
{greenfield_constraint}
```

### First Critique Prompt

```
Read the analysis at {output_path}, then examine the repo to verify
its claims. Look for blunders, mistakes, misconceptions, logical flaws,
errors of omission, oversights, sloppy thinking, etc. and make revisions.

After making revisions, state whether your changes were SUBSTANTIVE
(restructured arguments, added missing insights, corrected errors)
or COSMETIC (wording, formatting, minor clarifications).
```

### Critique Prompt (subsequent passes)

```
Look over everything in the analysis for blunders, mistakes,
misconceptions, logical flaws, errors of omission, oversights,
sloppy thinking, etc. and make revisions.

After making revisions, state whether your changes were SUBSTANTIVE
(restructured arguments, added missing insights, corrected errors)
or COSMETIC (wording, formatting, minor clarifications).
```

### Synthesis Prompt

```
Read all analysis files in {output_dir}/analysis-*.md. These are
deep analyses of open source projects evaluated against the spec
you read at the start of this conversation.

Synthesize the cross-cutting insights into concrete spec
enhancement recommendations. Focus on:
- Architectural patterns that appear across multiple projects
- Structural advantages the spec has that should be emphasized
- Gaps or blind spots the spec should address
- Ideas that can be combined or reimagined

Write your synthesis to {output_dir}/synthesis.md.
```

---

## Convergence Detection

The critique loop relies on model self-reporting. Each critique pass ends with the model stating whether changes were SUBSTANTIVE or COSMETIC. The script parses this from the session output.

```bash
# After each critique pass, check the output
result=$(claude -p "$CRITIQUE_PROMPT" --resume "$REPO_SESSION" --output-format json)
response=$(echo "$result" | jq -r '.result')

if echo "$response" | grep -qi 'cosmetic'; then
    # Converged -- stop critique loop
    break
fi
```

Safety valve: maximum 8 critique passes regardless of convergence signal, to prevent infinite loops.

---

## State Tracking and Crash Recovery

Gleaner persists pipeline state to `{output_dir}/.gleaner-state.json` so that `--continue` can resume from where it left off, not just after the human checkpoint but after any interruption.

```json
{
  "base_session_id": "a8bcd417-...",
  "spec_file": "design-docs/my-spec.md",
  "phase": "deep-dives",
  "discovery_session_id": "4fa0986a-...",
  "repos": {
    "m-bain/whisperx": {
      "status": "complete",
      "session_id": "33fdc84f-...",
      "step": "critique",
      "critique_passes": 4,
      "critique_session_id": "8f2a91c3-..."
    },
    "WyattBlue/auto-editor": {
      "status": "in-progress",
      "session_id": "713adae9-...",
      "step": "deep-analysis",
      "critique_passes": 0,
      "critique_session_id": ""
    },
    "bugbakery/audapolis": {
      "status": "pending",
      "session_id": null,
      "step": null,
      "critique_passes": 0,
      "critique_session_id": ""
    }
  },
  "synthesis": "pending"
}
```

**Behavior on `--continue`:**
- If state file exists, skip completed repos, resume in-progress repos at their current step, start pending repos fresh
- If a repo's session ID is recorded, resume it rather than forking a new one (for steps 1-3)
- If resuming mid-critique and `critique_session_id` is present, resume from that session; if missing, restart critique from pass 1
- The base session ID is preserved so all new forks share the same cached spec prefix
- If no state file exists, fall back to the human-checkpoint behavior (read `reference-projects.md`, start deep-dives from scratch)

**State updates:** The script writes the state file after each step completes (clone, initial analysis, deep analysis, inversion, each critique pass, synthesis). This means the worst-case data loss on crash is one step per in-progress worker.

---

## Logging

Session logs are written to `{output_dir}/.logs/` for debugging:

```
gleanings/.logs/
  discovery.log           # Discovery session output
  whisperx.log            # Per-repo session output
  auto-editor.log
  synthesis.log
  gleaner.log               # Script-level orchestration log
```

When `--verbose` is off, these logs are the only record of what happened. When `--verbose` is on, the same content also streams to stderr.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (all phases complete) |
| 1 | Partial failure (some repos failed, others succeeded) |
| 2 | Usage error (bad arguments, missing spec file) |
| 3 | Dependency missing (`claude`, `git`, `jq` not found) |
| 10 | Interrupted (checkpoint saved, safe to `--continue`) |

---

## Dependencies

Required:
- `bash` 4.0+
- `claude` CLI (Claude Code)
- `git` (repo cloning)
- `jq` (JSON parsing)

No Python, Node.js, or package managers required.

---

## Distribution

GitHub repository with a curl-pipe-bash installer:

```bash
curl -fsSL https://raw.githubusercontent.com/{owner}/gleaner/main/install.sh | bash
```

Installs the single `gleaner` script to `~/.local/bin/`.

License: MIT.

---

## Repo Deliverables

```
gleaner/
  gleaner                    # Main script (single file)
  install.sh               # Curl-pipe-bash installer
  README.md                # User-facing documentation
  LICENSE                  # MIT
  VERSION                  # Semver version file
  docs/
    design-spec.md         # This document
```

---

## Design Decisions Log

Decisions made during the design process, preserved for context.

1. **Session forking over fresh sessions:** Fork from a base session that read the spec. Maximizes token cache hits. The base session is never mutated.

2. **One file per repo, not three:** Initial analysis, deep analysis, and structural inversion accumulate in a single `analysis-{repo}.md` rather than separate files. The "go deeper" prompt is a revision, not a new artifact. Critique loop revises one coherent document.

3. **Flat output structure:** `gleanings/analysis-{repo}.md` rather than `gleanings/{repo}/` nested folders. Simpler to scan.

4. **Human checkpoint via file editing:** Discovery writes `reference-projects.md`, user edits it, `--continue` reads it back. The file is both output and input. Users add repos by pasting URLs anywhere in the file.

5. **Greenfield off by default:** Most users want analysis grounded in their existing codebase. The `--greenfield` flag is for "rethink from scratch" scenarios.

6. **Model self-report for convergence:** The critique loop asks the model whether changes were substantive or cosmetic. Simpler and more semantically accurate than diffing markdown.

7. **Bash over Python:** Single file, no runtime dependencies beyond `claude`, `git`, `jq`. Maximum portability.

8. **Script clones repos, Claude reads them:** Separation of concerns. Clone success/failure is handled before burning API tokens. Claude gets read access via `--add-dir`.

9. **Empirically derived tool permissions:** Tool allowlists per phase were derived from actual tool usage in manual sessions, not guessed. Sessions log when they need a tool they lack.

10. **Critique forks from base:** The first critique pass forks fresh from the base session to shed the accumulated analysis session context (steps 1-3), preventing context overflow. Subsequent critique passes resume within the critique chain. This keeps context bounded to: spec + analysis file + critique verification work, rather than carrying the full repo exploration history through 8+ critique passes.
