SolumWorld — State Transitions (Canonical Spec)

1. Purpose
State Transitions define how SolumWorld moves from one valid state to the next.
If the State Model defines what the world is, State Transitions define how the world changes.
No other mechanism may alter the world.

2. Formal Definition
A state transition is a pure function:
State(n+1) = Transition(State(n), Inputs(n))
Rules:
- One input state
- One output state
- No side effects
- No mutation of the input state

3. Determinism
Transitions MUST be deterministic.
Given the same input state, inputs and ruleset, the resulting state MUST be identical.
Non-deterministic behavior is forbidden.

4. Inputs to a Transition
A transition may depend on:
- Time step (tick)
- Solum ownership changes
- Player / colonist actions
- Environmental rules
- Governance constraints
Inputs must be explicit and serializable.
Hidden inputs are forbidden.

5. Transition Categories
5.1 Passive Transitions
Occur automatically:
- Resource production
- Resource decay
- Population growth or decline

5.2 Active Transitions
Triggered by actors:
- Construction
- Transfers
- Assignments

5.3 System Transitions
Applied by the engine:
- Rebalancing
- Constraint enforcement
- Cleanup of invalid entities

6. Order of Execution
1. Validation of input state
2. Passive transitions
3. Active transitions
4. System transitions
5. Validation of output state
If any step fails, the transition aborts.

7. Atomicity
All transitions are atomic.
Either the entire transition succeeds or the state remains unchanged.
Partial transitions are not allowed.

8. Conservation Laws
Transitions must respect conservation rules:
- Resources cannot appear or disappear unless explicitly allowed
- Population cannot go negative
- Solum ownership must remain consistent

9. Time Model
Transitions operate on discrete time steps.
Rules:
- One transition per tick
- No skipping ticks
- No overlapping transitions
Time is a first-class input.

10. Transition Outputs
The output state must be fully valid, self-consistent and pass full state validation.
Invalid outputs must never be published.

11. Replayability
Transitions must support replay.
Applying transitions sequentially must reconstruct history.
Replay divergence indicates a broken implementation.

12. Failure Handling
If a transition fails:
- The failure must be explicit
- The reason must be traceable
- The state must remain unchanged
Silent failure is forbidden.

13. Canonical Rule
If two implementations produce different states from the same inputs,
at least one of them is wrong.
SolumWorld transitions are law.
