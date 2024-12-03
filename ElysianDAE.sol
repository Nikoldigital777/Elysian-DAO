// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ICreature.sol";
import "./interfaces/IElysianDAO.sol";

contract ElysianDAO is IElysianDAO, Ownable, ReentrancyGuard {
    ICreature public immutable creature;
    
    mapping(bytes32 => Strategy) public strategies;
    mapping(address => bool) public isStrategist;
    
    uint256 public constant MAX_RISK_SCORE = 75;
    uint256 public constant MIN_CONFIDENCE = 70;
    
    constructor(address _creature) {
        creature = ICreature(_creature);
    }
    
    modifier onlyStrategist() {
        require(isStrategist[msg.sender], "Not strategist");
        _;
    }
    
    function proposeStrategy(
        bytes calldata strategyData
    ) external override onlyStrategist returns (bytes32) {
        // Get analysis from Creature
        ICreature.StrategyAnalysis memory analysis = 
            creature.analyzeStrategy(strategyData);
            
        require(analysis.riskScore <= MAX_RISK_SCORE, "Risk too high");
        require(analysis.isValid, "Invalid strategy");
        
        bytes32 strategyId = keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            analysis.thoughtId
        ));
        
        strategies[strategyId] = Strategy({
            id: strategyId,
            proposer: msg.sender,
            thoughtId: analysis.thoughtId,
            riskScore: analysis.riskScore,
            expectedReturn: analysis.expectedReturn,
            executed: false,
            failed: false
        });
        
        emit StrategyProposed(strategyId, msg.sender);
        
        return strategyId;
    }
    
    function executeStrategy(
        bytes32 strategyId
    ) external override nonReentrant onlyStrategist {
        Strategy storage strategy = strategies[strategyId];
        require(!strategy.executed, "Already executed");
        require(!strategy.failed, "Failed strategy");
        
        // Generate thought before execution
        ICreature.ThoughtResult memory thought = 
            creature.generateThought(abi.encode(strategyId));
            
        require(thought.confidence >= MIN_CONFIDENCE, "Low confidence");
        
        // Update dimensional scores
        ICreature.DimensionalScores memory scores = 
            creature.getDimensionalScores();
            
        // Execute strategy logic here...
        
        strategy.executed = true;
        emit StrategyExecuted(strategyId, 0); // Add return amount
    }
    
    function getStrategy(
        bytes32 strategyId
    ) external view override returns (Strategy memory) {
        return strategies[strategyId];
    }
}
