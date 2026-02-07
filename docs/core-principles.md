# Core Principles

Decision filters for this project. Every principle has teeth — it should be possible to violate it, and doing so should feel wrong.

## 1. Agent-First

Tools and configurations are chosen based on how well agents can manage them, not how pleasant they are for humans to configure by hand.

A tool that's great for humans but opaque to agents is worse than a simpler tool agents can fully control. If a plugin manager doesn't have a lockfile, if a config format can't be parsed programmatically, if a tool can only be configured through an interactive TUI — that's a liability.

**Says no to**: Tools that require interactive setup, plugin managers without lockfiles, configuration that depends on tribal knowledge.

## 2. Observable

Agents verify their work from the user's perspective — launching the actual TUI, starting the actual shell, seeing the actual output. File-level correctness is necessary but not sufficient.

An agent that edits a zsh config and calls it done hasn't verified anything. An agent that edits the config, opens a PTY, and confirms zsh starts without errors has actually done the job.

**Says no to**: "The config file looks right so it works." Testing only at the file level. Skipping validation because the tool is hard to run programmatically.

**See**: [#130 — Run a PTY to test changes from the user's perspective](https://github.com/ivy/dotfiles/issues/130)

## 3. Pinned Supply Chain

Every dependency has a version pin. Every update flows through Renovate. If a tool can't be pinned and auto-updated, it's a liability worth eliminating.

The goal is reproducibility and automated maintenance. Bespoke update mechanisms that only work via their own CLI are a tax on agent autonomy. The closer everything gets to "Renovate opens a PR, agent validates it, done" the better.

**Says no to**: `latest` tags, unversioned plugin installs, tools that can only update via their own bespoke CLI, dependency management that requires human judgment for routine updates.

## 4. Source Truth

Agent infrastructure teaches agents *where to look and how to navigate*, not *what to know*.

Agents aren't humans. They can read 10,000 lines of source code in seconds. They should read the actual installed plugin source, the actual checked-out code, the actual bundled docs — not a summary someone wrote three months ago that's already stale. Like Debian's `/usr/share/doc/`: truth lives with the installed artifact.

AGENTS.md, skills, and hooks are **wayfinding tools**. They point agents at primary sources and teach navigation patterns. They don't try to replicate the knowledge that already exists in the code itself.

**Says no to**: Maintaining repo docs that duplicate upstream knowledge. Agents relying on training data for fast-moving tools. Pre-digesting information that agents can find themselves.

## 5. Joy Is a Feature

The environment should be beautiful and make coding fun. Aesthetic isn't vanity — it's motivation. But beauty is a result of good configuration, not a hobby.

The human doesn't spend time ricing. The human says "I want this to look better" and an agent makes it happen. Conversely, "ugly but functional" is also rejected — a joyless environment saps energy even if it technically works.

**Says no to**: Human time spent ricing. Also says no to ugly/default-everything. The balance is: care about aesthetics, but let agents do the work.

## 6. Replace What Doesn't Fit

Off-the-shelf tools built for humans may need to be replaced with agent-manageable alternatives. Don't keep a tool because it's popular — keep it because it works in an agent-first workflow.

This isn't about replacing everything. tmux works great with agents today. But if a tool's plugin ecosystem requires 40 custom Renovate regex managers and still barely works, maybe the answer isn't more regex — maybe it's a different approach entirely. Be willing to vibe-code a replacement when the off-the-shelf option actively fights agent management.

**Says no to**: Keeping a tool out of inertia. Maintaining complex shims to force-fit human tools into agent workflows. But also: replacing things that aren't actually broken.
