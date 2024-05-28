// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedExchange is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public admin;
    mapping(address => mapping(address => uint256)) public balances;
    mapping(address => mapping(address => uint256)) public limitOrders;

    event Deposit(address indexed token, address indexed user, uint256 amount);
    event Withdraw(address indexed token, address indexed user, uint256 amount);
    event Trade(address indexed tokenGive, uint256 amountGive, address indexed tokenGet, uint256 amountGet);
    event LimitOrderCreated(address indexed tokenGive, uint256 amountGive, address indexed tokenGet, uint256 amountGet, address indexed user);
    event LimitOrderFilled(address indexed tokenGive, uint256 amountGive, address indexed tokenGet, uint256 amountGet, address indexed user);

    constructor() {
        admin = msg.sender;
    }

    function deposit(address _token, uint256 _amount) external {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        balances[_token][msg.sender] = balances[_token][msg.sender].add(_amount);
        emit Deposit(_token, msg.sender, _amount);
    }

    function withdraw(address _token, uint256 _amount) external {
        require(balances[_token][msg.sender] >= _amount, "Insufficient balance");
        
        balances[_token][msg.sender] = balances[_token][msg.sender].sub(_amount);
        IERC20(_token).safeTransfer(msg.sender, _amount);
        emit Withdraw(_token, msg.sender, _amount);
    }
    
    function trade(address _tokenGive, uint256 _amountGive, address _tokenGet, uint256 _amountGet) external {
        require(balances[_tokenGet][msg.sender] >= _amountGet, "Insufficient balance");
        require(balances[_tokenGive][msg.sender] >= _amountGive, "Insufficient balance");
        
        balances[_tokenGive][msg.sender] = balances[_tokenGive][msg.sender].sub(_amountGive);
        balances[_tokenGet][msg.sender] = balances[_tokenGet][msg.sender].add(_amountGet);
        
        emit Trade(_tokenGive, _amountGive, _tokenGet, _amountGet);
    }

    function createLimitOrder(address _tokenGive, uint256 _amountGive, address _tokenGet, uint256 _amountGet) external nonReentrant {
        require(_amountGive > 0 && _amountGet > 0, "Amount must be greater than 0");
        IERC20(_tokenGive).safeTransferFrom(msg.sender, address(this), _amountGive);
        
        limitOrders[_tokenGive][msg.sender] = _amountGive;
        
        emit LimitOrderCreated(_tokenGive, _amountGive, _tokenGet, _amountGet, msg.sender);
    }

    function fillLimitOrder(address _tokenGive, address _tokenGet, uint256 _amountGet) external nonReentrant {
        require(limitOrders[_tokenGive][msg.sender] >= _amountGet, "Insufficient limit order balance");
        
        uint256 _amountGive = limitOrders[_tokenGive][msg.sender];
        limitOrders[_tokenGive][msg.sender] = limitOrders[_tokenGive][msg.sender].sub(_amountGet);
        
        balances[_tokenGive][msg.sender] = balances[_tokenGive][msg.sender].sub(_amountGive);
        balances[_tokenGet][msg.sender] = balances[_tokenGet][msg.sender].add(_amountGet);
        
        emit LimitOrderFilled(_tokenGive, _amountGive, _tokenGet, _amountGet, msg.sender);
    }
}