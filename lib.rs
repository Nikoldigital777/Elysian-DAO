#![cfg_attr(not(feature = "export-abi"), no_main)]
extern crate alloc;

use stylus_sdk::{
    prelude::*,
    storage::{StorageVec, StorageMap},
    alloy_primitives::{Address, U256, I256, B256},
    msg,
    evm,
};

use alloy_sol_types::{sol, SolError};
mod creature;
mod bridge;

use creature::{Cell, Colony, QuantumState};

// Define core events 
sol! {
    event ThoughtGenerated(bytes32 indexed id, uint256 confidence);
    event StrategyAnalyzed(bytes32 indexed id, uint256 riskScore);
    event DimensionalScores(
        int256 emergence,
        int256 coherence,
        int256 resilience,
        int256 intelligence,
        int256 efficiency,
        int256 integration
    );
    
    error InvalidStrategy();
    error RiskTooHigh();
    error LowConfidence();
}

#[derive(SolidityError)]
pub enum CreatureError {
    InvalidStrategy(InvalidStrategy),
    RiskTooHigh(RiskTooHigh),
    LowConfidence(LowConfidence)
}

// Core storage
#[storage]
#[entrypoint]
pub struct Creature {
    colony: Colony,
    quantum_state: QuantumState,
    dimensional_scores: DimensionalScores,
    strategies: StorageMap<B256, Strategy>
}

#[derive(Storage)]
pub struct Strategy {
    risk_score: StorageU256,
    expected_return: StorageU256,
    thought_id: StorageB256,
    is_valid: StorageBool
}

#[derive(Storage)]
pub struct DimensionalScores {
    emergence: StorageI256,
    coherence: StorageI256,
    resilience: StorageI256,
    intelligence: StorageI256,
    efficiency: StorageI256,
    integration: StorageI256
}

// External interface
#[external]
impl Creature {
    #[payable]
    pub fn analyze_strategy(
        &mut self,
        strategy_data: Vec<u8>
    ) -> Result<StrategyAnalysis, CreatureError> {
        // Generate quantum analysis
        let quantum_analysis = self.quantum_state.analyze(&strategy_data)?;
        
        // Generate thought
        let thought = self.colony.generate_thought(
            &strategy_data,
            &quantum_analysis
        )?;

        // Create strategy
        let strategy_id = self.create_strategy(&thought, quantum_analysis)?;

        // Emit event
        evm::log(StrategyAnalyzed {
            id: strategy_id,
            risk_score: quantum_analysis.risk_score
        });

        Ok(StrategyAnalysis {
            risk_score: quantum_analysis.risk_score,
            expected_return: quantum_analysis.expected_return,
            is_valid: true,
            thought_id: thought.id
        })
    }

    #[view]
    pub fn get_dimensional_scores(&self) -> DimensionalScores {
        self.dimensional_scores.get()
    }
}

// Internal implementation
impl Creature {
    fn create_strategy(
        &mut self,
        thought: &Thought,
        analysis: QuantumAnalysis
    ) -> Result<B256, CreatureError> {
        let strategy_id = B256::random(); // Use proper ID generation
        
        let strategy = Strategy {
            risk_score: StorageU256::new(analysis.risk_score),
            expected_return: StorageU256::new(analysis.expected_return),
            thought_id: StorageB256::new(thought.id),
            is_valid: StorageBool::new(true)
        };
        
        self.strategies.insert(strategy_id, strategy);
        
        Ok(strategy_id)
    }
}
