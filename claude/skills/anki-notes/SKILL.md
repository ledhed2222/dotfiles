---
name: anki-notes
description: Turn something just taught into atomic Anki flashcards and add them through AnkiConnect. Use whenever you explain or teach an AI-engineering concept to the user (evals, metrics, LLMs, grounding, extraction, RAG, agents, tooling), whenever they say "add this to anki", "make a card", "flashcard this", and at the end of each step of a walkthrough or tutorial. Default deck is "AI Engineering".
---

# Anki notes

Turn what was just taught into cards the user can actually study, then add them.

## What earns a card

- **General AI-engineering knowledge** that carries over to other projects: concepts, metrics, failure modes, eval techniques, design tradeoffs, tool data models.
- **Not** project-specific names: internal module names, ticket numbers, client names, corpus or collection names. If a project taught a general lesson, write the card about the lesson and leave the project out.
- Skip anything the deck already holds (step 2 checks).

## The rule that matters: one fact per card

A card is studyable only if its back can be recalled **exactly**: one word, a number, or a short clause. The user has rejected cards for being "too broad/vague". So:

- **Split** compound ideas. "Synthetic vs real data" becomes "main advantage of synthetic?", "main weakness of synthetic?", "one job only real data can do?"
- **Prefer scenarios to definitions.** Not "What is a false gold label?" but "An answer key lists a fact that isn't in the input. Which metric drops for every system?" → **Recall.**
- Use **Cloze** for definitions, formulas and three-part structures: `CER = character {{c1::edit distance}} ÷ {{c2::reference length}}`.
- No back longer than one sentence. Context goes in an optional `Why/Example` line, never in the answer itself.

Bad → good:

| bad | good |
|---|---|
| Q: What is pooled recall? A: A label-free technique where the union of systems' outputs… (3 sentences) | Q: In pooled recall, what serves as the pseudo answer key? A: **The union of all systems' outputs.** |
| Q: Grounding vs attribution? A: paragraph | Cloze: Grounding is a {{c1::noun}}; attribution is a {{c2::verb}}. |

## Steps

1. **Draft** the cards against the rules above.
2. **Check the deck** for overlap. Use `deckNames` to get the exact deck name (case matters: `AI Engineering`), then `findNotes` + `notesInfo` on `deck:"<deck>"`, and drop drafts that repeat an existing card.
3. **Write** a JSON file to the scratchpad: a list of `{"model", "deck", "fields", "tags"}`.
   - `Basic`: `{"Front": ..., "Back": ...}`. Bold the key term with `<b>`. An optional context line goes at the end of Back: `<br><br><small><b>Why/Example:</b> one sentence</small>`.
   - `Cloze`: `{"Text": ..., "Extra": ""}`.
   - Tags: `aie::<area>::<topic>` (e.g. `aie::evals::metrics`, `aie::llm::grounding`), `type::definition|contrast|application|formula|calculation`, and a `src::<where-it-came-from>` tag so a batch can be found or deleted together.
4. **Add** them: `python3 -I <this skill dir>/scripts/add_notes.py <file>`. The script checks the deck exists, skips duplicates and reports counts.
5. **Report** in one line: how many were added, and their fronts in short form. Don't paste the whole card list unless asked.

If the user is mid-walkthrough, add cards without asking first; they asked for this standing behavior. If AnkiConnect is unreachable, say so in one line and keep teaching. Don't block the lesson on it.
