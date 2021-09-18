// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title String Manipulation Library
/// @author Tamas An
/// @notice This library contains functions for string manipulation and conversions.
/// @dev Is there a more gas-efficient solution?
library StringManipLibrary {

    /// @notice Concatenates two strings into single string
    /// @param a First string
    /// @param b Second string
    /// @return Resulting string
    function concatenateTwoStrings(string memory a, string memory b) 
        internal
        pure 
        returns(string memory) 
    {
        return string(abi.encodePacked(a, b));
    }

    /// @notice Parse uint to sring.
    /// @param _i Uint to be parsed
    /// @return _uintAsString Resulting string
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}