---
name: prfaq
description: Interview the user one question at a time about a PRFAQ until shared understanding is reached. Use when the user says "prfaq", "walk through this PRFAQ", or wants to pressure-test a PRFAQ or design doc before implementation.
argument-hint: "<path to PRFAQ document or topic>"
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
model: opus
---

# /prfaq — Interview to shared understanding on a PRFAQ

Interview the user relentlessly about every aspect of a PRFAQ until you reach a shared understanding, walking down each branch of the design tree and resolving dependencies between decisions one-by-one.

## Steps

1. Locate and read the PRFAQ:
   - If `$ARGUMENTS` is a file path, read it
   - If `$ARGUMENTS` is a topic, search `docs/` and the repo root for a matching document
   - If nothing is found, ask the user where the PRFAQ lives (this is the only setup question)

2. Build the design tree: identify every decision the PRFAQ implies — explicit claims, unstated assumptions, dependencies, edge cases, and open questions. Order them so that upstream decisions are resolved before the decisions that depend on them.

3. Before asking anything, look up what the codebase can answer:
   - If a fact can be found by exploring the codebase (existing modules, current behavior, naming, constraints), look it up with Read/Grep/Glob rather than asking
   - Only decisions go to the user — never facts you could verify yourself

4. Interview the user **one question at a time**:
   - Ask a single question, provide your recommended answer with reasoning, then STOP and wait for the user's response
   - NEVER ask multiple questions in one message — it is bewildering
   - Fold each answer into the design tree before choosing the next question; a resolved decision may unlock, reorder, or eliminate downstream questions
   - If an answer contradicts an earlier one or the codebase, surface the conflict and resolve it before moving on

5. Continue until every branch of the design tree is resolved, then present a summary of the shared understanding: each decision, what was chosen, and why.

6. Ask the user to confirm the shared understanding. **Do NOT enact the plan until the user explicitly confirms.** After confirmation, offer next steps (e.g., update the PRFAQ, create Linear issues, or start implementation in a fresh session).

## Arguments

- No arguments: ask the user which PRFAQ or design doc to walk through
- `$ARGUMENTS`: path to the PRFAQ document, or a topic to locate one

## Notes

- One question per message, always with a recommended answer — the recommendation gives the user something concrete to accept or push against
- The decisions are the user's; your job is to surface them, sequence them, and recommend — not to decide
- Facts come from the codebase; decisions come from the user
- This is a planning skill — make NO code changes during the interview
- Long interviews may span context compression; keep the design tree and resolved decisions summarized as you go so nothing is lost
