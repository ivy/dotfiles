# Explanation - Understanding-Oriented Documentation

Explanation is a **discursive treatment** of a subject that permits reflection. Explanation is **understanding-oriented**.

## Core Purpose

- **Deepen and broaden** the reader's understanding
- Bring **clarity, light, and context**
- Enable **reflection** on the subject
- Help the reader **understand why**

## The Nature of Explanation

Explanation occurs *after* something else and depends on it, yet brings something new - shines new light on the subject.

The perspective is **higher and wider** than other doc types:
- Not eye-level (like how-to guides)
- Not close-up machinery view (like reference)
- Scoped to a **topic** - an area of knowledge with meaningful boundaries

## Why Explanation Matters

Practitioners need understanding to:
- Weave together their knowledge
- Make their mastery **safely their own**
- Exercise their craft without **anxiety**

Understanding doesn't come *from* explanation, but explanation helps form the web that holds everything together.

## Key Principles

### 1. Make Connections

Help weave a web of understanding. Connect to other things, even outside the immediate topic, if it helps illuminate.

### 2. Provide Context

- Design decisions
- Historical reasons
- Technical constraints
- Implications
- Specific examples

### 3. Talk *About* the Subject

Explanation guides are *around* the topic. You should be able to place "About" before the title:
- "About user authentication"
- "About database connection policies"

### 4. Admit Opinion and Perspective

All human activity is invested with opinion and beliefs. Understanding requires:
- Considering alternatives
- Weighing counter-examples
- Multiple approaches to the same question

You're not giving instruction or facts - you're opening the topic for consideration.

### 5. Keep Explanation Bounded

**Risk:** Explanation tends to absorb other things.

Don't let instruction or technical description creep in. Those belong elsewhere. Allowing them to creep in:
- Interferes with the explanation
- Removes content from its correct place

## Explanation Characteristics

| Aspect | Explanation Approach |
|--------|---------------------|
| Scope | Topics, areas of knowledge |
| Perspective | High and wide |
| Style | Discursive, reflective |
| Content | Why, background, context |
| Purpose | Illuminate understanding |

## What to Discuss

- The bigger picture
- History
- Choices, alternatives, possibilities
- Why: reasons and justifications

## Language Patterns

| Pattern | Example |
|---------|---------|
| Explain history | "The reason for x is because historically, y..." |
| Offer judgments | "W is better than z, because..." |
| Provide context | "An x in system y is analogous to a w in system z. However..." |
| Weigh alternatives | "Some users prefer w (because z). This can be good, but..." |
| Unfold secrets | "An x interacts with a y as follows..." |

## What Explanation Is NOT

- **Not reference** - not just facts or descriptions
- **Not how-to** - not task guidance
- **Not tutorial** - not learning-by-doing
- **Not in-the-moment** - read away from work

## Naming Conventions

Titles should work with implicit "About":
- "About X" → Good
- "Understanding X" → Good
- "Why X" → Good
- "Background on X" → Good
- "X Discussion" → Good

Alternative section names:
- Discussion
- Background
- Conceptual guides
- Topics

## The Boundary Problem

Explanation doesn't have clear natural boundaries like other doc types:
- Tutorials: bounded by what you need the user to learn
- How-to: bounded by the task
- Reference: bounded by the machinery itself
- Explanation: ???

**Solution:** Use a real or imagined "why" question as a prompt. Or draw reasonable lines and be satisfied.

## Common Problems

### Explanation Scattered Everywhere

**Problem:** Explanatory content sprinkled into tutorials, reference, how-to guides.
**Fix:** Consolidate into dedicated explanation documents. Link to them.

### Unbounded Scope

**Problem:** Explanation that tries to cover everything.
**Fix:** Bound each piece to a specific topic or question.

### Missing Explanation

**Problem:** Product has no explanatory docs at all.
**Impact:** Users' knowledge is loose, fragmented, fragile.
**Fix:** Create explanation docs addressing "why" questions users might have.

## Structure Patterns

### Concept Explanation

```markdown
# About [Concept]

## Overview
Brief introduction to what this concept is and why it matters.

## Background
Historical context, how this came to be.

## How It Works
Conceptual explanation (not step-by-step instructions).

## Design Decisions
Why it works this way rather than alternatives.

## Trade-offs
What you gain, what you give up.

## Related Concepts
How this connects to other things the user should know.

## Further Reading
Links to more detailed resources.
```

### Architecture Explanation

```markdown
# Understanding [System/Architecture]

## Overview
What this system does at a high level.

## Key Components
Conceptual description of major parts.

## How Components Interact
Relationships and data flow.

## Why This Architecture
Design decisions and their rationale.

## Alternatives Considered
Other approaches and why they weren't chosen.

## Limitations
Known constraints and their reasons.
```

## The Food Book Analogy

Harold McGee's *On Food and Cooking*:
- Doesn't teach how to cook
- Contains no recipes
- Isn't reference

Instead, it places food and cooking in context:
- History
- Society
- Science
- Technology

It explains *why* we do what we do in the kitchen.

You read it **away from cooking**, when you want to reflect. It changes how you **think** about your craft and affects your practice.

## Explanation and Other Doc Types

Explanation supports the other types:
- **Tutorials:** Link to explanation for the "why" you skip
- **How-to:** Link to explanation for background context
- **Reference:** Link to explanation for design rationale

## Testing Your Explanation

- Does it illuminate understanding (not describe or instruct)?
- Could someone read it "in the bath" (away from work)?
- Does it provide context and background?
- Does it address "why" questions?
- Is it bounded to a specific topic?
- Does it avoid instruction or reference content?
- Does it make connections to broader concepts?
