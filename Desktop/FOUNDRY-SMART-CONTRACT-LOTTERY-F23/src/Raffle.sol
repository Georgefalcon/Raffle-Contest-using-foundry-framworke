//SPDX-License-Identifier: MIT

// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts

// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
pragma solidity 0.8.22;

/**
 * @title A Sample Raffle Contract
 * @author Georgefalcon
 * @notice This contract is for creating a simple raffle
 * @dev Implements Chainlink VRFv2 and chainlink Automation
 */
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Raffle is VRFConsumerBaseV2 {
    error Raffle__NotEnoughETH();
    error Raffle__TransferFailed();
    error Raffle__raffleNotOpen();
    error Raffle__UpkeepNotneeded(
        uint256 currentBalance,
        uint256 numOfPlayers,
        uint256 rafflestate
    );
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable i_entranceFee;
    address payable[] private s_players;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;
    // duration of the raffle
    uint256 private immutable i_interval;
    uint256 private s_startTimeStamp;
    address private s_recentWinner;
    RaffleState public s_raffleState;

    /**Events**/
    event EnteredRaffle(address indexed players);
    event PickedWinner(address indexed winner);
    event requestRaffleWinner(uint256 indexed requestId);

    constructor(
        uint256 entranceFee,
        uint256 interval,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_interval = interval;
        s_startTimeStamp = block.timestamp;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_raffleState = RaffleState.OPEN;
        //s_players = s_players.push(address(0));
    }

    function enterRaffle() public payable {
        // require(msg.value >= i_entranceFee, "NotEnoughETH"); not Gas efficient
        if (msg.value < i_entranceFee) {
            revert Raffle__NotEnoughETH();
        }

        if (s_raffleState != RaffleState.OPEN) {
            revert Raffle__raffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit EnteredRaffle(msg.sender);
    }

    //THE PLAN
    //1. Get a random number
    //2. Use the random number to pick a player
    //3. Be automatically called

    /**
     * @dev This is the function that the chainlink Automation node
     * calls to see if it's time to perform an upkeep
     * The following should be true for this to return true:
     * 1. The time has passed between the raffle runs
     * 2. The raffle is in the OPEN state
     * 3. The contact has ETH(aka players)
     * 4. (Implicit) The subcription is funded with LINK
     */
    function checkUpkeep(
        bytes memory /*CheckData*/
    ) public view returns (bool UpkeepNeeded, bytes memory /*performData*/) {
        bool timehasPassed = (block.timestamp - s_startTimeStamp) >= i_interval;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasplayers = s_players.length > 0;
        bool balanceOfPlayers = address(this).balance > 0;
        UpkeepNeeded = (timehasPassed &&
            isOpen &&
            hasplayers &&
            balanceOfPlayers);
        return (UpkeepNeeded, "0x0");
    }

    // PickWinner
    function performUpKeep(bytes calldata /*performData*/) external {
        (bool UpkeepNeeded, ) = checkUpkeep("");
        if (!UpkeepNeeded) {
            revert Raffle__UpkeepNotneeded(
                address(this).balance,
                s_players.length,
                uint256(s_raffleState)
            );
        }
        s_raffleState = RaffleState.CALCULATING;
        // Get a random number
        // But first we have to make a request call to chainlink to get this done
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane, //keyHash
            i_subscriptionId,
            REQUEST_CONFIRMATIONS, // block confirmation
            i_callbackGasLimit,
            NUM_WORDS
        );
        emit requestRaffleWinner(requestId);
    }

    // CEI: checks, Effect, Interactions
    function fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_players.length;
        address payable winner = s_players[indexOfWinner];
        s_recentWinner = winner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_startTimeStamp = block.timestamp;
        (bool success, ) = winner.call{value: address(this).balance}("");
        if (!success) {
            revert Raffle__TransferFailed();
        }
        emit PickedWinner(winner);
    }

    //Getter Function
    function getEntranceFee() external view returns (uint256) {
        return i_entranceFee;
    }

    function getRaffleState() external view returns (RaffleState) {
        return s_raffleState;
    }

    function getPlayer(uint256 indexOfPlayer) external view returns (address) {
        return s_players[indexOfPlayer];
    }

    function getLength() external view returns (uint256) {
        return s_players.length;
    }

    function getRecentWiner() external returns (address) {
        return s_recentWinner;
    }

    function getStartTimeStamp() external returns (uint256) {
        return s_startTimeStamp;
    }

    //Setter function
    function SetRaffleState(RaffleState _state) external returns (RaffleState) {
        s_raffleState = _state;
        return s_raffleState;
    }
}
