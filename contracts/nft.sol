// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721Enumerable, Ownable {
    using Strings for uint256;

    string baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    uint256 public cost;
    uint256 public maxSupply;
    uint256 public maxMintAmount;
    bool public revealed = false;
    bool public paused = false;

    mapping (uint256 => bool) public isSaleing;
    mapping (uint256 => address payable) public selling;
    mapping (uint256 => uint256) public sellPrice;

    mapping (address => mapping (uint256 => bool)) public isOffering;
    mapping (uint256 => mapping (address => uint256)) public offerPrice;
    uint256 public fee;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI,
        string memory _initNotRevealedUri
    ) ERC721(_name, _symbol) {
        setBaseURI(_initBaseURI);
        setNotRevealedURI(_initNotRevealedUri);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _mintAmount) public payable {
        uint256 supply = totalSupply();
        require(!paused);
        require(_mintAmount > 0);
        require(_mintAmount <= maxMintAmount);
        require(supply + _mintAmount <= maxSupply);

        if (msg.sender != owner()) {
            require(msg.value >= cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        
        if(revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function reveal() public onlyOwner() {
        revealed = true;
    }

    function setCost(uint256 _newCost) public onlyOwner() {
        cost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner() {
        maxMintAmount = _newmaxMintAmount;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    
    function setFee(uint256 _fee) external onlyOwner returns(bool) {
        fee = _fee;

        return true;
    }
    function getFee() public view returns(uint256) {
        return fee;
    }


    function sale(uint256 tokenid, uint256 price) external returns(bool) {
        require(ownerOf(tokenid) == msg.sender, "KIP17: You don't have this NFT");
        require(isSaleing[tokenid] == false, "KIP17: This NFT is currently on sale.");

        transferFrom(msg.sender, owner(), tokenid);

        selling[tokenid] = payable(msg.sender);
        sellPrice[tokenid] = price;
        isSaleing[tokenid] = true;

        return true;
    }

    function saleCancel(uint256 tokenid) external returns(bool) {
        require(ownerOf(tokenid) == msg.sender, "KIP17: You don't have this NFT");
        require(isSaleing[tokenid] == true, "KIP17: This NFT is currently not on sale.");

        selling[tokenid] = payable(address(0));
        sellPrice[tokenid] = 0;
        isSaleing[tokenid] = false;

        transferFrom(owner(), msg.sender, tokenid);


        return true;
    } 

    function purchase(uint256 tokenid) external payable returns(bool) {
        require(msg.value == sellPrice[tokenid], "KIP17: It doesn't fit the NFT's price");
        require(isSaleing[tokenid] == true, "KIP17: This NFT is currently not on sale.");

        uint256 payed = msg.value * fee / 100;

        transferFrom(owner(), msg.sender, tokenid);
        
        selling[tokenid].transfer(msg.value - payed);
        payable(owner()).transfer(payed);

        selling[tokenid] = payable(address(0));
        sellPrice[tokenid] = 0;
        isSaleing[tokenid] = false;

        return true;
    }

    function offer(uint256 tokenid, uint256 price) external payable returns(bool) {
        require(isOffering[msg.sender][tokenid] == false, "KIP17: You are currently on offering to the NFT.");
        require(msg.value == price, "KIP17: The offered amount is not right.");

        offerPrice[tokenid][msg.sender] = msg.value;
        isOffering[msg.sender][tokenid] = true;

        return true;
    }

    function offerCancel(uint256 tokenid) external returns(bool) {
        require(isOffering[msg.sender][tokenid] == true, "KIP17: You are currently not on offering to the NFT.");

        payable(msg.sender).transfer(offerPrice[tokenid][msg.sender]);

        offerPrice[tokenid][msg.sender] = 0;
        isOffering[msg.sender][tokenid] = false;

        return true;
    }
        

    function saleByOffering(uint256 tokenid, address provider) external returns(bool) {
        require(ownerOf(tokenid) == msg.sender, "KIP17: You don't have this NFT");
        require(isOffering[provider][tokenid] == true, "KIP17: Provider are currently not on offering to the NFT.");

        uint256 payed = offerPrice[tokenid][provider] * fee / 100;
        
        transferFrom(msg.sender, owner(), tokenid);

        payable(msg.sender).transfer(offerPrice[tokenid][provider] - payed);
        payable(owner()).transfer(payed);

        offerPrice[tokenid][provider] = 0;
        isOffering[provider][tokenid] = false;

        return true;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function withdraw() public payable onlyOwner {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success);
    }
}