// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * SolumCore (Phase 0 scaffolding)
 *
 * Purpose:
 * - Declare phases and control boundaries
 * - Provide explicit pause/resume controls
 * - Emit events for deterministic state transitions
 *
 * Non-scope:
 * - Tokenomics
 * - Autonomous execution
 * - Governance mechanisms
 */
contract SolumCore {
    enum Phase {
        Genesis,
        Phase1,
        Paused
    }

    enum ControlState {
        Human,
        Hybrid
    }

    Phase public phase;
    ControlState public controlState;

    address public steward;

    event PhaseChanged(Phase indexed previous, Phase indexed current);
    event ControlStateChanged(ControlState indexed previous, ControlState indexed current);
    event StewardChanged(address indexed previous, address indexed current);

    modifier onlySteward() {
        require(msg.sender == steward, "SOLUM: NOT_STEWARD");
        _;
    }

    constructor(address initialSteward) {
        require(initialSteward != address(0), "SOLUM: ZERO_STEWARD");
        steward = initialSteward;

        phase = Phase.Genesis;
        controlState = ControlState.Human;

        emit StewardChanged(address(0), initialSteward);
        emit PhaseChanged(Phase.Genesis, Phase.Genesis);
        emit ControlStateChanged(ControlState.Human, ControlState.Human);
    }

    function setSteward(address newSteward) external onlySteward {
        require(newSteward != address(0), "SOLUM: ZERO_STEWARD");
        address prev = steward;
        steward = newSteward;
        emit StewardChanged(prev, newSteward);
    }

    function setControlState(ControlState next) external onlySteward {
        ControlState prev = controlState;
        controlState = next;
        emit ControlStateChanged(prev, next);
    }

    function setPhase(Phase next) external onlySteward {
        Phase prev = phase;
        phase = next;
        emit PhaseChanged(prev, next);
    }

    function pause() external onlySteward {
        Phase prev = phase;
        phase = Phase.Paused;
        emit PhaseChanged(prev, Phase.Paused);
    }

    function resumeToPhase1() external onlySteward {
        Phase prev = phase;
        phase = Phase.Phase1;
        emit PhaseChanged(prev, Phase.Phase1);
    }
}
