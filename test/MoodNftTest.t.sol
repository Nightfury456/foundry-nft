// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {DeployMoodNft} from "../script/DeployMoodNft.s.sol";
import {MoodNft} from "../src/MoodNft.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {MintBasicNft} from "../script/Interactions.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {FoundryZkSyncChecker} from "lib/foundry-devops/src/FoundryZkSyncChecker.sol";

contract MoodNftTest is Test, ZkSyncChainChecker, FoundryZkSyncChecker {
    string constant NFT_NAME = "Mood NFT";
    string constant NFT_SYMBOL = "MN";
    MoodNft public moodNft;
    DeployMoodNft public deployer;
    address public deployerAddress;

    string public constant HAPPY_MOOD_URI =
        "data:application/json;base64,eyJuYW1lIjoiTW9vZCBORlQiLCAiZGVzY3JpcHRpb24iOiJBbiBORlQgdGhhdCByZWZsZWN0cyB0aGUgbW9vZCBvZiB0aGUgb3duZXIsIDEwMCUgb24gQ2hhaW4hIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogIm1vb2RpbmVzcyIsICJ2YWx1ZSI6IDEwMH1dLCAiaW1hZ2UiOiJkYXRhOmlhbWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIyYVdWM1FtOTRQU0l3SURBZ01qQXdJREl3TUNJZ2QybGtkR2c5SWpRd01DSWdhR1ZwWjJoMFBTSTBNREFpSUhodGJHNXpQU0pvZEhSd09pOHZkM2QzTG5jekxtOXlaeTh5TURBd0wzTjJaeUkrRFFvZ0lDQWdQR05wY21Oc1pTQmplRDBpTVRBd0lpQmplVDBpTVRBd0lpQm1hV3hzUFNKNVpXeHNiM2NpSUhJOUlqYzRJaUJ6ZEhKdmEyVTlJbUpzWVdOcklpQnpkSEp2YTJVdGQybGtkR2c5SWpNaUlDOCtEUW9nSUNBZ1BHY2dZMnhoYzNNOUltVjVaWE1pUGcwS0lDQWdJQ0FnSUNBOFkybHlZMnhsSUdONFBTSTNNQ0lnWTNrOUlqZ3lJaUJ5UFNJeE1pSWdMejROQ2lBZ0lDQWdJQ0FnUEdOcGNtTnNaU0JqZUQwaU1USTNJaUJqZVQwaU9ESWlJSEk5SWpFeUlpQXZQZzBLSUNBZ0lEd3ZaejROQ2lBZ0lDQThjR0YwYUNCa1BTSnRNVE0yTGpneElERXhOaTQxTTJNdU5qa2dNall1TVRjdE5qUXVNVEVnTkRJdE9ERXVOVEl0TGpjeklpQnpkSGxzWlQwaVptbHNiRHB1YjI1bE95QnpkSEp2YTJVNklHSnNZV05yT3lCemRISnZhMlV0ZDJsa2RHZzZJRE03SWlBdlBnMEtQQzl6ZG1jKyJ9";

    string public constant SAD_MOOD_URI =
        "data:application/json;base64,eyJuYW1lIjoiTW9vZCBORlQiLCAiZGVzY3JpcHRpb24iOiJBbiBORlQgdGhhdCByZWZsZWN0cyB0aGUgbW9vZCBvZiB0aGUgb3duZXIsIDEwMCUgb24gQ2hhaW4hIiwgImF0dHJpYnV0ZXMiOiBbeyJ0cmFpdF90eXBlIjogIm1vb2RpbmVzcyIsICJ2YWx1ZSI6IDEwMH1dLCAiaW1hZ2UiOiJkYXRhOmlhbWdlL3N2Zyt4bWw7YmFzZTY0LFBITjJaeUIzYVdSMGFEMGlNVEF5TkhCNElpQm9aV2xuYUhROUlqRXdNalJ3ZUNJZ2RtbGxkMEp2ZUQwaU1DQXdJREV3TWpRZ01UQXlOQ0lnZUcxc2JuTTlJbWgwZEhBNkx5OTNkM2N1ZHpNdWIzSm5Mekl3TURBdmMzWm5JajROQ2lBZ0lDQThjR0YwYUNCbWFXeHNQU0lqTXpNeklnMEtJQ0FnSUNBZ0lDQmtQU0pOTlRFeUlEWTBRekkyTkM0MklEWTBJRFkwSURJMk5DNDJJRFkwSURVeE1uTXlNREF1TmlBME5EZ2dORFE0SURRME9DQTBORGd0TWpBd0xqWWdORFE0TFRRME9GTTNOVGt1TkNBMk5DQTFNVElnTmpSNmJUQWdPREl3WXkweU1EVXVOQ0F3TFRNM01pMHhOall1Tmkwek56SXRNemN5Y3pFMk5pNDJMVE0zTWlBek56SXRNemN5SURNM01pQXhOall1TmlBek56SWdNemN5TFRFMk5pNDJJRE0zTWkwek56SWdNemN5ZWlJZ0x6NE5DaUFnSUNBOGNHRjBhQ0JtYVd4c1BTSWpSVFpGTmtVMklnMEtJQ0FnSUNBZ0lDQmtQU0pOTlRFeUlERTBNR010TWpBMUxqUWdNQzB6TnpJZ01UWTJMall0TXpjeUlETTNNbk14TmpZdU5pQXpOeklnTXpjeUlETTNNaUF6TnpJdE1UWTJMallnTXpjeUxUTTNNaTB4TmpZdU5pMHpOekl0TXpjeUxUTTNNbnBOTWpnNElEUXlNV0UwT0M0d01TQTBPQzR3TVNBd0lEQWdNU0E1TmlBd0lEUTRMakF4SURRNExqQXhJREFnTUNBeExUazJJREI2YlRNM05pQXlOekpvTFRRNExqRmpMVFF1TWlBd0xUY3VPQzB6TGpJdE9DNHhMVGN1TkVNMk1EUWdOak0yTGpFZ05UWXlMalVnTlRrM0lEVXhNaUExT1RkekxUa3lMakVnTXprdU1TMDVOUzQ0SURnNExqWmpMUzR6SURRdU1pMHpMamtnTnk0MExUZ3VNU0EzTGpSSU16WXdZVGdnT0NBd0lEQWdNUzA0TFRndU5HTTBMalF0T0RRdU15QTNOQzQxTFRFMU1TNDJJREUyTUMweE5URXVObk14TlRVdU5pQTJOeTR6SURFMk1DQXhOVEV1Tm1FNElEZ2dNQ0F3SURFdE9DQTRMalI2YlRJMExUSXlOR0UwT0M0d01TQTBPQzR3TVNBd0lEQWdNU0F3TFRrMklEUTRMakF4SURRNExqQXhJREFnTUNBeElEQWdPVFo2SWlBdlBnMEtJQ0FnSUR4d1lYUm9JR1pwYkd3OUlpTXpNek1pRFFvZ0lDQWdJQ0FnSUdROUlrMHlPRGdnTkRJeFlUUTRJRFE0SURBZ01TQXdJRGsySURBZ05EZ2dORGdnTUNBeElEQXRPVFlnTUhwdE1qSTBJREV4TW1NdE9EVXVOU0F3TFRFMU5TNDJJRFkzTGpNdE1UWXdJREUxTVM0MllUZ2dPQ0F3SURBZ01DQTRJRGd1TkdnME9DNHhZelF1TWlBd0lEY3VPQzB6TGpJZ09DNHhMVGN1TkNBekxqY3RORGt1TlNBME5TNHpMVGc0TGpZZ09UVXVPQzA0T0M0MmN6a3lJRE01TGpFZ09UVXVPQ0E0T0M0Mll5NHpJRFF1TWlBekxqa2dOeTQwSURndU1TQTNMalJJTmpZMFlUZ2dPQ0F3SURBZ01DQTRMVGd1TkVNMk5qY3VOaUEyTURBdU15QTFPVGN1TlNBMU16TWdOVEV5SURVek0zcHRNVEk0TFRFeE1tRTBPQ0EwT0NBd0lERWdNQ0E1TmlBd0lEUTRJRFE0SURBZ01TQXdMVGsySURCNklpQXZQZzBLUEM5emRtYysifQ==";

    address public constant USER = address(1);

    function setUp() public {
        deployer = new DeployMoodNft();
        if (!isZkSyncChain()) {
            moodNft = deployer.run();
        } else {
            string memory sadSvg = vm.readFile("./images/dynamicNft/sad.svg");
            string memory happySvg = vm.readFile(
                "./images/dynamicNft/happy.svg"
            );
            moodNft = new MoodNft(
                deployer.svgToImageURI(sadSvg),
                deployer.svgToImageURI(happySvg)
            );
        }
    }

    function testInitializedCorrectly() public view {
        assert(
            keccak256(abi.encodePacked(moodNft.name())) ==
                keccak256(abi.encodePacked((NFT_NAME)))
        );
        assert(
            keccak256(abi.encodePacked(moodNft.symbol())) ==
                keccak256(abi.encodePacked((NFT_SYMBOL)))
        );
    }

    function testCanMintAndHaveABalance() public {
        vm.prank(USER);
        moodNft.mint();

        assert(moodNft.balanceOf(USER) == 1);
    }

    function testTokenURIDefaultIsCorrectlySet() public {
        vm.prank(USER);
        moodNft.mint();

        assert(
            keccak256(abi.encodePacked(moodNft.tokenURI(0))) ==
                keccak256(abi.encodePacked(HAPPY_MOOD_URI))
        );
    }

    function testFlipTokenToSad() public {
        vm.prank(USER);
        moodNft.mint();

        vm.prank(USER);
        moodNft.flipMood(0);

        assert(
            keccak256(abi.encodePacked(moodNft.tokenURI(0))) ==
                keccak256(abi.encodePacked(SAD_MOOD_URI))
        );
    }

    // logging events doesn't work great in foundry-zksync
    // function testEventRecordsCorrectTokenIdOnMinting()
    //     public
    //     onlyVanillaFoundry
    // {
    //     uint256 currentAvailableTokenId = moodNft.getTokenCounter();

    //     vm.prank(USER);
    //     vm.recordLogs();
    //     moodNft.mint();
    //     Vm.Log[] memory entries = vm.getRecordedLogs();

    //     bytes32 tokenId_proto = entries[1].topics[1];
    //     uint256 tokenId = uint256(tokenId_proto);

    //     assertEq(tokenId, currentAvailableTokenId);
    // }
}
