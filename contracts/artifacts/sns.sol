//handle decimals in stake , transfer etc, events

// batch airdrop
// multisig has to be geniric tpo change ownership to other multisig
//events on every action that involves an offchain action
// snapshotable

// change owner
// emergency ithdraw of erc20 and ether 
// see other erc20 ether payemebts (listed)

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol"; // needed? for staking

// p=opensea approve and sell, erc020 out of contrwact
/// @custom:security-contact zionverse@gmail.com
contract Sanskar is ERC20, ERC20Burnable, Pausable, Ownable, ERC20Snapshot {
    // using SafeMath for uint256;

    event Staked(address _from, uint256 _stake);
    event Unstaked(address _from, uint256 _stake);
    event RewardWithdrawn(address from, uint256 _reward);

    address[] internal stakeholders; // since we cant iterate on mapping to find all stakeholders// see how to avoid iteration
    
    //The stakes for each stakeholder.
    struct UserInfo {
        uint256 stakeAmount;
        uint256 lastRewardUpdatedTime; // Latest timestamp of reward updation
    }

    //Multiplier for Rewards
    uint256 multiplier = 10; // check multiplier getter function/ public?

    //Universal UserInfo Mapping
    mapping (address => UserInfo) StakeholdersInfo; // stakeholder -> info
   /**
    * @notice The accumulated rewards for each stakeholder.
    */
   mapping(address => uint256) internal rewards;

    constructor() ERC20("Sanskar", "SNR") {
        _mint(msg.sender, 10000 * 10 ** decimals()); // mint to owner
    }

    // batch transfer?🍔

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * 10 ** decimals());
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot) // multiple inheitence
    {
        super._beforeTokenTransfer(from, to, amount * 10 ** decimals()); // check
    }

    //---/---- batch -- be careful with the size of batch
    function batchmint(address[] memory to, uint256[] memory amounts) public onlyOwner { // be careful w the limits
        require(to.length == amounts.length);
        // address temp = 0xDa873c9A480e695e01b5478cd53F42F92C9d2a58; // owner 1
        for(uint256 i=0; i< to.length; i++){
            _mint(to[i], amounts[i] * 10 ** decimals()); // handle in dapp
        }
        
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function getsnapshotid() public  view returns (uint256){
        return _getCurrentSnapshotId();
    }

    function batch_transfer(address[] memory recipents, uint256[] memory amounts) public onlyOwner{
        require(recipents.length == amounts.length);
        for(uint256 i=0; i<amounts.length; i++){
            address owner = _msgSender();
            _transfer(owner, recipents[i], amounts[i] * 10 ** decimals()); // or should it be ** decimla?  for mint also

        }
    }
    // withdraw stuck erc20 on the contract
    function withdrawsanskar(uint256 amount) public onlyOwner{ // check visiblily or edge cases
        //cheecks
        _transfer(address(this), _msgSender(), amount * 10 ** decimals());
    }
    // burn on staking, no conflict, ddecouple so new staking mech can be deployed, reduce circulating supply

    
    function changeMultiplier( uint256 _newMultiplier)
    public
    onlyOwner
    {   
        distributeRewards();
        multiplier = _newMultiplier;
    }
    
    // staking unstaking etc-----------------------------------
    /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the stakeholders array.
    */
   function isStakeholder(address _address)
       public 
       view
       returns(bool, uint256)
   {
       //mapping
       for (uint256 s = 0; s < stakeholders.length; s += 1){ // avoid iteration check
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0); // check, or -1?
   }

   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address _stakeholder)
       internal //  check shouldnt be public ---------------------
   {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) stakeholders.push(_stakeholder);
   }

   /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    */
   function removeStakeholder(address _stakeholder)
       internal // check internal --------------------------
   {
       // check who can delete
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
       }
   }

   /**
    * @notice A method to retrieve the stake for a stakeholder.
    * @param _stakeholder The stakeholder to retrieve the stake for.
    * @return uint256 The amount of tokens staked.
    */
   function stakeOf(address _stakeholder)
       public
       view
       returns(uint256)
   {
       return StakeholdersInfo[_stakeholder].stakeAmount;
   }

   /**
    * @notice A method to the aggregated stakes from all stakeholders.
    * @return uint256 The aggregated stakes from all stakeholders.
    */
//    function totalStakes() // check omit this and instead update vafiable on the fly
//        public
//        view
//        returns(uint256)
//    {
//        uint256 _totalStakes = 0;
//        for (uint256 s = 0; s < stakeholders.length; s += 1){
//            _totalStakes = _totalStakes.add(stakes[stakeholders[s]]);
//        }
//        return _totalStakes;
//    }

    /**
    * @notice A method for a stakeholder to create a stake, pause will pause staking aswell
    * @param _stake The size of the stake to be created.
    */
   function createStake(uint256 _stake) // technically we can burn someome elses tokens, but shuld we?
       public
   {
       // add stake event
       // checks
       uint256 _stakeInDecimals = _stake * 10 ** decimals();
       _burn(msg.sender, _stakeInDecimals); // or burn?
    // _burn(temp, _stake);
       if(StakeholdersInfo[msg.sender].stakeAmount == 0) {
           addStakeholder(msg.sender);
        }
        else{
            //add rewards if already stakeholder present
            updateRewards(msg.sender);
            
        }

       StakeholdersInfo[msg.sender].stakeAmount = StakeholdersInfo[msg.sender].stakeAmount + _stakeInDecimals ;
       StakeholdersInfo[msg.sender].lastRewardUpdatedTime = block.timestamp;

       emit Staked(msg.sender, _stakeInDecimals); // check stake in decimals?
   }

   /**
    * @notice A method for a stakeholder to remove a stake.
    * @param _stake The size of the stake to be removed.
    */
   function removeStake(uint256 _stake)
       public // check or owneronly
   {
       // checks // check stakeof?
       // provide msg if he doesnt have stake?
       // check give rewards

        uint256 _stakeInDecimals = _stake * 10 ** decimals();

        updateRewards(msg.sender);
        StakeholdersInfo[msg.sender].stakeAmount = StakeholdersInfo[msg.sender].stakeAmount - _stakeInDecimals; // will automatically revert as uint cant store negative values
        

       if(StakeholdersInfo[msg.sender].stakeAmount == 0){
            removeStakeholder(msg.sender); // check if address isnt present
            //check update timestamp? s 
       }
       _mint(msg.sender, _stakeInDecimals);

       emit Unstaked(msg.sender, _stakeInDecimals);
   }

   // rewards

   // update rewards in the maping in 4 cases:
//    - the multiplier chages - all
//    - owner withdraws - ondemand
//    - owner staked more over already staked amount - ondemand
//    - distributes reward by contract owner - all
// remove stake
//
// compund stake rewards

    /**
    * @notice A simple method that calculates the rewards for each stakeholder since lastrewardypdatedtime
    * @param _stakeholder The stakeholder to calculate rewards for.
    */
   function calculateReward(address _stakeholder)
    //    public
       internal// or internal? check
       view
       returns(uint256)
   {
       uint256 timeInvested = block.timestamp - StakeholdersInfo[_stakeholder].lastRewardUpdatedTime;
       uint256 calculatedRewards = (StakeholdersInfo[_stakeholder].stakeAmount * timeInvested * multiplier/100)/(60*60*24*365);
    // uint256 calculatedRewards = (StakeholdersInfo[_stakeholder].stakeAmount * multiplier/100);
       return  calculatedRewards;
   }


    function updateRewards(address _stakeholder) // add reward and update timestamp
        internal // or private?
         // or not return
        {
            uint256 addReward = rewardOf(_stakeholder);
            rewards[_stakeholder] = addReward; //check
            StakeholdersInfo[_stakeholder].lastRewardUpdatedTime = block.timestamp;
            // return what?
        }
   /**
    * @notice A method to allow a stakeholder to check his unclaimed rewards.
    * @param _stakeholder The stakeholder to check rewards for.
    */
   function rewardOf(address _stakeholder) // unclaimed rewards
       public
       view
       returns(uint256)
   {
       // update rewards in the mapping and then return, check // no
       // cxalclulate the updated rewards and return the updated value but dont write it
       uint256 last_reward = calculateReward(_stakeholder);
       return rewards[_stakeholder] + last_reward;
   }
    
    // total rewards function?

    /**
    * @notice A method to distribute rewards to all stakeholders.
    */
   function distributeRewards()
       public
       onlyOwner
   { //check
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           address stakeholder = stakeholders[s];
        //    uint256 reward = calculateReward(stakeholder);
        //    rewards[stakeholder] = rewards[stakeholder].add(reward);
            updateRewards(stakeholder); // check if time shoudnt be updated
       }
   }

   /**
    * @notice A method to allow a stakeholder to withdraw his rewards.
    */
   function withdrawReward()
       public
   {    
       uint256 latest_reward = rewardOf(msg.sender);

    //    uint256 reward = rewards[msg.sender];
       rewards[msg.sender] = 0;
       StakeholdersInfo[msg.sender].lastRewardUpdatedTime = block.timestamp;
       // timestamp update, check
       _mint(msg.sender, latest_reward);
       
       emit RewardWithdrawn(msg.sender, latest_reward);
   }


}

// staking min amount,  see sxs, pyr
//public or not, access control
//partial unstakiing?
// someome can spam contract with staking 1 token of tons of account and congest contract, isstakeholder will be stuck
// burn to upgrde
//--
//role assign?, vice owner?
// on chain off chain, will affect multisig design
// multisig, sankar, web3 school deadlines

// --- misc
// pause message
// staking on pause?

// --------
// reward?
// axs - public,partial unstaking, claim/restake rewards, no min amount, claim once in 24 hours, reward same token
// pyr- not available yet, soft lock
// lava - no stake, found burn,
// punks(721) - diff contract, public

// ----
// some func on 1 calleed only by staking contect 2
// min stake variable
// variabale percentage rewards // document it, with date, confluence

// remove not very necessary features- snapshot?