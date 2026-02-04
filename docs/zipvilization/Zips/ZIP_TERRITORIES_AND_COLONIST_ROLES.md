# Zipvilization — Territories and Colonist Roles (Canonical)

This document defines the **territorial hierarchy** in Zipvilization and the
**role assumed by a colonist (wallet)** depending on their consolidated territory.

This file is canonical for:
- Zipvilization logic
- Solumtools observability
- Future SolumWorld interpretation layers

No narrative meaning is implied.
Roles describe **territorial responsibility**, not social hierarchy.

---

## 1. Core Principle

A colonist's role is determined **exclusively** by the highest consolidated
territory they control.

- Territory level is derived from Solum balance.
- Consolidation is automatic.
- Gains and losses are reversible.
- No role is permanent.

---

## 2. Territory → Role Mapping

| Territory | Solum Threshold | Colonist Role |
|---------|----------------|---------------|
| Farm | ≥ 10M | Farmer |
| Village | ≥ 100M | Chief |
| City | ≥ 1,000M | Mayor |
| County | ≥ 10,000M | Sheriff |
| State | ≥ 50,000M | Governor |
| Kingdom | ≥ 250,000M | King |

Notes:
- Thresholds represent **minimum consolidated Solum**.
- Higher territories include all lower ones implicitly.

---

## 3. Automatic Promotion and Demotion

Territorial status is **dynamic**.

### Promotion
When a wallet crosses a threshold:
- Its role upgrades instantly.
- Lower territories are absorbed.

Example:
- 99M → Farm → Farmer
- 100M → Village → Chief

### Demotion
If balance drops below a threshold:
- Role downgrades automatically.
- Territory reverts to the highest valid level.

Example:
- 100M → Village → Chief
- Sell 1M → 99M → Farm → Farmer

No cooldowns.
No grace periods.
No exceptions.

---

## 4. Aggregation Logic (Conceptual)

Territories aggregate lower units internally.

Example:
- A City contains:
  - 10 Villages
  - 100 Farms

The **role reflects only the highest level**, but internal structure is preserved
for population, biology, and future mechanics.

---

## 5. Relationship to Solumtools

Solumtools uses this model to:
- Classify wallets
- Display territory level
- Enable filtering and grouping
- Expose changes over time

Solumtools does NOT:
- Rank players
- Judge behavior
- Add narrative meaning

---

## 6. Relationship to Future Systems

This file enables:
- Zip population simulation
- Territory maturation logic
- Infrastructure progression
- SolumWorld visualization layers

Without this definition, higher-level systems cannot remain deterministic.

---

## 7. Canonical Rules

- Roles are derived, never assigned.
- No manual override exists.
- On-chain balance is the single source of truth.
- Interpretation layers may rename or visualize roles, but **must not alter logic**.

---

END OF FILE
