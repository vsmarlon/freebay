# Claude Code guidance

@AGENTS.md

The shared file is the source of truth for architecture, tests, evidence, and commands. Load the relevant skill from `.agents/skills/` before changing code. For frontend edits, run `cd frontend && flutter analyze --fatal-infos lib test libs/freebay_design_system/lib`; resolve warnings, infos, and errors before completion. For test work, also load `.agents/skills/test-audit/SKILL.md`.
