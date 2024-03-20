//SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console} from "forge-std/test.sol";
import {Raffle} from "../../src/Raffle.sol";
import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Vm} from "forge-std/Vm.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract TestRaffle is Test {
    event EnteredRaffle(address indexed players);
    event PickedWinner(address indexed winner);
    Raffle public raffle;
    DeployRaffle public deployer;
    HelperConfig public helperConfig;
    uint256 public entranceFee;
    uint256 public interval;
    address public vrfCoordinator;
    bytes32 public gasLane;
    uint64 public subscriptionId;
    uint32 public callbackGasLimit;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 5 ether;
    // uint256 public prize = entranceFee * (additionalEntrants + 1);
    address public playerRecorded;
    uint256 public lengthOfPlayers;
    address public link;
    uint256 public previousTimeStamp;
    uint256 public additionalEntrants = 5;

    function setUp() external {
        deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        (
            entranceFee,
            interval,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit,
            link,

        ) = helperConfig.activeNetworkConfig();
        deal(PLAYER, STARTING_USER_BALANCE);
    }

    modifier raffleEneteredAndTimePassed() {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        _;
    }

    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    function testRaffleInitializesOpenState() public {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    function testRevertWhenYouDontHaveEnoughEth() public {
        //A Arrange
        vm.prank(PLAYER);
        // Act/assert
        vm.expectRevert(Raffle.Raffle__NotEnoughETH.selector);
        raffle.enterRaffle();
    }

    function testRevertWhenRaffleIsNotOpen() public {
        raffle.SetRaffleState(Raffle.RaffleState.CALCULATING);
        vm.expectRevert(Raffle.Raffle__raffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    // ALTERNATIVE METHOD OF TESTING THE RAFFLE STATE WHEN  CALCULATING!
    function testCantEnterWhenRaffleIsCalcultaing() external {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");
        // Act/Assert
        vm.expectRevert(Raffle.Raffle__raffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        playerRecorded = raffle.getPlayer(0);

        assertEq(playerRecorded, PLAYER);
    }

    function testArrayGetsUpdated() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        lengthOfPlayers = raffle.getLength();
        assertEq(lengthOfPlayers, 1);
    }

    function testEmitsEventOnEntrance() external {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit EnteredRaffle(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
    }

    ///////////////////////////////
    ////checkUpkeepTest////
    //////////////////////////////

    function testCheckUpkeepReturnsFalseIfItHasNoBalance() public {
        // Arrange
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        //Assert
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfRaffleNotOpen() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpKeep("");
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded == false);
    }

    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval - 20);
        vm.roll(block.number + 1);
        //Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");

        //Assert
        assert(upkeepNeeded == false);
    }

    function testCheckUpKeepReturnsTrueWhenParametersAreGood() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        // Assert
        assert(upkeepNeeded == true);
    }

    ///////////////////////////////
    ////PerformupTest////
    //////////////////////////////

    function testPerformUpKeepCanOnlyRunIfCheckUpKeepIsTrue() public {
        //Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        // Act
        raffle.performUpKeep("");
    }

    function testPerformUpKeepRevertsIfCheckUpKeepIsFalse() public {
        //Arrange
        uint256 currentBalance = 0;
        uint256 numOfPlayers = 0;
        uint256 rafflestate = 0;

        vm.expectRevert(
            abi.encodeWithSelector(
                Raffle.Raffle__UpkeepNotneeded.selector,
                currentBalance,
                numOfPlayers,
                rafflestate
            )
        );
        // Assert/Act
        raffle.performUpKeep("");
    }

    function testPerformUpKeepUpdatesRaffleStateAndEmitsRequestId()
        public
        raffleEneteredAndTimePassed
    {
        // Act
        vm.recordLogs();
        raffle.performUpKeep(""); // emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];
        Raffle.RaffleState rState = raffle.getRaffleState();
        assert(uint256(requestId) > 0);
        assert(uint256(rState) == 1);
    }

    ///////////////////////////////
    ////RandomWords////
    //////////////////////////////

    function testFufillRandomWordsCanOnlyBeCalledAfterPerformUpKeep(
        uint256 randomRequestId
    ) public raffleEneteredAndTimePassed skipFork {
        // Arrange
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            randomRequestId,
            address(raffle)
        );
    }

    function testfufillRandomWordsPicksAWinnerResetsAndSendsMoney()
        public
        raffleEneteredAndTimePassed
        skipFork
    {
        // Arrange
        uint256 startingIndex = 1;
        previousTimeStamp = raffle.getStartTimeStamp();
        for (
            uint256 i = startingIndex;
            i < startingIndex + additionalEntrants;
            i++
        ) {
            address player = address(uint160(i));
            // Act
            hoax(player, STARTING_USER_BALANCE);
            raffle.enterRaffle{value: entranceFee}();
        }

        vm.recordLogs();
        raffle.performUpKeep(""); // emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        // Pretend to be chainlink vrf to get a random number and pick winner
        VRFCoordinatorV2Mock(vrfCoordinator).fulfillRandomWords(
            uint256(requestId),
            address(raffle)
        );
        uint256 prize = entranceFee * (additionalEntrants + 1);

        console.log(raffle.getRecentWiner().balance);
        console.log((STARTING_USER_BALANCE + prize) - entranceFee);
        console.log(prize);
        console.log(entranceFee);
        // Assert
        assert(uint256(Raffle.RaffleState.OPEN) == 0);
        assert(raffle.getRecentWiner() != address(0));
        assert(raffle.getLength() == 0);
        assert(previousTimeStamp < raffle.getStartTimeStamp());
        assert(
            raffle.getRecentWiner().balance ==
                (STARTING_USER_BALANCE + prize) - entranceFee
        );
    }
}
