# Zipvilization — Territory Hierarchy & Population Capacity

## 0) Purpose

This document defines the **canonical relationship** between:

- Solum balances
- Territorial units
- Maximum Zip population capacity

It establishes that **population is derived from territory**,
not directly from token quantity.

If Solum does not form a valid territorial unit,
it does not generate population.

---

## 1) Minimum Unit of Territory

The **minimum unit of representation** is the **Farm**.

| Unit | Solum Required |
|----|---------------|
| Farm | 10 million Solum |

- Balances below **10M Solum** do **not** generate territory
- They do **not** generate Zips
- They are tracked but **discarded** for population purposes

---

## 2) Territory Hierarchy

Territories scale by **aggregation**, not by linear size.

| Territory | Solum Required | Composition |
|--------|---------------|------------|
| Farm | 10M | — |
| Village | 100M | 10 Farms |
| City | 1,000M | 10 Villages |
| County | 10,000M | 10 Cities |
| State | 50,000M | 5 Counties |
| Kingdom | 250,000M | 5 States |

⚠️ Notes:
- Scaling is **1×10** until City → County
- From County upward scaling is **1×5**
- Kingdoms may never exist in practice

---

## 3) Acquisition Rules

- Farms, Villages, Cities, and Counties can be acquired directly
- States and Kingdoms require **aggregation via transfers**
- Aggregation implies paying transaction taxes
- High-scale consolidation is intentionally frictional

---

## 4) Territory Status Naming

A wallet’s **territory name** is determined by the **highest valid unit** it owns.

Lower units remain aggregated internally.

---

## 5) Population Capacity Rule

> **Zip population capacity is derived from territorial units, not raw Solum.**

There is **no 1:1 ratio** between Solum and Zips.

---

## 6) Population Capacity by Unit

| Territory | Max Zips |
|---------|----------|
| Farm | 10 |
| Village | 200 |
| City | 3,000 |
| County | 30,000 |
| State | 150,000 |
| Kingdom | 750,000 |

---

## 7) Residual Aggregation Logic

Residual Solum generates population **only if it completes a valid unit**.

### Example A — 104M Solum
- 100M → 1 Village → 200 Zips
- 4M → discarded
- **Total: 200 Zips**

### Example B — 114M Solum
- 100M → 1 Village → 200 Zips
- 10M → 1 Farm → 10 Zips
- 4M → discarded
- **Total: 210 Zips**

---

## 8) Multi-Level Example

### Example C — 1,114M Solum

Territory status: **City**

Breakdown:
- 1 City → 3,000 Zips
- Residual 114M:
  - 1 Village → 200 Zips
  - 1 Farm → 10 Zips
  - 4M → discarded

**Total capacity: 3,210 Zips**

---

## 9) Loss of Territory Status

Territory status is **dynamic**.

If a wallet drops below a threshold:
- The higher unit is lost
- Population capacity recalculates instantly

No grace period exists.

---

## 10) Canonical Implications

- Population growth is **step-based**
- Small holders remain meaningful
- Large holders face consolidation friction
- All visual layers must respect this model

---

## 11) Final Rule

If Solum does not form a valid territorial unit,
it **does not exist** for population.

Territory comes first.
Population follows.

END OF DOCUMENT
