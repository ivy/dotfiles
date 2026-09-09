# The paper test

The smallest thing that validates a domain model, before a schema exists. One
hour, no database, no code that ships.

## The method

1. Name the **central query**: the one question the system exists to answer.
2. Hand-write the most realistic workload you can into a flat file, using the
   **real field names from the domain model**. Not a sketch. The actual names.
3. Write a throwaway script, under about a hundred lines, that computes the
   central query from that file.
4. Run it and check the answer against what you already know is true.

Two things can happen, and both are wins. The model cannot express your
workload, so the model is wrong and you learned it before writing a migration.
Or the central query returns something surprising, and you found a bug for the
price of an hour.

## Naming the central query

| Domain | Central query |
|---|---|
| Task or dependency graph | Which work is ready |
| Permissions | The effective decision for a principal on a resource |
| Billing | The invoice for a period |
| Scheduling | What runs next |
| Ranking, feed, search | The top N |
| Inventory | What can be promised |
| Routing, dispatch | Where this request goes |
| Sync or replication | What changed since a cursor |

If you cannot name one, that is the finding: the project's purpose is not
settled. Go back to the vision before writing another table.

## What it caught in dagger

Dagger's central query is *which work is ready*. The paper test was
`backlog.toml`, dagger's own build expressed in dagger's own domain model, plus
a Python script computing readiness. The whole script was about 140 lines; the
readiness computation inside it was under sixty, and the rest was argument
parsing and a work-order printer.

It found a real bug in about twenty minutes. Readiness was defined as open,
unblocked, and unleased. Under that rule a grouping node — one that only
contains children — was ready the moment it was created, so an agent would have
claimed it and found nothing to do. The fix was one clause added to the rule:
a node with open children is not ready. Cost: one line of a document. Had it
been found after the schema, it would have been a migration, a query change, and
whatever had already been built on the wrong readiness.

Two details worth copying:

- **The subject was the project's own first workload.** Self-hosting the model
  makes the test honest, because you cannot quietly simplify data you actually
  have to build from.
- **The throwaway was not thrown away.** That script became the readiness source
  the build harness imported, and later grew a lint mode. A paper test written
  in the real vocabulary tends to survive.

## When the backlog is the paper test

If the project's domain is work, dependencies, or workflow, its own backlog is
the natural subject and steps 6 and 9 collapse into one artifact. Write the
backlog in your own model, compute your own central query over it, and you have
validated the model and planned the build in a single pass.

For every other domain the subject is whatever real data you can hand-write:
three tenants and their permissions, one month of usage, a week of orders. Keep
it small enough to check by eye and real enough to embarrass the model.

## Failure modes

- **Sketching instead of using the real names.** The point is to find out that a
  field is missing. Placeholder names hide exactly that.
- **Choosing convenient data.** Pick the workload you are most worried about.
- **Skipping it because the model is obvious.** Dagger's was obvious, had been
  discussed for hours, and was still wrong.
- **Letting the script grow.** Past a hundred lines you are building the system,
  not testing the model.
