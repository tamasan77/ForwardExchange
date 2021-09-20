// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

/// @title Date-Time Library
/// @author Tamas An
/// @notice This library contains functions for date-time related helpers.
/// @dev Is there a more gas-efficient solution?
library DateTimeLibrary {

    /// @notice Gives difference in seconds between two timestamps
    /// @dev taken from BokkyPooBahsDateTimeLibrary (MIT license)
    /// @param fromTimestamp Timestamp to calculate time from.
    /// @param toTimestamp Timestamp to calculate time to.
    /// @return _seconds Time difference.
    function diffSeconds(uint fromTimestamp, uint toTimestamp) 
        internal 
        pure 
        returns (uint _seconds) 
    {
        require(fromTimestamp <= toTimestamp, "timediff err");
        _seconds = toTimestamp - fromTimestamp;
    }


}