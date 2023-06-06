// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {tokenUtils} from "./tokenUtils.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TimeLock {
    using tokenUtils for IERC20;
    // address constant ttokenAddress = 0xD959C2b807b63236E2005FC23b6c479054522ebA;
    IERC20 token;
    uint256 public decimal;
    string public symbol;
    address immutable contractOwner;

    enum SwapStatus {
        // initiator tokens locked in the contract
        Started, // 0
        Withdrew, // 1 cansel
        Fail, // 2
        Finished //3
    }

    constructor() {
        contractOwner = msg.sender;
        emit ContractCreated(address(this));
    }

    struct Swap {
        address initiator;
        address beneficiary;
        address tokenAddress;
        bytes32 secret;
        uint256 amount;
        uint256 remaining;
        uint256 lockedUntil;
        SwapStatus status;
    }

    // mappings TODO chang the access to internal in production
    mapping(bytes32 => Swap) public swaps;

    // events
    event SwapCreated(bytes32 swapId);
    event SwapFinished(bytes32 swapId);
    event SwapFail(address tokenAddress, address initiator, uint256 amount);
    event PasswordMismatchAttempt(address sender, bytes32 swapId);
    event Log(bytes32 res);
    event ContractCreated(address indexed _contractAddress);

    // arrays
    bytes32[] public swapIds;
    //modifiers
    modifier onlyAuthurized(address _address1, address _address2) {
        require(_address1 == _address2);
        _;
    }

    modifier onlyauthurized(address _address1, address _address2) {
        require(_address1 == _address2);
        _;
    }

    //no1
    function lockFunds(
        address __tokenAddress,
        uint256 __releaseTime,
        uint256 amount,
        bytes32 _secret
    ) public payable {
        token = IERC20(__tokenAddress);
        (decimal, symbol) = token.getTokenMetadata();
        uint256 balance = token.balanceOf(msg.sender);
        if (balance <= amount) {
            revert(string(abi.encodePacked("Insufficient Funds ", balance)));
        }
        bool transferred = token.transferFrom(
            msg.sender,
            address(this),
            amount
        );
        Swap memory thisSwap;
        if (!transferred) {
            thisSwap.status = SwapStatus.Fail;
            emit SwapFail(__tokenAddress, msg.sender, amount);
            revert("Transfer error");
        }
        thisSwap.initiator = msg.sender;
        thisSwap.tokenAddress = __tokenAddress;
        thisSwap.lockedUntil = __releaseTime;
        thisSwap.amount = amount;
        // two-time hashed
        thisSwap.secret = keccak256(abi.encodePacked(_secret));
        bytes32 swapId = keccak256(abi.encode(thisSwap));
        thisSwap.status = SwapStatus.Started;
        swaps[swapId] = thisSwap;
        swapIds.push(swapId);
        emit SwapCreated(swapId);
    }

    function currantAllowance(
        address _token,
        address owner,
        address spender
    ) public view returns (uint256) {
        return IERC20(_token).allowance(owner, spender);
    }

    function fullfill(bytes32 _swapId, uint256 _amount) external {
        Swap storage thisSwap = swaps[_swapId];
        if (
            thisSwap.beneficiary != 0x0000000000000000000000000000000000000000
        ) {
            revert("this swap alrady fullFilled for now");
        }
        if (thisSwap.initiator == msg.sender) {
            revert("you can't fullFill your owon swap");
        }

        if (_amount > thisSwap.amount) {
            revert("proposed amount is bigger than the swap total amount");
        } else if (_amount < thisSwap.amount) {
            thisSwap.remaining = thisSwap.amount - _amount;
            thisSwap.amount -= _amount;
            swaps[_swapId].beneficiary = msg.sender;
        } else {
            swaps[_swapId].beneficiary = msg.sender;
        }
    }

    function releaseFunds(bytes32 _swapId) external {
        Swap memory swap = swaps[_swapId];
        if (block.timestamp <= swap.lockedUntil) {
            revert("Not yet buddy");
        }
        if (msg.sender != swap.beneficiary) {
            revert("Unauthorized(swap.beneficiary)");
        }
        IERC20 _token = IERC20(address(swap.tokenAddress));
        swap.status = SwapStatus.Finished;
        _token.transfer(swap.beneficiary, swap.amount);
    }

    function getContractBalance(address _tokenAddress, address _address)
        public
        view
        returns (uint256)
    {
        IERC20 _token = IERC20(_tokenAddress);
        return _token.balanceOf(_address);
    }

    // cancel the swap
    function withdrew(bytes32 _swapId, bytes32 _secret) external payable {
        Swap memory swap;
        swap = swaps[_swapId];
        if (block.timestamp <= swap.lockedUntil) {
            revert("This swap is still locked");
        }
        if (swap.status != SwapStatus.Started) {
            revert("Swap status error");
        }
        if (msg.sender != swap.initiator) {
            revert("Unauthorized(initiator)");
        }
        if (swap.secret != keccak256(abi.encodePacked(_secret))) {
            emit PasswordMismatchAttempt(msg.sender, _swapId);
            revert("Password mismatch");
        }
        IERC20 _token = IERC20(swap.tokenAddress);
        _token.transfer(swap.initiator, swap.amount);
        swaps[_swapId].status = SwapStatus.Withdrew;
    }
}

error TimeShouldBeIntheFuture(
    string reason,
    uint256 currentTime,
    uint256 passedTime
);

// add more custom errors
error NoFundsToRelease(uint256 balance);
error Unauthorized(address beneficiary);
error InsufficientFunds(string reason, uint256 balance, uint256 required);
    /*
    Which function is called, fallback() or receive()?

           send Ether
               |
         msg.data is empty?
              / \
            yes  no
            /     \
receive() exists?  fallback()
         /   \
        yes   no
        /      \
    receive()   fallback()
    */