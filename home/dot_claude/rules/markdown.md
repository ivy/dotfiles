# Markdown

## Line width

One paragraph is one line. Do not insert newlines to wrap prose at 80, 100, or any other column — renderers soft-wrap to the reader's viewport, and a hard-wrapped paragraph renders as a stack of short ragged lines instead. Let the line run as long as the paragraph.

Newlines are content, not formatting. Reach for one only where the break is the point: between paragraphs, between list items, around fenced blocks.

Editing an existing file that is already hard-wrapped is not a licence to reflow it. Rewrap only the paragraphs the change touches, so the diff stays readable.

## Syntax

A reference for getting the syntax right, not a menu to work through. Plain prose, headings, lists, links, and fenced code carry almost every document. The rest earns its place only where it says something plainer markup cannot.

| Need | Syntax |
|------|--------|
| Emphasis | `**bold**`, `_italic_`, `~~strike~~` |
| Inline code | `` `code` `` |
| Heading | `## ATX only` — never `===` underlines |
| Link | `[text](url)`, repo-relative for repo files |
| Anchor | `[text](#heading-name)` — lowercase, hyphens, punctuation dropped |
| Image | `![alt text](url)` — alt text always |
| Task list | `- [ ]` / `- [x]` |
| Footnote | `text[^1]` … `[^1]: note` |
| Sub/superscript | `<sub>x</sub>`, `<sup>2</sup>` |

Fenced code always names its language, so it highlights:

````markdown
```bash
echo hello
```
````

Alerts render as coloured callouts on GitHub. One per section at most; a document of alerts is a document with no emphasis at all:

```markdown
> [!NOTE]
> neutral aside

> [!TIP]
> optional advice

> [!IMPORTANT]
> needed to succeed

> [!WARNING]
> needed to avoid harm

> [!CAUTION]
> risk of damage
```

Collapse long output — logs, stack traces, generated dumps — behind a summary rather than dropping it inline:

```markdown
<details><summary>Full test output</summary>

...

</details>
```

Tables are for genuinely tabular data. Two columns of prose is a list.
