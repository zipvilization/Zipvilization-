STATE_ROLLBACK — SolumWorld / Zipvilization

Purpose
-------
Define how SolumWorld handles invalid states without breaking immutability.

Rollback is not time travel.
Rollback is state selection.

Core Rule
---------
Past states are never modified.
Rollback selects a previous valid state as the new head.

When Rollback Is Allowed
------------------------
Rollback can occur only if:
- A state fails invariant validation
- A transition cannot be deterministically replayed
- Corruption or inconsistency is detected

Rollback Mechanism
------------------
1. Detect invalid state
2. Identify last valid state
3. Set last valid state as active head
4. Discard invalid forward states from canonical view

Important:
- Discarded states remain archived
- They are excluded from canonical history

Rollback Scope
--------------
- Rollback always applies to the entire world state
- Partial rollback is forbidden

Rollback vs Evolution
---------------------
- Evolution is forward-only
- Rollback does not reverse evolution; it rejects invalid futures

Safety Guarantees
-----------------
- No invariant-breaking state can persist
- Canonical history remains linear
- Determinism is preserved

Canonical Status
----------------
Rollback protects SolumWorld integrity.
It is a safeguard, not a gameplay mechanic.
