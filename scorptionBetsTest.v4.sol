// SPDX-License-Identifier: MIT
// ScorpionBets version the first, try 4
/* 
NOTES: this seems to be working.  
added minimum bet to hopefully fix large bet failures
*/

pragma solidity ^0.8.0;


//required by ownable.sol
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol";

//import some nice ownership functions
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

//import token functions
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

abstract contract Token is ERC20{}

contract ScorpionBets is Ownable {
  
    // this is used to count the total number of bets, and also as a unique ID for bets
    uint betCount = 0;
    uint public sumHomeBets = 0;
    uint public sumAwayBets = 0;
    uint public totalOfBets = 0;
    bool public bettingFrozen = true;
    //insert token contract address here...
    address chitContract = 0x681B52f92d4b3fEAd2091ff6b5a234f493Ad2E95;
    uint minimumBet = 1000000000000;  //1 microEther

    //used for emitting test info
    //event Payouts(address _playerWallet, uint _payout, bool betHome);

    //the bettinCard is a ledger of all the bets in the current round
    mapping(uint => bet) private bettingCard;

    //this is where we log all the bets for this game
    struct bet {
        uint betAmount;
        bool betHome;
        address payable playerWallet;
    
    }
    
    function addBet(uint _betAmount, bool _betHome) private {
        betCount += 1;
        bettingCard[betCount] = bet(_betAmount, _betHome, payable(msg.sender));
        _betHome ? (sumHomeBets += _betAmount):(sumAwayBets += _betAmount);
        totalOfBets += _betAmount;
     
    }

    //gives the current payout ratio for home bets with 6 digits of precision (need to remove these on actual payout/display)
    function homeBetRatio() view public returns (uint){
        return ((totalOfBets/sumHomeBets));
    }
    
    //gives the current payout ratio for away bets with 6 digits of precision (need to remove these on actual payout/display)
    function awayBetRatio() view public returns (uint){
        return ((totalOfBets/sumAwayBets));
    }

    function betHome(uint _betAmount) public{
        require (!bettingFrozen, "bettingFrozen");
        require (_betAmount > minimumBet);
        transferFrom(_betAmount);
        addBet(_betAmount, true);
    }
    
    function betAway(uint _betAmount) public{
        require (!bettingFrozen, "bettingFrozen");
        require (_betAmount > minimumBet);
        transferFrom(_betAmount);
        addBet(_betAmount, false);
    }

    //the owner can toggle freezing bets
    function freezeBets() public onlyOwner returns (bool){
        (bettingFrozen ? bettingFrozen = false : bettingFrozen = true);
        return (bettingFrozen);
    }
    
    //the owner pays out all winners
    function payWinners(bool homeWin) public onlyOwner{
    //function payWinners(bool winnerHome) public onlyOwner{    
        
        //payouts for homeWinners
        if (homeWin){
            for(uint256 i = 1; i <= betCount; i++){
                if (bettingCard[i].betHome){ transferOut(bettingCard[i].playerWallet, calculatePayout(bettingCard[i].betAmount,homeWin)); }
             //emit Payouts(bettingCard[i].playerWallet, (bettingCard[i].betHome ? (calculatePayout(bettingCard[i].betAmount,homeWin)) : 0), bettingCard[i].betHome);
            }
        }
        
        //payouts for awayWinners
        if (!homeWin){
            for(uint256 i = 1; i <= betCount; i++){
                if (!bettingCard[i].betHome){ transferOut(bettingCard[i].playerWallet, calculatePayout(bettingCard[i].betAmount,homeWin)); }
             //emit Payouts(bettingCard[i].playerWallet, (!bettingCard[i].betHome ? (calculatePayout(bettingCard[i].betAmount,homeWin)) : 0), bettingCard[i].betHome);
            }
        }
        
        //cleanup
        //reset contract variables for next game
        betCount = 0;
        sumHomeBets = 0;
        sumAwayBets = 0;
        totalOfBets = 0;
        bettingFrozen = true;
        
    }
    
    //used for a tie or other problem
    function returnAllBets () public onlyOwner{
        for(uint256 i = 1; i <= betCount; i++){
            transferOut(bettingCard[i].playerWallet, bettingCard[i].betAmount);  
            
            //emit Payouts(bettingCard[i].playerWallet, bettingCard[i].betAmount, bettingCard[i].betHome);
        }
        
        //reset contract variables for next game
        betCount = 0;
        sumHomeBets = 0;
        sumAwayBets = 0;
        totalOfBets = 0;
        bettingFrozen = true;
    }
    
    //used by the payWinners function to calculate payouts
    function calculatePayout(uint wager, bool homeWin) view private returns (uint){
        return (wager * (homeWin ? homeBetRatio() : awayBetRatio()));
    }
    
    //for the token approval/xfer
    Token token = Token(chitContract);

    //used for transfering tokens back out
    function transferOut(address wallet, uint amount) private {
        token.transfer(wallet, amount);
    }

    //used to xfer wagers to the contract
    function transferFrom(uint amount) private {
        token.transferFrom(msg.sender, address(this), amount);
    }
    
    //for testing purposes
    function testing() view public returns (uint, uint, uint, uint){
        return(betCount, sumHomeBets, sumAwayBets, totalOfBets);
    }
}
