import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICreature.sol";

contract ElysianGovernance is Ownable {
    ICreature public immutable creature;
    
    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        bytes callData;
        address target;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        bool canceled;
        bytes32 thoughtId;
        mapping(address => bool) hasVoted;
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public isTopHolder;
    
    uint256 public proposalCount;
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant EXECUTION_DELAY = 2 days
    uint256 public constant TOP_HOLDER_COUNT = 100;
    uint256 public constant PROPOSAL_THRESHOLD = 100000e18; // 100,000 tokens
    
    event ProposalCreated(
        uint256 indexed id,
        address proposer,
        address target,
        string description
    );
    event VoteCast(
        uint256 indexed id,
        address indexed voter,
        bool support,
        uint256 votes
    );
    event ProposalExecuted(uint256 indexed id);
    event TopHoldersUpdated(uint256 timestamp);
    
    constructor(address _creature) {
        creature = ICreature(_creature);
    }
    
    function propose(
        address target,
        bytes calldata data,
        string calldata description
    ) external returns (uint256) {
        require(isTopHolder[msg.sender], "Not top holder");
        
        // Get quantum analysis from Creature
        ICreature.ThoughtResult memory thought = creature.generateThought(
            abi.encode(target, data, description)
        );
        
        proposalCount++;
        Proposal storage proposal = proposals[proposalCount];
        proposal.id = proposalCount;
        proposal.proposer = msg.sender;
        proposal.description = description;
        proposal.target = target;
        proposal.callData = data;
        proposal.startTime = block.timestamp;
        proposal.endTime = block.timestamp + VOTING_PERIOD;
        proposal.thoughtId = thought.id;
        
        emit ProposalCreated(
            proposalCount,
            msg.sender,
            target,
            description
        );
        
        return proposalCount;
    }
    
    function castVote(
        uint256 proposalId,
        bool support
    ) external {
        require(isTopHolder[msg.sender], "Not top holder");
        
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp <= proposal.endTime, "Voting ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");
        
        // Get dimensional analysis for vote weight
        ICreature.DimensionalScores memory scores = 
            creature.getDimensionalScores();
            
        uint256 voteWeight = calculateVoteWeight(msg.sender, scores);
        
        if(support) {
            proposal.forVotes += voteWeight;
        } else {
            proposal.againstVotes += voteWeight;
        }
        
        proposal.hasVoted[msg.sender] = true;
        
        emit VoteCast(proposalId, msg.sender, support, voteWeight);
    }
    
    function executeProposal(uint256 proposalId) external {
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp > proposal.endTime + EXECUTION_DELAY,
            "Time lock active"
        );
        require(!proposal.executed, "Already executed");
        require(!proposal.canceled, "Proposal canceled");
        require(
            proposal.forVotes > proposal.againstVotes,
            "Vote not passed"
        );
        
        // Final thought analysis before execution
        ICreature.ThoughtResult memory thought = creature.generateThought(
            abi.encode("execute", proposalId)
        );
        require(thought.confidence >= 75, "Low execution confidence");
        
        proposal.executed = true;
        
        (bool success, ) = proposal.target.call(proposal.callData);
        require(success, "Execution failed");
        
        emit ProposalExecuted(proposalId);
    }
    
    function updateTopHolders(address[] calldata holders) external onlyOwner {
        require(holders.length == TOP_HOLDER_COUNT, "Invalid length");
        
        // Reset old holders
        for(uint i = 0; i < TOP_HOLDER_COUNT; i++) {
            if(isTopHolder[holders[i]]) {
                isTopHolder[holders[i]] = false;
            }
        }
        
        // Set new holders
        for(uint i = 0; i < holders.length; i++) {
            isTopHolder[holders[i]] = true;
        }
        
        emit TopHoldersUpdated(block.timestamp);
    }
    
    function calculateVoteWeight(
        address voter,
        ICreature.DimensionalScores memory scores
    ) internal view returns (uint256) {
        // Base weight from token balance
        uint256 weight = IERC20(token).balanceOf(voter);
        
        // Adjust based on dimensional scores
        uint256 modifier = 100;
        
        // Higher coherence increases vote weight
        if(scores.coherence > 50) {
            modifier += uint256(scores.coherence - 50);
        }
        
        // Higher intelligence increases vote weight
        if(scores.intelligence > 50) {
            modifier += uint256(scores.intelligence - 50);
        }
        
        return weight * modifier / 100;
    }
    
    receive() external payable {}
}