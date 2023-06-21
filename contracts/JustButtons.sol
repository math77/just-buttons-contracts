// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract JustButtons is ERC721, Ownable, ReentrancyGuard {
  using ECDSA for bytes32;

  uint256 private _tokenId;

  //may change that for a graph (e.g. goldsky) and delete this mapping and view method?
  mapping(address user => uint256 buttonId) private _lastMintButtonId;
  mapping(uint256 tokenId => string uri) private _tokenURIs;
  mapping(address user => mapping(uint256 buttonId => uint256 total)) private _mintsByButtonId;
  mapping(uint256 id => uint256 fee) private _mintFees;

  event Minted(
    uint256 indexed buttonId,
    uint256 indexed tokenId,
    address indexed createdBy
  );


  error URICannotBeEmpty();
  error InvalidSignature();
  error WrongPrice(uint256 correctPrice);

  constructor(uint256[] memory mintFees) ERC721("JUST BUTTONS", "JBTN") {

    for (uint8 i; i < 5; i++) {
      _mintFees[i+1] = mintFees[i];
    }

  }


  function mint(uint256 buttonId, address creator, string calldata uri, bytes calldata signature) external payable nonReentrant {
    bytes32 hash = keccak256(abi.encodePacked(buttonId, creator, uri, msg.sender));
   
    if (!verifySignature(hash, signature)) revert InvalidSignature();
    if (bytes(uri).length == 0) revert URICannotBeEmpty();
    if (_mintFees[buttonId] != msg.value) revert WrongPrice({correctPrice: _mintFees[buttonId]});

    unchecked { 
      _tokenURIs[++_tokenId] = uri;
      _mintsByButtonId[msg.sender][buttonId] += 1;
    }

    _lastMintButtonId[msg.sender] = buttonId;

    (bool sent, ) = payable(creator).call{value: (msg.value / 100) * 80}("");

    if(!sent) revert("error when sent eth");

    _mint(msg.sender, _tokenId);

    emit Minted({
      buttonId: buttonId,
      tokenId: _tokenId,
      createdBy: creator
    });
  }

  function collectFees() external onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success, "Withdraw fees error");
  }

  function minterStats(address minter) external view returns (uint256[5] memory stats) {
    for (uint256 i; i < 5; i++) {
      stats[i] = _mintsByButtonId[minter][i+1];
    }
  }

  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    _requireMinted(tokenId);

    return _tokenURIs[tokenId];
  }

  function verifySignature(bytes32 hash, bytes memory signature) internal view returns (bool) {
    bytes32 messageHash = hash.toEthSignedMessageHash();
    return messageHash.recover(signature) == owner();
  }

}