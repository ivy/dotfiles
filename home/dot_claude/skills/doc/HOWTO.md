# How-to Guides - Goal-Oriented Documentation

How-to guides are **directions** that guide the reader through a problem or towards a result. They are **goal-oriented**.

## Core Purpose

- Help the user **get something done**
- Guide the user's **action** correctly and safely
- Serve **work**, not study
- Navigate real-world problem-fields

## Key Distinction

How-to guides are written from the **user's perspective**, not the machinery's.

**Bad (machinery-focused):**
> "To deploy the desired database configuration, select the appropriate options and press Deploy."

**Good (user-focused):**
> "To handle traffic spikes during product launches, configure auto-scaling with a minimum of 3 replicas."

The bad example describes what buttons do. The good example addresses a real human need.

## What How-to Guides Address

| Good Scope | Bad Scope |
|------------|-----------|
| How to calibrate the radar array | How to use the radar system |
| How to configure reconnection back-off policies | How to build a web application |
| Specific, bounded problems | Vast, open-ended spheres |

## Key Principles

### 1. Address Real-World Problems

Every how-to guide answers a human project. Define the problem from the user's perspective.

### 2. Assume Competence

The user knows what they want to achieve. They can follow instructions correctly. Don't teach.

### 3. Maintain Goal Focus

Action and only action. No digression, explanation, or teaching.

**Temptation:** Add explanation for completeness.
**Reality:** Link to explanation instead.

### 4. Address Real-World Complexity

Guides must be **adaptable** to various use-cases. Show how to adjust for different situations.

### 5. Omit the Unnecessary

Practical usability > completeness. Start and end at reasonable, meaningful places.

### 6. Provide Executable Solutions

A contract: if you're facing this situation, these steps will work.

### 7. Describe Logical Sequences

Steps have meaning in their order. Consider:
- Technical dependencies (step 2 requires step 1)
- Cognitive flow (earlier steps set up thinking for later steps)

### 8. Seek Flow

Ground sequences in user activities and thinking. Ask:
- What context switches are required?
- How long must the user hold thoughts before resolution?
- Are there unnecessary jumps back to earlier concerns?

Great how-to guides **anticipate** the user - like a helper who has the tool ready before you reach for it.

## How-to Guide Characteristics

| Aspect | How-to Approach |
|--------|-----------------|
| Environment | Real world |
| Path | Forks and branches |
| Responsibility | User bears risk |
| Competence assumed | Full |
| Scope | General, adaptable |
| Skills | Assumed, applied |
| Unexpected | Prepared for, addressed |

## Language Patterns

| Pattern | Example |
|---------|---------|
| State the goal | "This guide shows you how to..." |
| Conditional imperatives | "If you want x, do y. To achieve w, do z." |
| Reference links | "Refer to the x reference guide for options." |

## What How-to Guides Are NOT

- **Not tutorials** - those serve study, not work
- **Not procedural guides only** - problems aren't always linear
- **Not reference** - reference describes, how-to guides direct
- **Not explanation** - no "why" discussions

## How-to vs Tutorial Comparison

| Aspect | How-to Guide | Tutorial |
|--------|--------------|----------|
| Purpose | Accomplish a task | Acquire competence |
| User mode | Work | Study |
| Path | Real-world, branching | Managed, single |
| Assumptions | User is competent | User knows nothing |
| Environment | Real | Contrived |
| Safety | Cannot promise | Guaranteed |
| Responsibility | User | Teacher |
| Questions | User asks the right ones | User may not know what to ask |
| Knowledge | Implicit, assumed | Explicit, taught |

## Naming Conventions

**Good titles say exactly what the guide shows:**

| Quality | Example |
|---------|---------|
| Good | "How to integrate application performance monitoring" |
| Bad | "Integrating application performance monitoring" |
| Very bad | "Application performance monitoring" |

The best titles can't be mistaken for anything else. Search engines appreciate this too.

## Structure Patterns

How-to guides often need to handle multiple paths:

```markdown
## Prerequisites
Brief list of what's needed before starting.

## Steps

### 1. First action
Do this thing.

### 2. Second action
If condition A, do this.
If condition B, do that instead.

### 3. Third action
Check that the result matches expectations.

## Troubleshooting
Common issues and their solutions.
```

## The Recipe Analogy

A recipe is an excellent model for a how-to guide:
- Clearly defines what will be achieved
- Addresses a specific question ("How do I make...?")
- Doesn't teach (a professional chef still follows recipes)
- Requires basic competence
- Follows a well-established format
- Excludes teaching and discussion
- Focuses only on **how**

## Testing Your How-to Guide

- Does it address a real user problem?
- Is the goal clearly stated upfront?
- Can a competent user follow it to success?
- Is explanation minimal (linked, not inline)?
- Does it handle real-world variations?
- Does it have flow (smooth progress)?
- Is the title unambiguous?
