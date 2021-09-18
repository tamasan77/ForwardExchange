// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title String Manipulation Library
/// @author Tamas An
/// @notice This library contains functions for string manipulation and conversions.
/// @dev Is there a more gas-efficient solution?
library StringManipLibrary {

    /// @notice Concetenates two strings into single string
    /// @param a First string
    /// @param b Second string
    /// @return Resulting string
    function concetenateTwoStrings(string memory a, string memory b) 
        internal
        pure 
        returns(string memory) 
    {
        return string(abi.encodePacked(a, b));
    }

    
}