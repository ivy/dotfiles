# The documents

What each one is for, how it fails, and the line from dagger that shows it
working. Written for the person who has to keep them true a year later.

## Vision

**For:** the argument. Why this exists, who it is for, and what success is.

**Contains, always:** a *what this is not* section, written before anyone asks.
It does more work than the rest of the document combined, because every later
scope question is answered by pointing at it.

**Fails when:** it describes features. A vision that lists what you will build
is a backlog with adjectives.

**From dagger:** "Not an orchestrator. Not an agent runtime. Not a workflow
engine. Not a message bus. Not a distributed filesystem." Five lines that
settled a dozen later arguments.

## Principles

**For:** decision filters, so choices are made once rather than relitigated.

**Contains, always:** a **says no to** list under each principle.

**Fails when:** a principle forbids nothing. "We value quality" is decoration.
The test is whether you can name a thing you wanted that the principle refuses.

**From dagger:** "Ready is dumb" says no to budget logic in the store, to a
scheduler in the store, and to any default two reasonable organizations would
want to differ on. It ended three separate scope discussions.

## Domain model

**For:** the vocabulary and the rules. The authority everything else cites.

**Contains, always:** what is stored, what is derived, and what is deliberately
absent, kept visibly separate.

**Fails when:** it is written as a schema. Storage-shaped thinking invents
fields the domain does not have and hides derivations behind columns.

**From dagger:** status stores exactly three values; blocked, ready, and claimed
are derived and never stored. Every migration header cites the section it
implements, which is the document doing its job.

## ADRs

**For:** the reasoning behind choices that are expensive to reverse.

**Contains, always:** the options rejected, and why each lost.

**Fails when:** written after the decision. Then it is documentation, and it
records what you did instead of what you weighed. Write it while arguing.

**From dagger:** seven, covering storage engine, wire contract, artifacts,
policy, protocol alignment, provenance, and stack. The two that paid off most
were the ones nobody would have thought to write down later.

## Architecture

**For:** how the pieces fit, and where the boundaries are.

**Contains, always:** a table of what this system owns and what it does not,
naming who owns the rest.

**Fails when:** it is a diagram with no boundary. Boxes and arrows without a
responsibility split cannot answer a scope question.

**From dagger:** the responsibility table made "no" cheap. Retrieval,
notification, moderation, and supervision are all consumers of one event
stream, and the system works without any of them.

## Roadmap

**For:** honesty about deferral. Milestones defined by what becomes possible,
not by dates.

**Contains, always:** the findings you declined, with the milestone they belong
to. Deferral in writing is a decision; deferral in silence is forgetting.

**Fails when:** it becomes a schedule. Dates invite negotiation about dates
instead of about scope.

**From dagger:** the outside review's whole enterprise-readiness list went to
M4 rather than into an argument, which is why the argument ended.

## Backlog

**For:** work orders an agent or a new hire can execute with no other context.

**Contains, always:** per item — the documents that govern it, concrete
deliverables, verifiable acceptance criteria, and scenarios that become tests.

**Fails when:** items are titles. A thin backlog reads fine and produces
inconsistent work, because every ambiguity gets resolved differently by whoever
picks it up.

**From dagger:** the first backlog was thin and had to be rewritten as real work
orders before it could be delegated. Write it thick the first time.
