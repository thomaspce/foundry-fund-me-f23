// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // Address : 0x694AA1769357215DE4FAC081bf1f309aDC325306 addresse du smart contract qui fait la conversion ETH/USD

        (, int256 price, , , ) = priceFeed.latestRoundData(); //recuperer seulement le prix, le reste ne nous interesse pas
        return uint256(price * 1e10); //convertir le prix renvoyé en uint et x10 pour le transformer en Wei
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed); //to get how much eth is actually worth
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1e18; //current price x how much is sent to calculte the value in $

        return ethAmountInUSD;
    }
}
