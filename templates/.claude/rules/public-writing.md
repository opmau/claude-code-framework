# Public-Facing Writing

Rules for every artifact a stranger can read: source comments, README, docs,
CHANGELOG, commit messages, PR titles and bodies, release notes, issue text.

The failure this prevents is specific. An agent drafts these from its own
session memory, because that is what is salient to it. The result reads as a
narrative of the agent's work — what it discovered, what it tried, what finally
passed — addressed to the person who watched it happen. A reader who did not
watch learns about the agent's process instead of the change.

Knowing the rule does not fix it, because the rule governs what not to write
while the problem is what the text is being written *from*. The mechanisms
below are what fix it.

## The reader

Write for a **technical lead integrating this project** who has never seen the
codebase's internals and was not present for the work. They ask three things:

1. **Does this affect me?**
2. **What do I have to do about it?**
3. **How do I tell whether it worked?**

**Every sentence serves one of those three, or it is cut.** That is a mechanical
test, not a matter of taste — apply it sentence by sentence.

## Tells that the text is session narrative

- **Discovery narrative** — "found while implementing this", "caught by the new
  test", "it turned out that", "mostly masked because". *How* a defect was
  noticed is never the reader's concern.
- **Agent presence** — the writer appearing as an actor in the sentence.
  Note that "previously X, now Y" is correct changelog voice; past tense is not
  the problem, the writer's presence is.
- **Internal metrics as news** — test counts, line counts, coverage numbers,
  file-size limits, "all green", before/after line totals.
- **Internal structure as news** — file splits, module renames, which file
  something now lives in — unless it is part of the public interface.
- **Confessional history** — "for the first time", "never worked", "had always
  been broken". These read as an admission to an insider and alarm everyone else.
- **Session-relative time** — "now", "currently", "at time of writing", "still".
  Artifacts outlive the session.
- **Private data** — see below. This is the one that causes real harm.

## Private data never appears in a public artifact

Applies to source, tests, fixtures, docs, commit messages, PR bodies and release
notes alike — anything a stranger can read.

- Real account, customer or user data of any kind — balances, identifiers,
  quantities, names, addresses, keys, tokens
- Local machine paths, private log or file names, internal hostnames
- Names of private systems, internal projects or non-public tooling
- Internal process detail: ticket workflow, agent/session mechanics

State the **shape** of an effect, not the measured value: "a substantial
increase, depending on configuration" rather than a real figure. Fixtures and
doc examples use illustrative values. Precise real figures belong in the
conversation and the issue tracker, which are private.

## A change that removes private data must not name what it removed

Read every artifact as two people. The **integrator** asks what they must do.
The **attacker** asks what this hands them. Most public text only gets read for
the first, and gets written for neither.

A commit that removes sensitive material is the clearest case. Its diff is
public the moment it is pushed, so a message describing what was taken out is a
signpost: it tells a reader which parent to inspect and what they will find
there. The removal advertises the thing the removal was for.

Say what changed in form and stop:

- "tidy comments"
- "use illustrative fixture values"
- "simplify the changelog entries"

That is a complete message. **It needs no inventory, no example, and no
rationale** — and it is not evasive, because the reader who needs to act on this
change does not need any of that. The same applies to the PR body and, if the
change reaches one, the release note.

## Mechanisms

These are what actually change the output.

1. **Draft from the diff, not from the session.** Write from `git diff` and the
   ticket. If a sentence cannot be traced to a changed line or to behaviour the
   reader can observe, it is commentary — cut it.

2. **Have it reviewed cold.** Hand the `docs-reviewer` agent only the artifact
   text and the diff — never the session transcript. Its value is that it lacks
   the context which makes commentary feel earned. Self-review does not
   substitute; the author has that context and cannot unsee it.

3. **Read it back from where it was published.** After publishing, fetch the
   artifact from its published source and read it. Do not assert that a draft is
   clean — retrieve it and check. Publishing is not the end of the task.

4. **Say what you verified, not that you verified.** "Checked and it's clean" is
   not a result. Show the check.

5. **Default to less.** Most changes need one line. Length is not thoroughness;
   an explanation nobody asked for is usually the author reasoning in public.
