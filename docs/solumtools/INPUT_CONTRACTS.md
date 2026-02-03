INPUT_CONTRACTS — SolumTools (Canonical)

Purpose
-------
This document defines the canonical INPUT CONTRACTS for SolumTools.
An input contract specifies what data can be provided to the system,
in what structure, with what guarantees, and with what constraints.

Inputs are treated as *requests for interpretation*, never as commands
to mutate state directly.

Core Principles
---------------
1. Inputs never imply state changes by themselves.
2. All inputs must be explicit, bounded, and self-describing.
3. No hidden defaults, no inferred parameters.
4. Inputs are validated BEFORE any processing or simulation.
5. Invalid inputs are rejected, never corrected.

General Input Envelope
----------------------
All inputs follow this envelope:

{
  "type": "<INPUT_TYPE>",
  "version": "<SEMVER>",
  "payload": { ... }
}

- type: declares intent (not action)
- version: schema version
- payload: data strictly defined per type

Canonical Input Types
---------------------

1. MAP_QUERY
------------
Purpose:
Request information about a spatial area of Solum.

Payload:
{
  "zoom_level": <int>,
  "coordinates": {
    "x": <int>,
    "y": <int>
  },
  "radius": <int>
}

Constraints:
- zoom_level must be valid per ZOOM_RULES
- radius must be >= 0
- coordinates must be integers

2. WALLET_QUERY
---------------
Purpose:
Request Solum-related data for a wallet.

Payload:
{
  "wallet_address": "<hex-string>",
  "mode": "summary | detailed | historical"
}

Constraints:
- wallet_address must be checksummed or canonical hex
- mode must be one of the allowed literals

3. STATE_SNAPSHOT_REQUEST
-------------------------
Purpose:
Request the state of the system at a given moment.

Payload:
{
  "timestamp": <unix_timestamp>,
  "scope": "local | global"
}

Constraints:
- timestamp must be <= current time
- scope defines resolution, not permissions

4. EVOLUTION_QUERY
------------------
Purpose:
Request evolution data between two moments.

Payload:
{
  "from": <unix_timestamp>,
  "to": <unix_timestamp>,
  "zoom_level": <int>
}

Constraints:
- from < to
- range must be bounded by system limits

Validation Rules
----------------
- Unknown input types are rejected.
- Missing fields are rejected.
- Extra fields are rejected.
- Type mismatches are rejected.

Versioning
----------
Input contracts are immutable once published.
New behavior requires a new version identifier.

AI Consumption Notes
--------------------
- Inputs are not suggestions.
- Inputs are not prompts.
- Inputs are formal contracts.
- AI must never invent missing fields.

End of file.
