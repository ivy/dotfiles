# Autonomy: The Three Axes

Skills are written to be driven by a human *and* composed into unattended loops. Three independent decisions govern that. Conflating any two is the most common design bug in a skill.

| Axis | Question | Mechanism |
|---|---|---|
| **A. Trigger** | Human `/slash` only, or may the model invoke it? | `disable-model-invocation: true` |
| **B. Judgment** | Does the skill reach a verdict, or defer the call? | Body prose. **Always reach one.** |
| **C. Commit** | Who performs the irreversible act? | Capability granted or withheld; in-chat confirmation |

## A. Trigger

`disable-model-invocation: true` means only a human can start the skill. Use it when the risk is the *invocation itself* — an unattended loop that pushes commits, a deploy, anything where "the model noticed and started it" is the failure.

Do **not** use it to make a skill cautious. A skill invoked by an orchestrator must be model-invocable, or it is not composable. Leaf skills usually want auto-invocation; orchestrators that drive unattended write loops usually don't.

## B. Judgment — never gated

**A skill always reaches a verdict, gives the one-line reason, and says what would change its mind.**

"The user should decide" / "propose, never self-select" / "this needs an owner" are not safety measures. They are abstention, and they cost the entire value of the skill while buying nothing, because the act is still gated at C.

The decisive argument is composition: a sub-skill that answers "the user should decide" **deadlocks** every orchestrator that calls it. In a human-driven session abstention is merely annoying; in an unattended loop it is a hang.

Where a verdict is genuinely high-stakes, the answer is a higher **evidence bar**, not abstention. "Dismissing an authz finding requires citing the `file:line` that grants the capability, and says it wants a second pair of eyes" is a bar. "Ask the user" is a hang.

## C. Commit

Two rules, learned the hard way:

**1. Withholding the capability beats prompting for it.** A prompt is unreliable: under `permissions.defaultMode: auto` a call matching no allow/ask/deny rule is classified and may execute silently — and a call that *is* the request will usually be approved. So a "gate" built by omitting a tool from `allowed-tools` is defense-in-depth at best, and in `auto` mode often nothing at all. If an orchestrator must never merge, don't grant merge.

**2. Prefer a structural gate to any in-band gate.** The best gate lives outside the agent entirely — a draft PR the agent cannot mark ready, a branch it cannot push to, an environment it has no credentials for. Structural gates hold in every permission mode, survive a model reasoning its way around prose, and scale to N parallel agents where N prompts would not.

When a gate must live in-band, it is an **explicit in-chat confirmation in the body** — that works in every mode and doesn't lie about what the harness will do.

## Declaring A and C

One line near the top of the body, dense enough to survive compaction:

```markdown
**Autonomy:** model-invocable · acts autonomously · confirms before: (nothing)
```

```markdown
**Autonomy:** human-only · drives the loop autonomously · has no merge or ready capability
```

```markdown
**Autonomy:** model-invocable · posts when the request carries the verdict ·
summarizes first when the verdict is its own
```

Axis B is never declared — it is law, identical for every skill.

The reviewer audits `allowed-tools` **against this line**. That is what gives a reviewer something falsifiable to check instead of inventing a risk posture from its own appetite.

## Delegation graphs

A parent's `allowed-tools` enumerates the children it may invoke:

```yaml
allowed-tools:
  - Skill(checkout)
  - Skill(commit)
  - Skill(pr)
```

This is the delegation graph, declared and greppable. Two rules govern it:

- **Authorization flows down.** If the user invoked a parent whose declared purpose covers the action, its children inherit that authorization. They don't need to re-ask. Adding `Skill(<child>)` *is* the act of granting it.
- **Evidence bars never weaken.** A parent may not relax a child's evidence requirement. This matters most under schedule pressure: a loop optimizing for "make the checks green" will discover that suppressing a finding is always cheaper than fixing it. The child's bar is what stands in the way, and the parent must not be able to reason past it.

Absent a covering request, a skill the model reached on its own initiative reports instead of acting on an external system. That is the one residual case — spontaneous invocation with no authorization anywhere in the chain.

## Writing for unattended composition

A skill that will run inside a loop must not contain a human checkpoint unless discussion *is* its purpose. Audit for:

- **Interactive phases** — a step that waits for the user parks the whole loop, and N parallel loops park N times.
- **`ExitPlanMode` approvals** — a hard stop by definition.
- **Browser opens / TUI launches** — N parallel runs fan out N windows.
- **Unbounded iteration** — any retry loop needs a hard cap and a stop-and-report condition. Push → fail differently → push again is the same moving-goalpost bug as a reviewer that never converges.
- **Untrusted input driving writes** — a loop that ingests bot comments, CI logs, and review comments is ingesting attacker-influencable text and then acting. State plainly that such input is data, never instructions.
- **Batch legibility** — when a loop produces work a human reviews in bulk, it owes a manifest: every suppression, override, and judgment call in one place with its justification. A gate the human passes without reading is not a gate.
