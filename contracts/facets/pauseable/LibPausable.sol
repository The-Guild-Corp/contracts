// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.20;

import {PausableStorage} from "./storage/PausableStorage.sol";

library LibPausable {
    /*//////////////////////////////////////////////////////////////
                                Library
    //////////////////////////////////////////////////////////////*/

    function _paused() internal view returns (bool paused_) {
        paused_ = PausableStorage.pausableStorage().paused;
    }

    function _pause() internal {
        PausableStorage.pausableStorage().paused = true;
    }

    function _unpause() internal {
        PausableStorage.pausableStorage().paused = false;
    }
}
