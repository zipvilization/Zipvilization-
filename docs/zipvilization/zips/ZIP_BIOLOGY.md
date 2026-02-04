# Zip Biology — Canonical Specification

## 0. Scope

This document defines the **biological rules of Zips**.

- It is descriptive, not narrative.
- It does not include gameplay, UI, or economic mechanics.
- It applies equally to all Zips, territories, and future phases.

If a biological rule is not defined here, it does not exist.

---

## 1. What Is a Zip

A Zip is a **non-human lifeform** native to Zipvilization.

Key properties:
- Zips are not mammals.
- Zips do not age or die.
- Zips do not have genders.
- Zips do not reproduce individually.

Zips exist only as part of a **reproductive pair**.

---

## 2. Eggs and Decompression

Zips are born from **eggs** (also referred to as containers).

- An egg requires **3 days** to decompress.
- Upon decompression, two Zips emerge simultaneously.
- Newly decompressed Zips are immediately reproductively mature.

> The term *decompression* is used to avoid anthropomorphic metaphors such as childhood or growth.

---

## 3. Reproductive Pairs

### 3.1 Definition

- A reproductive pair consists of **two Zips**.
- A pair always produces **exactly two eggs per cycle**.
- Eggs always hatch in pairs (twins).

There is no concept of:
- infertility
- mutation
- randomness in offspring count

---

### 3.2 Reproduction Cycle

Once active, a reproductive pair follows this loop:

1. Lay two eggs
2. Eggs decompress after **3 days**
3. New pair becomes active
4. Original pair lays eggs again

This cycle repeats indefinitely.

---

## 4. Territory-Based Latent Pairs

Zips do not exist freely.
They are **bound to territory structure**.

Each territory level contains a fixed number of **latent reproductive pairs**.

Latent pairs:
- exist conceptually at territory creation
- do not reproduce immediately
- activate only when lower territory levels are mature

---

## 5. Latent Reproductive Pairs per Territory

| Territory | Latent Pairs |
|---------|--------------|
| Farm    | 1 |
| Village | 10 |
| City    | 100 |
| County  | 1,000 |
| State   | 5,000 |
| Kingdom | 25,000 |

These values are **structural**, not configurable.

---

## 6. Activation Rules (Hierarchical)

Reproductive pairs activate **hierarchically**.

### 6.1 Farms

- A Farm contains **1 latent pair**
- This pair activates immediately when the Farm is created
- First eggs are laid immediately
- First decompression completes after **3 days**

---

### 6.2 Higher Territories (Village and above)

For any territory above Farm:

- All latent pairs remain inactive at creation
- Activation requires **full maturity of all contained lower territories**
- Once activated, pairs require **+3 days** for first decompression

Example (Village):
- Contains 10 Farms
- Each Farm must reach biological maturity
- Once all Farms are mature:
  - the 10 Village pairs activate simultaneously
  - after +3 days, first Village-level Zips appear

---

## 7. Biological Maturity

A territory is considered **biologically mature** when:

- all its latent reproductive pairs are active
- all resulting Zips have decompressed
- maximum population capacity is reached

Maturity is a prerequisite for:
- activation of higher territory levels
- future progression mechanics (defined in later chapters)

---

## 8. No Death, No Regression

Zips:
- do not die
- do not regress
- are never removed biologically

Population only changes through:
- territory loss (handled elsewhere)
- structural reclassification of territory

Biology itself is irreversible.

---

## 9. Time Units

All biological timing is expressed in **days**.

- 1 decompression cycle = 3 days
- Maturity emerges from multiple cycles

Mapping from days to blockchain blocks:
- is network-dependent
- is intentionally deferred
- will be defined at implementation level

---

## 10. Canonical Constraints

This biological system guarantees:

- deterministic growth
- predictable scaling
- no exponential runaway without territory
- no hidden multipliers

Time and structure are the only growth factors.

---

End of Zip Biology Specification.
