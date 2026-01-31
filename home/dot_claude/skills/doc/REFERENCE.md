# Reference - Information-Oriented Documentation

Reference guides are **technical descriptions** of the machinery and how to operate it. Reference material is **information-oriented**.

## Core Purpose

- **Describe** the machinery succinctly and orderly
- Provide **truth and certainty** for users at work
- Serve as a **map** of the product's territory
- Enable users to work with **confidence**

## The Nature of Reference

Reference material is **led by the product**, not user needs. It describes:
- APIs, classes, functions
- Configuration options
- Commands and their flags
- Data structures
- Protocols and formats

Users **consult** reference; they don't read it.

## Key Principles

### 1. Describe and Only Describe

**Neutral description** is the imperative. This is hard - natural communication wants to explain, instruct, discuss, opine.

Reference demands:
- Accuracy
- Precision
- Completeness
- Clarity

### 2. Be Austere

Reference should be **uncompromising** in its neutrality, objectivity, and factuality.

**Temptation:** Add instruction or explanation because description seems inadequate.
**Reality:** Link to how-to guides and explanation instead.

### 3. Adopt Standard Patterns

Reference is useful when **consistent**. Place information where users expect it, in familiar formats.

No creativity in vocabulary or style. Consistency trumps cleverness.

### 4. Mirror the Structure of the Machinery

Documentation structure should reflect code structure:
- If a method is in a class in a module, the docs should show the same relationship
- Like a map corresponds to territory

### 5. Provide Examples

Examples illustrate without distracting from description. Usage examples show context succinctly.

## Reference Characteristics

| Aspect | Reference Approach |
|--------|-------------------|
| Style | Austere, uncompromising |
| Tone | Neutral, objective, factual |
| Structure | Mirrors the machinery |
| Content | Facts, not opinions |
| Purpose | Enable correct use |

## Language Patterns

| Pattern | Example |
|---------|---------|
| State facts | "Django's logging inherits Python's defaults. Available as `django.utils.log.DEFAULT_LOGGING`." |
| List options | "Sub-commands are: a, b, c, d, e, f." |
| Provide warnings | "You must use a. You must not apply b unless c. Never d." |

## What Reference Is NOT

- **Not explanation** - no "why" or background
- **Not how-to** - no task guidance
- **Not tutorial** - no learning experience
- **Not marketing** - no opinions or interpretation

## Reference vs Explanation

| Aspect | Reference | Explanation |
|--------|-----------|-------------|
| User mode | Work | Study |
| Purpose | Apply knowledge | Acquire understanding |
| Content | Facts, descriptions | Context, background, "why" |
| Style | Boring, unmemorable | Engaging, illuminating |
| When used | At the keyboard | Away from work |

**Rules of thumb:**
- If it's boring and unmemorable → Reference
- Lists of things, tables of information → Reference
- If you could read it in the bath → Explanation
- "Can you tell me more about X?" → Explanation

## Common Problems

### Explanation Creeping In

Examples are fun to develop. They can tempt you to explain *why* or *what if*.

**Problem:** Reference interrupted by digressions.
**Fix:** Keep examples minimal; link to explanation.

### Missing Structure

**Problem:** Docs don't reflect code architecture.
**Fix:** Reorganize to mirror the product's structure.

### Incomplete Coverage

**Problem:** Gaps in API documentation.
**Fix:** Use code structure as checklist for completeness.

## Structure Patterns

### API Reference

```markdown
## ClassName

Brief description of what this class does.

### Constructor

`ClassName(param1, param2, **kwargs)`

| Parameter | Type | Description |
|-----------|------|-------------|
| param1 | str | What this parameter does |
| param2 | int | What this parameter does |

### Methods

#### method_name(arg)

Description of what the method does.

**Parameters:**
- `arg` (type): Description

**Returns:**
- type: Description

**Example:**
\`\`\`python
result = obj.method_name("value")
\`\`\`
```

### CLI Reference

```markdown
## command-name

Brief description.

### Synopsis

\`\`\`
command-name [OPTIONS] ARGUMENT
\`\`\`

### Options

| Flag | Description |
|------|-------------|
| `-v, --verbose` | Enable verbose output |
| `-o, --output FILE` | Write output to FILE |

### Arguments

- `ARGUMENT`: Description of required argument

### Examples

\`\`\`bash
command-name -v input.txt
\`\`\`
```

### Configuration Reference

```markdown
## Configuration Options

### Section Name

#### option_name

- **Type:** string
- **Default:** "default_value"
- **Required:** No

Description of what this option controls.

**Valid values:**
- `value1`: What this means
- `value2`: What this means
```

## The Food Packet Analogy

Information on food packaging:
- Presented in **standard ways**
- Users **expect** specific information in specific places
- No recipes or marketing mixed in (could be dangerous)
- Often **governed by law** due to importance

The same seriousness applies to all reference documentation.

## Auto-Generated Reference

Some reference (like API docs) can be generated from code. Benefits:
- Stays accurate to code
- Ensures completeness

Limitations:
- May lack context
- Examples may be minimal
- Doesn't replace human-written reference entirely

## Testing Your Reference

- Is it purely descriptive (no instruction or explanation)?
- Does the structure mirror the product structure?
- Are patterns consistent throughout?
- Is it complete (all options, parameters, etc.)?
- Are examples minimal and illustrative?
- Can users find what they need quickly?
- Is the style austere and objective?
