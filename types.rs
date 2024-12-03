use stylus_sdk::{
    prelude::*,
    alloy_primitives::{U256, I256, B256},
};

#[derive(Storage)]
pub struct CreatureConfig {
    pub min_confidence: StorageU256,
    pub max_risk_score: StorageU256,
    pub evolution_threshold: StorageU256,
    pub energy_cost_per_thought: StorageU256
}

#[derive(Storage)]
pub struct CoherenceMetrics {
    pub global_coherence: StorageU256,
    pub local_coherences: StorageArray4<StorageU256>,
    pub stability: StorageU256,
}

#[derive(Storage)]
pub struct RiskMetrics {
    pub risk_score: StorageU256,
    pub expected_return: StorageU256,
    pub volatility: StorageU256,
    pub correlation: StorageU256,
}

pub trait DimensionalState {
    fn is_valid(&self) -> bool;
    fn calculate_impact(&self, other: &Self) -> Result<Self, CreatureError> 
    where
        Self: Sized;
}

impl DimensionalState for DimensionalPosition {
    fn is_valid(&self) -> bool {
        // Validate each dimension is within bounds
        let valid_range = |value: I256| value >= I256::from(-100) && value <= I256::from(100);
        
        valid_range(self.emergence) &&
        valid_range(self.coherence) &&
        valid_range(self.resilience) &&
        valid_range(self.intelligence) &&
        valid_range(self.efficiency) &&
        valid_range(self.integration)
    }

    fn calculate_impact(&self, other: &Self) -> Result<Self, CreatureError> {
        let merge_dimension = |a: I256, b: I256| -> I256 {
            let raw = (a + b) / 2;
            raw.clamp(I256::from(-100), I256::from(100))
        };

        Ok(Self {
            emergence: merge_dimension(self.emergence, other.emergence),
            coherence: merge_dimension(self.coherence, other.coherence),
            resilience: merge_dimension(self.resilience, other.resilience),
            intelligence: merge_dimension(self.intelligence, other.intelligence),
            efficiency: merge_dimension(self.efficiency, other.efficiency),
            integration: merge_dimension(self.integration, other.integration),
        })
    }
}

// Helper functions
pub fn calculate_dimension_update(
    current: I256,
    impact: I256,
    stability: U256
) -> I256 {
    let stability_factor = U256::from(100)
        .checked_div(stability)
        .unwrap_or(U256::from(1));
        
    let impact_scaled = impact
        .checked_mul(I256::try_from(stability_factor).unwrap())
        .unwrap_or(impact)
        .checked_div(I256::from(100))
        .unwrap_or(impact);
        
    let new_value = current
        .checked_add(impact_scaled)
        .unwrap_or(current);
        
    // Clamp between -100 and 100
    if new_value > I256::from(100) {
        I256::from(100)
    } else if new_value < I256::from(-100) {
        I256::from(-100)
    } else {
        new_value
    }
}
