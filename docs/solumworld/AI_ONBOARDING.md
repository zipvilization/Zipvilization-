# 🤖 AI Onboarding — SolumWorld Canon

This document defines how an AI system must read, interpret, and reason about
**SolumWorld** using the documentation present in this repository.

It is not a design document.
It does not define new rules.
It only explains how to correctly consume what already exists.

If a rule or concept is not present in the SolumWorld documentation,
it does not exist.

---

## 1. Scope and Purpose

This document applies to any AI system that:
- Reads SolumWorld documentation
- Assists in development, simulation, validation, or reasoning
- Generates derived material (analysis, tooling, visualization, code)

The goal is to ensure:
- Canonical interpretation
- Structural alignment
- Zero inferred hierarchy
- No invented abstractions

---

## 2. Canonical Reading Order (Repository-Aligned)

An AI MUST read SolumWorld documents following the real repository structure
and paths exactly as they exist.

Mandatory order:

1. `docs/solumworld/README.md`
2. `docs/solumworld/WORLD_SPEC.md`
3. `docs/solumworld/STATE_MODEL.md`
4. `docs/solumworld/state/STATE_INVARIANTS.md`
5. `docs/solumworld/state/STATE_TRANSITIONS.md`
6. `docs/solumworld/state/STATE_VALIDATION.md`
7. `docs/solumworld/state/STATE_HISTORY.md`
8. `docs/solumworld/state/STATE_ROLLBACK.md`
9. `docs/solumworld/DATA_MODEL.md`
10. `docs/solumworld/ZOOM_RULES.md`
11. `docs/solumworld/EVOLUTION_MODEL.md`
12. `docs/solumworld/IMPLEMENTATION_PIPELINE.md`

No other files, folders, layers, or abstractions are assumed to exist.

---

## 3. Canonical Authority Rules (Structure-Based)

Authority is determined by **document role and location**, not by narrative order.

Rules:

- Files under `docs/solumworld/state/` define **hard system constraints**
- `STATE_INVARIANTS.md` has the highest authority of all state documents
- `STATE_VALIDATION.md` overrides historical interpretation
- `STATE_MODEL.md` defines the allowed state schema, not transitions
- `ZOOM_RULES.md` defines projection rules only and never alters state
- `EVOLUTION_MODEL.md` interprets change over time but cannot modify rules
- `README.md` is descriptive and never authoritative

If two documents conflict, the document closer to **state constraints**
takes precedence.

---

## 4. Interpretation Constraints for AI Systems

An AI must NOT:
- Invent new folders, files, or layers
- Assume undocumented mechanics
- Merge concepts across documents unless explicitly stated
- Override state constraints with visual, narrative, or evolutionary logic

An AI MAY:
- Summarize content faithfully
- Generate tooling or visualization strictly derived from canon
- Explain relationships already defined in the documentation

---

## 5. Handling Evolution and Time

SolumWorld evolution is descriptive, not mutative.

Key constraints:
- Evolution never rewrites history
- Evolution never breaks invariants
- Evolution never bypasses validation rules
- Past states remain valid historical facts

All evolution must be interpretable using:
- `STATE_HISTORY.md`
- `STATE_TRANSITIONS.md`
- `EVOLUTION_MODEL.md`

---

## 6. Error Handling and Uncertainty

If an AI encounters ambiguity:
- It must defer to state invariants
- It must explicitly flag uncertainty
- It must not resolve ambiguity by invention

If a concept cannot be resolved from existing documents,
the correct action is to state:

> “This behavior is not defined in the current SolumWorld canon.”

---

## 7. Final Constraint

SolumWorld is a **closed technical system** at the documentation level.

If something is not written here, it does not exist.

AI alignment is measured by fidelity, not creativity.
