// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/utils/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract VVToken is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("Vega Voting Token", "VV")
        Ownable(initialOwner)
    {}

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}

contract VotingResultNFT is ERC721, Ownable {
    uint256 public nextTokenId;

    struct ResultData {
        bytes32 voteId;
        bool passed;
        uint256 yesVotes;
        uint256 noVotes;
        string description;
    }

    mapping(uint256 => ResultData) public results;

    constructor(address initialOwner)
        ERC721("Vega Voting Result", "VVR")
        Ownable(initialOwner)
    {}

    function mintResult(
        address to,
        bytes32 voteId,
        bool passed,
        uint256 yesVotes,
        uint256 noVotes,
        string memory description
    ) external onlyOwner returns (uint256 tokenId) {
        tokenId = ++nextTokenId;
        _mint(to, tokenId);

        results[tokenId] = ResultData({
            voteId: voteId,
            passed: passed,
            yesVotes: yesVotes,
            noVotes: noVotes,
            description: description
        });
    }
}

contract VegaVoting is Ownable, Pausable, ReentrancyGuard {
    VVToken public immutable vvToken;
    VotingResultNFT public immutable resultNFT;

    uint256 public constant WEEK = 7 days;
    uint256 public constant MIN_LOCK_WEEKS = 1;
    uint256 public constant MAX_LOCK_WEEKS = 4;

    struct StakeInfo {
        uint256 amount;
        uint256 expiry;
        bool withdrawn;
    }

    struct Voting {
        bytes32 id;
        uint256 deadline;
        uint256 votingPowerThreshold;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        bool finalized;
        bool passed;
        uint256 resultNftId;
    }

    mapping(address => StakeInfo[]) public stakes;
    mapping(bytes32 => Voting) public votings;
    mapping(bytes32 => mapping(address => bool)) public hasVoted;
    mapping(bytes32 => bool) public voteExists;

    event Staked(address indexed user, uint256 amount, uint256 lockWeeks, uint256 expiry);
    event Unstaked(address indexed user, uint256 stakeIndex, uint256 amount);

    event VotingCreated(
        bytes32 indexed id,
        uint256 deadline,
        uint256 threshold,
        string description
    );

    event VoteCast(
        bytes32 indexed id,
        address indexed voter,
        bool support,
        uint256 power
    );

    event VotingFinalized(
        bytes32 indexed id,
        bool passed,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 nftId
    );

    constructor(address initialOwner) Ownable(initialOwner) {
        vvToken = new VVToken(address(this));
        resultNFT = new VotingResultNFT(address(this));
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function faucetMint(address to, uint256 amount) external onlyOwner {
        vvToken.mint(to, amount);
    }

    function stake(uint256 amount, uint256 lockWeeks)
        external
        whenNotPaused
        nonReentrant
    {
        require(amount > 0, "amount=0");
        require(
            lockWeeks >= MIN_LOCK_WEEKS && lockWeeks <= MAX_LOCK_WEEKS,
            "invalid lock"
        );

        vvToken.transferFrom(msg.sender, address(this), amount);

        uint256 expiry = block.timestamp + lockWeeks * WEEK;
        stakes[msg.sender].push(
            StakeInfo({
                amount: amount,
                expiry: expiry,
                withdrawn: false
            })
        );

        emit Staked(msg.sender, amount, lockWeeks, expiry);
    }

    function unstake(uint256 stakeIndex)
        external
        whenNotPaused
        nonReentrant
    {
        require(stakeIndex < stakes[msg.sender].length, "bad index");

        StakeInfo storage s = stakes[msg.sender][stakeIndex];
        require(!s.withdrawn, "already withdrawn");
        require(block.timestamp >= s.expiry, "still locked");

        s.withdrawn = true;
        vvToken.transfer(msg.sender, s.amount);

        emit Unstaked(msg.sender, stakeIndex, s.amount);
    }

    function createVoting(
        bytes32 id,
        uint256 deadline,
        uint256 threshold,
        string calldata description
    ) external onlyOwner whenNotPaused {
        require(!voteExists[id], "vote exists");
        require(deadline > block.timestamp, "bad deadline");
        require(bytes(description).length > 0, "empty description");

        votings[id] = Voting({
            id: id,
            deadline: deadline,
            votingPowerThreshold: threshold,
            description: description,
            yesVotes: 0,
            noVotes: 0,
            finalized: false,
            passed: false,
            resultNftId: 0
        });

        voteExists[id] = true;

        emit VotingCreated(id, deadline, threshold, description);
    }

    function vote(bytes32 id, bool support) external whenNotPaused {
        require(voteExists[id], "vote missing");

        Voting storage v = votings[id];

        require(!v.finalized, "already finalized");
        require(block.timestamp < v.deadline, "deadline passed");
        require(!hasVoted[id][msg.sender], "already voted");

        uint256 power = votingPower(msg.sender);
        require(power > 0, "no voting power");

        hasVoted[id][msg.sender] = true;

        if (support) {
            v.yesVotes += power;
        } else {
            v.noVotes += power;
        }

        emit VoteCast(id, msg.sender, support, power);

        if (v.yesVotes >= v.votingPowerThreshold) {
            _finalize(id);
        }
    }

    function finalize(bytes32 id) external whenNotPaused {
        require(voteExists[id], "vote missing");

        Voting storage v = votings[id];

        require(!v.finalized, "already finalized");
        require(
            block.timestamp >= v.deadline || v.yesVotes >= v.votingPowerThreshold,
            "too early"
        );

        _finalize(id);
    }

    function _finalize(bytes32 id) internal {
        Voting storage v = votings[id];

        v.finalized = true;
        v.passed = v.yesVotes >= v.votingPowerThreshold;

        uint256 nftId = resultNFT.mintResult(
            owner(),
            v.id,
            v.passed,
            v.yesVotes,
            v.noVotes,
            v.description
        );

        v.resultNftId = nftId;

        emit VotingFinalized(id, v.passed, v.yesVotes, v.noVotes, nftId);
    }

    // Формула из задания:
    // VP_U(t) = sum_i (T_expiry - t)^2 * A_i
    function votingPower(address user) public view returns (uint256 totalPower) {
        StakeInfo[] memory userStakes = stakes[user];
        uint256 len = userStakes.length;

        for (uint256 i = 0; i < len; i++) {
            StakeInfo memory s = userStakes[i];

            if (s.withdrawn || block.timestamp >= s.expiry) {
                continue;
            }

            uint256 dRemain = s.expiry - block.timestamp;
            totalPower += s.amount * dRemain * dRemain;
        }
    }

    function getUserStakesCount(address user) external view returns (uint256) {
        return stakes[user].length;
    }

    function getVoting(bytes32 id) external view returns (Voting memory) {
        return votings[id];
    }
}
