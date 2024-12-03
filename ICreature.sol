// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ICreature {
    struct DimensionalScores {
        int256 emergence;
        int256 coherence;
        int256 resilience;
        int256 intelligence;
        int256 efficiency;
        int256 integration;
    }

    struct StrategyAnalysis {
        uint256 riskScore;
        uint256 expectedReturn;
        bool isValid;
        bytes32 thoughtId;
    }

    struct ThoughtResult {
        bytes32 id;
        string content;
        uint256 confidence;
        DimensionalScores impact;
    }

    function analyzeStrategy(
        bytes calldata strategyData
    ) external returns (StrategyAnalysis memory);

    function getDimensionalScores() external view returns (DimensionalScores memory);

    function generateThought(
        bytes calldata context
    ) external returns (ThoughtResult memory);
}

interface IElysianDAO {
    struct Strategy {
        bytes32 id;
        address proposer;
        bytes32 thoughtId;
        uint256 riskScore;
        uint256 expectedReturn;
        bool executed;
        bool failed;
    }

    event StrategyProposed(bytes32 indexed id, address indexed proposer);
    event StrategyExecuted(bytes32 indexed id, uint256 returnAmount);
    event ThoughtGenerated(bytes32 indexed id, uint256 confidence);

    function proposeStrategy(bytes calldata strategyData) external returns (bytes32);
    function executeStrategy(bytes32 strategyId) external;
    function getStrategy(bytes32 strategyId) external view returns (Strategy memory);
}
