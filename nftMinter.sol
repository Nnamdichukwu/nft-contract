// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "./nft_contract.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MyToken is ERC721, ERC721URIStorage, AccessControl {
    error WhitelistClaimedAlready();
    error NotWhitelisted();
    error AmountTooSmall(uint expectedamount, uint inputtedAmount);
    bytes32 public merkleRoot; // this is the calculated merkleRoot
    address public owner;
   // mapping(address => NFTMetaInfo) public nftInfo;
    uint256 public notMinted;
    uint256 public balance;
    uint256 public tokenCount;
    uint256 public price;
    uint256 public totalMintable;
    uint256 public maxMints;
    string public description;
    string public utils;
  uint immutable power = 10**18;
  receive() payable external{}
    //Mint limit can be decided by contract owner
    //to decide how many NFTs a user can have

    using Counters for Counters.Counter;

  
    bool private contract_running = true; // checks the status of the contract
      mapping(address => bool) public whitelistClaimed;
    Counters.Counter private _tokenIdCounter;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  struct NFTFinance{
      address owner;
      uint amount;
      uint minters;

  }
mapping(address => NFTFinance) public nft_details;
  event Minting(address indexed minter);
    constructor(
      
        uint256 _price,
        string memory _desc,
        uint256 _quan,
    
    
        string memory _utility,
        uint256 mintLimit
      
    ) ERC721("Nnamdi", "NMD") {
        price = _price;
       description= _desc;
        totalMintable = _quan;
    
        owner =  msg.sender;
        utils = _utility;
        maxMints = mintLimit;
        _grantRole(ADMIN_ROLE, msg.sender);
      //  _grantRole(MINTER_ROLE, msg.sender);
    }

    modifier requireOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier notMintLimit(){
       require(_tokenIdCounter.current() < totalMintable);
       _ ;
    }

    function setMinter(bytes32[] calldata merkleProof) public {
        if (whitelistClaimed[msg.sender] == true){
            revert WhitelistClaimedAlready();
        }
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if( !MerkleProof.verify(merkleProof, merkleRoot, leaf)){
            revert NotWhitelisted();
        }
        _grantRole(MINTER_ROLE, msg.sender);
    }

   

    function safeMint()
        public payable
        onlyRole(MINTER_ROLE) notMintLimit
    {
         
        require(
            balanceOf(msg.sender) < maxMints
        );
        if(msg.value * power < price){
           uint expectedamount = price;
            uint inputtedAmount = msg.value;
            revert AmountTooSmall(expectedamount, inputtedAmount);
        }
        uint excess_balance = msg.value - price;
        uint payable_amount = msg.value- excess_balance; 
        nft_details[owner].amount = nft_details[owner].amount + msg.value;
        nft_details[owner].minters++;

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(owner, tokenId);
        //_setTokenURI(tokenId, uri);
        tokenCount= tokenId + 1;
        if(msg.value > nft_details[owner].amount){
        payable(address(msg.sender)).transfer(excess_balance);   
       
        payable(address(owner)).transfer(payable_amount);
         
            
       }
      else{
      
          payable(address(owner)).transfer(msg.value);
           
      } 
        notMinted = totalMintable - tokenCount;
        emit Minting(msg.sender);
    }

    
    function getMintLeft() public view returns (uint256) {
        return notMinted;
    }

    function amountMinted() public view returns (uint256) {
        return tokenCount;
    }

    function isRunning() private view requireOwner returns (bool) {
        return contract_running; // function returns if contract is running or not
    }

    function pauseContract(bool status) external requireOwner {
        contract_running = status;
    }

   

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

  
}

   
  