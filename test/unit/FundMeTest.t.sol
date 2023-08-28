//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

//is Test -> so we inherent everything from "Test"
contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000 Wei
    uint256 constant STARTING_BALANCE = 10 ether;

    /*gas calculation
    uint256 constant GAS_PRICE = 1;
    */
    function setUp() external {
        //this is us calling the fung me test function and then it calls the FundMeTest contract which then deploys the fundMe us->FundMeTest->FundMea
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe(); //We can do a new deployFundMe because it is a solidity contract
        fundMe = deployFundMe.run(); //run now returns a fundMe contract
        vm.deal(USER, STARTING_BALANCE);
    }

    //checking if the minimum usd is five
    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18); //assertEq is a function that allows you to compare two "things" and chech that they are equal
    }

    function testOwnerIsMsgSender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), address(msg.sender)); //before we used to have (this) and this points to this contract
    }

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughtETH() public {
        vm.expectRevert(); //the next line, should revert!
        //assert(this tx fails/reverts)
        fundMe.fund();
    }

    function testFunfUpdatesDataStructure() public {
        vm.prank(USER); //the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER); //we fund the contract with some money
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        //then we have the user try and withdraw because the user is not the owner
        vm.expectRevert(); //skips the cheatcode lines (hey the next line is expected to revert (so next transaction that is not vm stuff))
        vm.prank(USER);
        fundMe.withdraw(); //the one we expect to revert
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange (set up test)
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); //this is what we are testing

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0); //checking that we withdrawned everything
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //Arrange
        uint160 numberOfFunders = 10; //must be uint160 to be able to do address(0), address(1), address(2), etc to use in the for loop (uint160 has the same number of bytes as an address) uint160 to have numbers generate addresses
        uint160 startingFunderIndex = 1; //sometimes 0 address doesn't work and reverts, so start on one

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE); //this does both prank and deal in one function
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        /* gas calculation
        uint256 gasStart = gasleft(); //to see the gas spent, we need to see what was spent before and after the tx - say we sent 1000gas
        vm.txGasPrice(GAS_PRICE); //when working with anvil, even id it's a fork, you have by default 0 gas price. This allows us to put some gas price
        */
        //anything in between is going to be sent pretending to be this address
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw(); //say the cost here is 200gas
        vm.stopPrank();

        /* gas calculation prt2
        uint256 gasEnd = gasleft(); //we would have left here 800gas
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //tx.gasprice tells you the current gas price
        console.log(gasUsed);
        */

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //Arrange
        uint160 numberOfFunders = 10; //must be uint160 to be able to do address(0), address(1), address(2), etc to use in the for loop (uint160 has the same number of bytes as an address) uint160 to have numbers generate addresses
        uint160 startingFunderIndex = 1; //sometimes 0 address doesn't work and reverts, so start on one

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE); //this does both prank and deal in one function
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        //Act
        /* gas calculation
        uint256 gasStart = gasleft(); //to see the gas spent, we need to see what was spent before and after the tx - say we sent 1000gas
        vm.txGasPrice(GAS_PRICE); //when working with anvil, even id it's a fork, you have by default 0 gas price. This allows us to put some gas price
        */
        //anything in between is going to be sent pretending to be this address
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw(); //say the cost here is 200gas
        vm.stopPrank();

        /* gas calculation prt2
        uint256 gasEnd = gasleft(); //we would have left here 800gas
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; //tx.gasprice tells you the current gas price
        console.log(gasUsed);
        */

        //Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
