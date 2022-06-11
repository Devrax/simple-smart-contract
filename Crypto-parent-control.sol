// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.7 < 0.9.0;

// Kid(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2, "Jim", "Marc", 1656967227, 0, false),
// Kid(0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, "Jane", "Mary", 1654382738, 0, false),
// Kid(0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB, "Uladis", "Encarnacion", 1656967227, 0, false)

/// @author Rafael Mejia Blanco
/// @title contract to parent manage kid's wallets
contract CryptoParent {
    // owner DAD
    address owner;

    event logKidFundingReceived(address addr, uint amount, uint contractBalance);   

    constructor() {
        owner = msg.sender;
    }

    /// @dev define Kid
    struct Kid {
        address payable walletAddress;
        string firstName;
        string lastName;
        uint releaseTime;
        uint amount;
        bool canWithdraw;
    }

    Kid[] public kids;

    /// @dev controller for owner controls transactions only
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can add kids");
        _;
    }

    /// @param walletAddress Kid's payable address
    /// @param firstName Kid's string name
    /// @param lastName Kid's string lastName
    /// @param releaseTime Uint Time when Kid will be capable of manage their account by their own.
    /// @param amount Uint Initial amount that kid will start holding
    /// @param canWithdraw Bool that specify if the kid is capable of withdraw its account
    function addKid(address payable walletAddress, string memory firstName, string memory lastName, uint releaseTime, uint amount, bool canWithdraw) public onlyOwner{
        kids.push(Kid(
            walletAddress,
            firstName,
            lastName,
            releaseTime,
            amount,
            canWithdraw
        ));
    }

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }

    function deposit(address _walletAddress) public payable {
        addToKidsBalance(_walletAddress);
    }

    function addToKidsBalance(address _walletAddress) private onlyOwner{

        for(uint i = 0; i < kids.length; i++) {
            if(kids[i].walletAddress == _walletAddress) {
                kids[i].amount += msg.value;
                emit logKidFundingReceived(_walletAddress, msg.value, balanceOf());
            }
        }

    }

    function getIndex(address _walletAddress) view private returns(uint, bool) {
        for(uint i = 0; i < kids.length; i++) {
            if(kids[i].walletAddress == _walletAddress) {
                return (i, true);
            }
        }

        return (0, false);
    }

    // kid checks if able to withdraw
    function availableToWithdraw(address _walletAddress) public returns(bool) {
        (uint _index, bool _doesExist) = getIndex(_walletAddress);

        if(_doesExist) {
            require(block.timestamp > kids[_index].releaseTime, "You cannot withdraw yet!");
            if(block.timestamp > kids[_index].releaseTime) {
                kids[_index].canWithdraw = true;
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    //withdraw money
    function withdraw(address payable _walletAddress) public payable {
        (uint _index, bool _doesExist) = getIndex(_walletAddress);
        if(_doesExist) {
            Kid memory kid = kids[_index];
            require(msg.sender == kid.walletAddress, "You must be the kid to withdraw");
            require(kid.canWithdraw == true, "You must be 18 years old to withdraw");
            kids[_index].walletAddress.transfer(kids[_index].amount);
        }
    }
}
