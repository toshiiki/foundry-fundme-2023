// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
* REMEMBER: TEST WRITING METHODOLOGY
* 1. ARRANGE - TEST SETUP
* 2. ACT - EXECUTE ACTIONS
* 3. ASSERT - VERIFY RESULTS
 */

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);  
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function test_MinumumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function test_OwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);

    }

    function test_PriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function test_FundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // next line should revert
        fundMe.fund(); // send 0 value
    }
    
    function test_FundUpdatesFundedDataStructure() public funded{
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function test_AddsFunderToArrayOfFunders() public funded{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function test_OnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function test_WithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);

    }


    function test_WithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function test_WithdrawFromMultipleFundersCheaper() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for(uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}