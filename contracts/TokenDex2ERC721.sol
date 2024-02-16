// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IBlast {
  function configureClaimableGas() external;
  function configureGovernor(address governor) external;
  function claimAllGas(address contractAddress, address recipient) external returns (uint256);
}

contract TokenDex2ERC721 is ERC721, ERC721Enumerable, Ownable {
    IBlast public constant BLAST = IBlast(0x4300000000000000000000000000000000000002);
    using Math for uint256;
    using Strings for uint256;

    uint256 private _nextTokenId;
    uint256[4] private _tiers;
    uint256[4] private _maxNumberOfNFTsByType;
    address[4] private _anotherAddresses;
    string private _baseTokenURI;
    address private _paymentSplitterAddress;

    struct TokenMetadata {
        string name;
        string image;
    }

    mapping(uint256 => TokenMetadata) private _tokenMetadata;
    mapping(uint256 => uint256) private _tokenType;
    mapping(uint256 => uint256) private _tokenTypeCount;

    constructor(
        address initialOwner,
        string memory _name,
        string memory _symbol,
        string memory baseTokenURI,
        string[4] memory imageTypes,
        uint256[4] memory tiers,
        uint256[4] memory maxNumberOfNFTsByType,
        address[4] memory anotherAddresses,
        address paymentSplitterAddress
        
    )
        ERC721(_name, _symbol)
        Ownable(initialOwner)
    {
        for (uint256 i = 0; i < 4; i++) {
           _tokenMetadata[i + 1] = TokenMetadata(string(abi.encodePacked("Type ", Strings.toString(i + 1))), imageTypes[i]);
        }
        _baseTokenURI = baseTokenURI;
        _tiers = tiers;
        _maxNumberOfNFTsByType = maxNumberOfNFTsByType;
        _anotherAddresses = anotherAddresses;
        BLAST.configureClaimableGas();
        BLAST.configureGovernor(address(this));
        _paymentSplitterAddress = paymentSplitterAddress;
    }

    function claimMyContractsGas() external onlyOwner {
        BLAST.claimAllGas(address(this), _paymentSplitterAddress);
    }

    function setPaymentSplitterAddress(address paymentSplitterAddress) public onlyOwner {
        _paymentSplitterAddress = paymentSplitterAddress;
    }
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setImageTypes(string[] memory imageTypes) public onlyOwner {
        require(imageTypes.length == 4, "Invalid array length");
        
        for (uint256 i = 0; i < imageTypes.length; i++) {
            _tokenMetadata[i + 1].image = imageTypes[i];
        }
    }

    function setTiers(uint256[4] memory newTiers) public onlyOwner {
        _tiers = newTiers;
    }
    function setMaxNumberOfNFTsByType(uint256[4] memory newMaxNumberOfNFTsByType) public onlyOwner {
        _maxNumberOfNFTsByType = newMaxNumberOfNFTsByType;
    }

    function setAnotherAddresses(address[4] memory newAddresses) public onlyOwner {
        _anotherAddresses = newAddresses;
    }

    function safeMint() external payable {
        require(msg.value > 0, "Payment required");
        require(msg.value == _tiers[0] || msg.value == _tiers[1] || msg.value == _tiers[2] || msg.value == _tiers[3],
         "Payment amount does not match");

        uint256 totalPayment = msg.value;
        uint256 tokenId;
        uint256 typeId;

        require(address(this).balance >= totalPayment, "Insufficient balance for total payment");
        uint256 paymen1 = totalPayment * 60 / 100;
        uint256 paymen2 = totalPayment * 20 / 100;
        uint256 paymen3 = totalPayment * 15 / 100;
        uint256 paymen4 = totalPayment - paymen1 - paymen2 - paymen3; 

        payable(_anotherAddresses[0]).transfer(paymen1);
        payable(_anotherAddresses[1]).transfer(paymen2);
        payable(_anotherAddresses[2]).transfer(paymen3);
        payable(_anotherAddresses[3]).transfer(paymen4);

        for (uint256 i = 0; i < 4; i++) {
            if (totalPayment == _tiers[i]) {
                require(_tokenTypeCount[i + 1] < _maxNumberOfNFTsByType[i], "Exceeded maximum minting limit for this type");
                tokenId = _mintNFT(msg.sender, i + 1);
                typeId = i + 1;
                break;
            }
        }

        require(typeId > 0, "Insufficient payment for any tier");
        
        _tokenType[tokenId] = typeId;
        _tokenTypeCount[typeId]++;
    }

    function getTokenMetadata(uint256 tokenId) public view returns (string memory name, string memory image) {
        return (_tokenMetadata[_tokenType[tokenId]].name, _tokenMetadata[_tokenType[tokenId]].image);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
         require(ownerOf(tokenId) != address(0), "URI query for nonexistent token");

        string memory baseURI = _baseURI();
        if (bytes(baseURI).length == 0) {
            return "";
        }

        (string memory name, string memory image) = getTokenMetadata(tokenId);

        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI,"/", image))
            : "";
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function _mintNFT(address to, uint256 typeId) private returns (uint256) {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenMetadata(tokenId, typeId);
        return tokenId;
    }

    function _setTokenMetadata(uint256 tokenId, uint256 typeId) private {
        _tokenType[tokenId] = typeId;
    }


    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}