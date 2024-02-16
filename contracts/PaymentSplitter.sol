// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PaymentSplitter {
    address private owner;
    address private address1;
    address private address2;
    address private address3;
    address private address4;

    constructor(
        address _address1,
        address _address2,
        address _address3,
        address _address4
    ) {
        owner = msg.sender;
        address1 = _address1;
        address2 = _address2;
        address3 = _address3;
        address4 = _address4;
    }

    receive() external payable {}

    function distributeBalance() external {
        require(msg.sender == owner, "Only the owner can distribute the balance");

        uint256 contractBalance = address(this).balance;

        require(contractBalance > 0, "Contract balance is zero");

        uint256 share1 = (contractBalance * 60) / 100;
        uint256 share2 = (contractBalance * 20) / 100;
        uint256 share3 = (contractBalance * 15) / 100;
        uint256 share4 = contractBalance - share1 - share2 - share3;

        payable(address1).transfer(share1);
        payable(address2).transfer(share2);
        payable(address3).transfer(share3);
        payable(address4).transfer(share4);
    }

    function changeAddresses(
        address _newAddress1,
        address _newAddress2,
        address _newAddress3,
        address _newAddress4
    ) external {
        require(msg.sender == owner, "Only the owner can change addresses");
        require(
            _newAddress1 != address(0) &&
                _newAddress2 != address(0) &&
                _newAddress3 != address(0) &&
                _newAddress4 != address(0),
            "Addresses cannot be zero"
        );

        address1 = _newAddress1;
        address2 = _newAddress2;
        address3 = _newAddress3;
        address4 = _newAddress4;
    }
}
