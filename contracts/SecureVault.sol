// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// ============= I M P O R T S ================
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol";


/*
* title: Secure Vault.
* @author: Anthony (fps) https://github.com/fps8k .
* @dev: 
* 
* A safe vault, that allows the owner to deploy an dave some ether for some time.
*/

contract SecureVault
{
    // Using all the SafeMath for all uint256 calculations.
    using SafeMath for uint256;

    // Owner of the contract.
    address payable immutable owner;

    // Total money in the contract storage.
    uint256 private total_funds;

    // Default timespan constant for Rinkeby.
    uint256 constant DEFAULT_DURATION = 7 days;

    // Default timespan for Ganache.
    // uint256 constant DEFAULT_DURATION = 60 seconds;

    // Variable time for the user to add to the contract;
    uint256 public duration;

    // Variable for re-entrancty attack check.
    bool locked = false;



    // ==================  E V E N T S ===========================

    // Emitted when the contract is initially deployed.
    event CreateVault(address indexed __owner, uint256 indexed __time);

    // Emitted when new money is added into the vault.
    event DepositToVault(address indexed __owner, uint256 indexed __amount);

    // Emitted when the owner prolongs the vault duration by some seconds.
    event ProlongVault(address indexed __owner, uint256 indexed __time);

    // Emitted when the owner withdraws money from the vault.
    event WithdrawFromVault(address indexed __owner, uint256 indexed __amount);

    // Emitted when the vault is destroyed.
    event DestroyVault(address indexed _owner, uint256 indexed __time);

    // ==================  E V E N T S ===========================



    // ==================== M O D I F I E R S ======================

    // Makes sure that only the owner can call the function.
    modifier onlyOwner()
    {
        require(msg.sender == owner, "!Owner");
        _;
    }

    // Checks for Re-Entrancy.
    modifier noReEntrance()
    {
        // Makes sure the locked is false.
        require(!locked, "No ReEntrance");

        // Sets the locked to true so that a new entrance breaks on line 70.
        locked = true;
        _;

        // Change locked back to false after the function is through with execution.
        locked = false;
    }

    // ==================== M O D I F I E R S ======================



    // ==================== F A L L B A C K   A N D   R E C E I V E ========================

    fallback() external payable {}
    receive() external payable {}

    // ==================== F A L L B A C K   A N D   R E C E I V E ========================
    


    /*
    * @dev:
    *
    * Initialize the owner of the contract, only the owner can store ether here.
    */
    constructor()
    {
        // Assign the owner to whoever deploys the contract.
        owner = payable(msg.sender);

        // Emit the CreateVault event.
        emit CreateVault(msg.sender, block.timestamp);
    }



    /*
    * @dev:
    *
    * Adds more funds to the vault, this increases the vaults duration by some time, the default duration.
    */
    function deposit() public payable onlyOwner
    {
        // Use SafeMath to add the msg.value to the total_funds.
        total_funds = total_funds.add(msg.value);

        // Pushes the duration by the default duration.
        duration = block.timestamp.add(DEFAULT_DURATION);

        // Emit the DepositToVault event.
        emit DepositToVault(owner, msg.value);

        // Emit the ProlongVault event.
        emit ProlongVault(owner, DEFAULT_DURATION);
    }



    /*
    * @dev:
    *
    * Withdraws some amount from the vault.
    *
    *
    * @param
    */
    function withdrawSome(uint256 __withdraw_amount) public onlyOwner noReEntrance
    {
        // Check the time and make sure that the current time has passed the time.
        require(block.timestamp >= duration, "Time is not yet up");

        // Make sure that the amount is greater than 0.
        require(__withdraw_amount > 0, "Amount <= 0");

        // Makes sure that the amount to withdraw is less than the total funds in the contract.
        require(__withdraw_amount <= total_funds, "Amount > Total funds");

        // Hold the total funds in a memory storage for validation.
        uint256 total_funds_validator = total_funds;

        // Remove the value from the total funds in the contract.
        total_funds = total_funds.sub(__withdraw_amount);

        // Send the value to the  owner of the contract.
        // Since msg.sender == owner and is payable.
        owner.transfer(__withdraw_amount);

        // Assert that the total_funds have changed.
        // After every transfer, the total funds will be lower than the initial storage of the total funds validator.
        assert(total_funds < total_funds_validator);

        // Emit the WithdrawFromVault event.
        emit WithdrawFromVault(owner, __withdraw_amount);
    }



    /*
    * @dev:
    *
    * Withdraws all the money in the contract and makes sure that the contract's total funds.
    */
    function withdrawAll() public onlyOwner noReEntrance
    {
        // Check the time and make sure that the current time has passed the time.
        require(block.timestamp >= duration, "Time is not yet up");

        // Makes sure that the account is not empty.
        require(total_funds > 0, "Total funds == 0");

        // Hold the total funds in a memory storage for validation.
        uint256 stored_total_funds = total_funds;

        // Remove the value from the total funds in the contract.
        total_funds = total_funds.sub(stored_total_funds);

        // Send the value to the  owner of the contract.
        // Since msg.sender == owner and is payable.
        owner.transfer(stored_total_funds);

        // Assert that the total_funds have changed and is now == 0.
        assert(total_funds == 0);

        // Emit the WithdrawFromVault event.
        emit WithdrawFromVault(owner, stored_total_funds);
    }



    /*
    * dev:
    *
    * Destroys the vault.
    */
    function destroyVault() public onlyOwner
    {
        // Pay the owner and destroy.
        selfdestruct(owner);
    }
}