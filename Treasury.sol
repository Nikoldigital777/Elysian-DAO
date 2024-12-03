// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ICreature.sol";

contract ElysianTreasury is Ownable, ReentrancyGuard {
    ICreature public immutable creature;
    
    struct Investment {
        bytes32 id;
        address token;
        uint256 amount;
        uint256 entryPrice;
        bytes32 thoughtId;
        bool active;
        uint256 profitTarget;
        uint256 stopLoss;
    }
    
    mapping(bytes32 => Investment) public investments;
    mapping(address => bool) public approvedStrategists;
    
    uint256 public totalInvestedValue;
    uint256 public constant MAX_INVESTMENT_PERCENT = 2000; // 20% in basis points
    
    event InvestmentCreated(bytes32 indexed id, address token, uint256 amount);
    event InvestmentExited(bytes32 indexed id, uint256 returnAmount, uint256 profit);
    
    constructor(address _creature) {
        creature = ICreature(_creature);
    }
    
    modifier onlyStrategist() {
        require(approvedStrategists[msg.sender], "Not strategist");
        _;
    }
    
    function executeInvestment(
        string calldata strategyId,
        address token,
        uint256 amount
    ) external nonReentrant onlyStrategist {
        // Validate quantum analysis
        ICreature.StrategyAnalysis memory analysis = 
            creature.analyzeStrategy(abi.encode(strategyId, token, amount));
            
        require(analysis.isValid, "Invalid strategy");
        require(analysis.riskScore <= 75, "Risk too high");
        
        // Check investment size vs treasury
        uint256 treasuryValue = address(this).balance;
        require(
            amount <= treasuryValue * MAX_INVESTMENT_PERCENT / 10000,
            "Investment too large"
        );
        
        bytes32 investmentId = keccak256(abi.encodePacked(
            strategyId,
            block.timestamp,
            token
        ));
        
        investments[investmentId] = Investment({
            id: investmentId,
            token: token,
            amount: amount,
            entryPrice: getCurrentPrice(token),
            thoughtId: analysis.thoughtId,
            active: true,
            profitTarget: analysis.expectedReturn,
            stopLoss: analysis.riskScore
        });
        
        totalInvestedValue += amount;
        
        emit InvestmentCreated(investmentId, token, amount);
    }
    
    function exitInvestment(
        bytes32 investmentId,
        uint256 returnAmount
    ) external nonReentrant onlyStrategist {
        Investment storage investment = investments[investmentId];
        require(investment.active, "Investment not active");
        
        investment.active = false;
        totalInvestedValue -= investment.amount;
        
        uint256 profit = 0;
        if(returnAmount > investment.amount) {
            profit = returnAmount - investment.amount;
        }
        
        // Handle profit distribution
        if(profit > 0) {
            distributeProfit(profit);
        }
        
        emit InvestmentExited(
            investmentId,
            returnAmount,
            profit
        );
    }
    
    function getCurrentPrice(address token) internal view returns (uint256) {
        // Implement price oracle integration
        return 0;
    }
    
    function distributeProfit(uint256 profit) internal {
        // Implement profit distribution logic
    }
}
