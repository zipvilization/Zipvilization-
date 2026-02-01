SolumMap — Technical Execution (Developer-Oriented)

This document describes how SolumMap can be implemented as a deterministic,
observational system visualization.

It is written for developers and system designers.
It is not a specification.
It does not define a technology stack or a roadmap.

Its purpose is to demonstrate technical plausibility without introducing
agency, optimization, or gameplay mechanics.

------------------------------------------------------------
0. DESIGN INVARIANTS
------------------------------------------------------------

- Deterministic: identical inputs always produce identical derived states
- Observational: the visualization layer never mutates system state
- Non-interactive: no user controls that enable optimization or strategy
- Non-cinematic: visuals are systemic, stable, and informational

------------------------------------------------------------
1. SYSTEM ROLE
------------------------------------------------------------

SolumMap is a derived visualization layer.

It does not store primary data.
It does not generate economic events.
It does not influence system evolution.

All visual states are computed from:
- Solum balance persistence
- elapsed time
- global treasury state
- deterministic evolution rules

------------------------------------------------------------
2. MINIMAL DATA MODEL
------------------------------------------------------------

type UnixMs = number
type Address = "0x" + string

type WalletSnapshot = {
  address: Address
  solumBalance: bigint
  firstSeenMs: UnixMs
  lastSeenMs: UnixMs
}

type GlobalSnapshot = {
  atMs: UnixMs
  treasuryLevel: number
  totalActiveSolum: bigint
  wallets: WalletSnapshot[]
}

type DerivedCell = {
  x: number
  y: number
  ageBucket: number
  density: number
  tier: SILO | FARM | VILLAGE | TOWN | COUNTY | STATE
  isCore: boolean
}

type DerivedMapState = {
  atMs: UnixMs
  cells: DerivedCell[]
}

------------------------------------------------------------
3. DETERMINISTIC DERIVATION PIPELINE
------------------------------------------------------------

function deriveMapState(snapshot):
    origin = deriveTemporalOrigin(snapshot.wallets)
    projected = projectWallets(snapshot.wallets, origin)
    aggregated = aggregateToGrid(projected, snapshot.treasuryLevel)
    cells = classifyCells(aggregated, snapshot.treasuryLevel, snapshot.atMs)
    return { atMs: snapshot.atMs, cells }

function deriveTemporalOrigin(wallets):
    earliest = wallet with smallest firstSeenMs
    return { anchorFirstSeenMs: earliest.firstSeenMs }

The temporal origin represents system genesis, not a privileged actor.

------------------------------------------------------------
4. TERRITORY AND TIER THRESHOLDS (ILLUSTRATIVE)
------------------------------------------------------------

FARM_MIN = 1_000_000

function tierFromSolum(balance):
    if balance < FARM_MIN:
        return SILO
    return FARM

Higher tiers emerge via deterministic aggregation rules
(FARM → VILLAGE → TOWN → COUNTY → STATE)

------------------------------------------------------------
5. ZOOM AS TEMPORAL ORIENTATION
------------------------------------------------------------

Zoom is not camera proximity.
Zoom is a change in temporal interpretation density.

Zoom levels:
0 | 1 | 2 | 3

function viewForZoom(state, zoom):
    minAge = zoomToMinAgeBucket(zoom)
    filtered = cells where ageBucket >= minAge
    return reaggregateForReadability(filtered, zoom)

function zoomToMinAgeBucket(zoom):
    return [0, 1, 2, 3][zoom]

There is no Zoom 4.
Maximum readable depth emerges from Wallet Mode.

------------------------------------------------------------
6. WALLET MODE (VIEW FILTER)
------------------------------------------------------------

function deriveWalletMode(wallet):
    if wallet.solumBalance < 10_000_000:
        return { maxZoom: 3, densityCap: 1200, focusRadius: 40 }
    if wallet.solumBalance < 1_000_000_000:
        return { maxZoom: 2, densityCap: 900, focusRadius: 70 }
    return { maxZoom: 1, densityCap: 600, focusRadius: 120 }

function walletView(state, wallet):
    cfg = deriveWalletMode(wallet)
    zoomed = viewForZoom(state, cfg.maxZoom)
    centered = centerOnWalletNucleus(zoomed, wallet)
    return capDensity(centered, cfg.densityCap, cfg.focusRadius)

No user-selected zoom or camera control is exposed.

------------------------------------------------------------
7. EVOLUTION VIEW (TEMPORAL COMPRESSION)
------------------------------------------------------------

function buildEvolutionFrames(snapshots, zoom):
    frames = []
    for snapshot in snapshots:
        state = deriveMapState(snapshot)
        frames.push({ atMs: snapshot.atMs, state: viewForZoom(state, zoom) })
    return frames

function playEvolutionView(frames, durationMs):
    step = durationMs / frames.length
    for frame in frames:
        renderFrame(frame)
        wait(step)

Properties:
- non-interactive
- fixed duration
- identical for all observers

------------------------------------------------------------
8. RENDERING CONSTRAINTS
------------------------------------------------------------

- no cinematic lighting
- no gradients or blur
- stable palettes
- non-reactive transitions

Rendering stack intentionally unspecified.

------------------------------------------------------------
9. EXPLICIT NON-GOALS
------------------------------------------------------------

Any implementation introducing the following violates the design:
- strategic optimization
- predictive analytics
- gameplay mechanics
- user-driven control loops
- success-oriented visual emphasis

SolumMap exists to reveal consequences, not enable them.

------------------------------------------------------------
CLOSING NOTE
------------------------------------------------------------

This document demonstrates how SolumMap can be built without becoming
a product specification.

What must remain invariant is not the code,
but the absence of agency and incentive.
