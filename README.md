# Gleaner

<p align="center">
  <img src="docs/gleaner.png" alt="The Gleaning — AI-powered combine harvesting insights from open source fields" width="700" />
</p>

Automated spec enhancement through open source intelligence.

Gleaner reads a design spec, discovers relevant open source projects, deeply analyzes each one through the lens of the spec, and synthesizes cross-cutting insights into concrete spec enhancements.

## Requirements

- bash 4.0+
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- git
- jq

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/{owner}/gleaner/main/install.sh | bash
```

Or clone and use directly:

```bash
git clone https://github.com/{owner}/gleaner.git
cd gleaner
./gleaner --help
```

## Usage

```
gleaner [options] <spec-file>

Options:
  --continue            Resume after editing the discovery list or after interruption
  --output-dir <dir>    Output directory (default: ./gleanings)
  --repos <urls...>     Pre-seed specific repo URLs (skips discovery)
  --max-repos <n>       Maximum repos to deep-dive (default: 10)
  --model <model>       Claude model (default: opus)
  --effort <level>      Thinking effort: medium, high, max (default: high)
  --workers <n>         Parallel repo analyses (default: 3)
  --greenfield          Forbid reading local codebase during analysis
  --verbose             Stream Claude output to terminal
```

### Typical workflow

```bash
# 1. Discover relevant projects
gleaner design-docs/my-spec.md

# 2. Review and edit the candidate list
vim gleanings/reference-projects.md

# 3. Run deep analysis + synthesis
gleaner --continue design-docs/my-spec.md
```

### Skip discovery with known repos

```bash
gleaner design-docs/my-spec.md \
  --repos https://github.com/m-bain/whisperx https://github.com/WyattBlue/auto-editor
```

## Output

```
gleanings/
  reference-projects.md    # Discovery index (human-editable)
  synthesis.md             # Cross-repo spec enhancements
  analysis-whisperx.md     # Per-repo deep analysis
  analysis-auto-editor.md
  ...
```

## How it works

1. **Spec ingestion** — Creates a base Claude session that reads your spec
2. **Discovery** — Forks from base, searches GitHub/web for related projects
3. **Human checkpoint** — You review and edit the candidate list
4. **Parallel deep-dives** — For each repo: initial analysis, deeper analysis, structural inversion, then iterative critique until convergence
5. **Synthesis** — Cross-cutting insights distilled into spec enhancements

All sessions fork from the base, sharing cached spec context for efficiency.

## Crash recovery

Gleaner persists pipeline state to `.gleaner-state.json`. If interrupted, `--continue` resumes from where it left off — completed repos are skipped, in-progress repos resume at their current step.

## Credits

Gleaner was inspired by [Jeff Emanuel](https://github.com/Dicklesworthstone) ([@doodlestein](https://x.com/doodlestein) on X/Twitter). The analysis prompts and the core idea of using iterative AI critique loops to refine specs against real-world open source projects both come from Jeff. His project [automated_plan_reviser_pro](https://github.com/Dicklesworthstone/automated_plan_reviser_pro) pioneered the automated multi-round revision workflow that gleaner builds on.

## License

MIT
