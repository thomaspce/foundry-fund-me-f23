// get funds from user
// withdraw funds
// set a minimum funding value in usd

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    //type declaration
    using PriceConverter for uint256;

    mapping(address funders => uint256 amountFunded)
        private s_addressToAmountFunded; //s because these are storage variables
    address[] private s_funders;

    address private immutable i_owner; //i_ for unchangeable
    uint256 public constant MINIMUM_USD = 5e18; //Capital letters for constants
    AggregatorV3Interface private s_priceFeed; //storage variables have s_

    constructor(address priceFeed) {
        //so we pass it an adress -> for compatibility depending on the chain we are on
        //constructor is immediately called when the smart contract starts
        i_owner = msg.sender; //to define the caller of this contract as the owner
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // Allow users to send $
        // Have a minimum $ sent

        //value and sender are gloably available units in solidity (there are more and they are viewable in the solidity documentation)
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough ETH"
        ); //1e18 = 1ETH = 100000000000000000 Wei / converts how much Wei is sent in $ and checks if it's minimum 5$
        s_funders.push(msg.sender); //store the senders address
        // addressToAmountFunded[msg.sender] = addressToAmountFunded[msg.sender] + msg.value; //stores and associates the senders address and how much he sent
        // other way of writing it:
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (
            uint256 funderIndex = 0;
            funderIndex < fundersLength; //so we don't reed from storage each time which costs more gas
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); //reset the array

        //call
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}(""); //to transfer/pay the eth
        require(callSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        // require(msg.sender == owner, "Must be owner"); //so only the owner of the contract can withdraw

        //.lenght allows to get lenght of an array
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0); //reset the array

        //transfer
        // payable(msg.sender).transfer(address(this).balance);

        //send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");

        //call
        (bool callSuccess /*bytes memory dataReturned*/, ) = payable(msg.sender)
            .call{value: address(this).balance}(""); //to transfer/pay the eth
        require(callSuccess, "Call failed");
        //revert(); //works same as the require above, used to revert any operation
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!"); //So only the owner can withraw the money
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //then execute what ever else is in the function / order of the underscore matters for when to execute the function code
    }

    receive() external payable {
        //if someone sends money without using the fund function we can still execute the original code (including $ min -> else payement refused)
        fund();
    }

    fallback() external payable {
        //if someone tries to send data to the smart contract without using an integrated function it goes through here
        fund();
    }

    /**
     * View / Pure functions (Getters)
     */
    //using getters instead of the s_... is a lot more readable
    //improving gas efficiency -> make variable private and then use them from external view functions
    function getAddressToAmountFunded(
        address fundingAddress
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    //we can use these two getter functions to see if these variables are populated
    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
