//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// to get the string length in solidity   
import { StringUtils } from "./libraries/StringUtils.sol";

// standart OpenZeppelin contracts
// ERC721 Non-Fungible Token Standard(NFT)
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import {Base64} from "./libraries/Base64.sol";

import "hardhat/console.sol";

// inherit the OpenZeppelin contract to use its methods
contract Domain is ERC721URIStorage {

  // track of tokenIds
  // this is for saving on gas 
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // set the domain ending (eg: .xyz)
  string public tld;

	// NFT images on chain as SVGs
  // SVG is an image that is built with code
  string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M72.863 42.949c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-10.081 6.032-6.85 3.934-10.081 6.032c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-8.013-4.721a4.52 4.52 0 0 1-1.589-1.616c-.384-.665-.594-1.418-.608-2.187v-9.31c-.013-.775.185-1.538.572-2.208a4.25 4.25 0 0 1 1.625-1.595l7.884-4.59c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v6.032l6.85-4.065v-6.032c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595L41.456 24.59c-.668-.387-1.426-.59-2.197-.59s-1.529.204-2.197.59l-14.864 8.655a4.25 4.25 0 0 0-1.625 1.595c-.387.67-.585 1.434-.572 2.208v17.441c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l10.081-5.901 6.85-4.065 10.081-5.901c.668-.387 1.426-.59 2.197-.59s1.529.204 2.197.59l7.884 4.59a4.52 4.52 0 0 1 1.589 1.616c.384.665.594 1.418.608 2.187v9.311c.013.775-.185 1.538-.572 2.208a4.25 4.25 0 0 1-1.625 1.595l-7.884 4.721c-.668.387-1.426.59-2.197.59s-1.529-.204-2.197-.59l-7.884-4.59a4.52 4.52 0 0 1-1.589-1.616c-.385-.665-.594-1.418-.608-2.187v-6.032l-6.85 4.065v6.032c-.013.775.185 1.538.572 2.208a4.25 4.25 0 0 0 1.625 1.595l14.864 8.655c.668.387 1.426.59 2.197.59s1.529-.204 2.197-.59l14.864-8.655c.657-.394 1.204-.95 1.589-1.616s.594-1.418.609-2.187V55.538c.013-.775-.185-1.538-.572-2.208a4.25 4.25 0 0 0-1.625-1.595l-14.993-8.786z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#cb5eee"/><stop offset="1" stop-color="#0cd7e4" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
  string svgPartTwo = '</text></svg>';

  // "mapping" data type, maps the strings to the wallet address 
  mapping(string => address) public domains;

  // mapping to store the values 
  mapping(string => string) public records;

  // used to withdraw the funds
  // the contract will have a balance, as it receives the payments 
  // and the owner can withdraw this amount 
  address payable public owner;

  // collection name: EdaTweets Name Service
  // Symbol: EDA
  constructor(string memory _tld) payable ERC721("Eda Tweets Name Service", "EDA") {
    owner = payable(msg.sender);
    tld = _tld;
    console.log("%s name service deployed", _tld);
  }

  // The name <> wallet address
  function register(string calldata name) public payable{

    // Checks the name is unregistered 
    require(domains[name] == address(0));

    // Check if enough Matic is paid in the transaction, the price is pre-determined 
    require(msg.value >= 10**1, "Not enough Matic paid");

		// Combine the name + tld
    string memory _name = string(abi.encodePacked(name, ".", tld));

		// Create the SVG (image) for the NFT with the name
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    uint256 newRecordId = _tokenIds.current();
  	uint256 length = StringUtils.strlen(name);
		string memory strLen = Strings.toString(length);

    console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

		// Create the JSON metadata of our NFT
    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "',
            _name,
            '", "description": "A domain on the Eda Tweets name service", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(finalSvg)),
            '","length":"',
            strLen,
            '"}'
          )
        )
      )
    );

    string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));
	  console.log("Final tokenURI", finalTokenUri);

    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, finalTokenUri);

      // the address is the wallet making the transaction  
      domains[name] = msg.sender;
      console.log("%s has registered a domain!", msg.sender);
      _tokenIds.increment();
  }

  // get the address of the domain name 
  function getAddress(string calldata name) public view returns (address) {
    return domains[name];
  }

  // set the record with the domain name and the given record 
  function setRecord(string calldata name, string calldata record) public {
    // Check that the owner is the transaction sender
    require(domains[name] == msg.sender);
    records[name] = record;
  }

  // get the record with the domian name
  function getRecord(string calldata name) public view returns(string memory) {
    return records[name];
  }

  // when we use the modifier function, it will require that the person is the owner
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  // checks if its the owner who is making the call 
  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  // gets the balance and sends to the requestor 
  function withdraw() public onlyOwner {
    uint amount = address(this).balance;
    
    (bool success, ) = msg.sender.call{value: amount}("");
    require(success, "Failed to withdraw Matic");
  } 

}