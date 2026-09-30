# Test-audit campaign

Read this before sweeping an entire subsystem's test surface.

1. Define one owner (a backend module, a Flutter feature, or a script/tool area). Enumerate **every** test file it owns, its production entry points, shared test support, and the CI gates that run them. Check root and scoped `AGENTS.md`, relevant history, and dependencies before classifying candidates. Do not infer ownership from filename alone.
2. Make a read-only inventory: for each test, name its observable contract and credible regression, overlaps at stronger boundaries, and any test-only production seam. Use the `SKILL.md` candidate-evidence fields for every proposed deletion. Mark valuable tests to keep, including security, money, concurrency, recovery, and independent package/protocol contracts.
3. Share the evidence and scope before editing. Work in coherent owner-boundary batches; migrate or retain unique regressions, remove confirmed junk and the dead seams it supported, then run focused sibling tests followed by the affected subsystem/CI gates. Never trade away unverified behavior for a larger deletion count.
4. Close the campaign only when every owned test file is accounted for, required gates have passed or are explicitly blocked, and the `SKILL.md` handoff reports what was removed, what remains valuable, LOC by category, and follow-ups.
