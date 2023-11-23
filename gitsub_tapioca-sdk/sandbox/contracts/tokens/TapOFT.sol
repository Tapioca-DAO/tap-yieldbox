// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "tapioca-sdk/dist/contracts/interfaces/ILayerZeroEndpoint.sol";
import {BaseBoringBatchable} from "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "tapioca-sdk/dist/contracts/token/oft/v2/OFTV2.sol";
import "tapioca-sdk/dist/contracts/libraries/LzLib.sol";

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title Tapioca OFT token
/// @notice OFT compatible TAP token
/// @dev Latest size: 17.663  KiB
/// @dev Emissions E(x)= E(x-1) - E(x-1) * D with E being total supply a x week, and D the initial decay rate
contract TapOFT is OFTV2, ERC20Permit, BaseBoringBatchable {
    using ExcessivelySafeCall for address;
    using BytesLib for bytes;

    // ==========
    // *DATA*
    // ==========

    //  Allocation:
    // =========
    // * DSO: 56.5m
    // * DAO: 10m
    // * Contributors: 15m
    // * Investors: 11m
    // * LBP: 5m
    // * Airdrop: 2.5m
    // == 100M ==
    uint256 public constant INITIAL_SUPPLY = 43_500_000 * 1e18; // Everything minus DSO
    uint256 public dso_supply = 56_500_000 * 1e18;

    /// @notice the a parameter used in the emission function;
    uint256 constant decay_rate = 8800000000000000; // 0.88%
    uint256 constant DECAY_RATE_DECIMAL = 1e18;

    /// @notice seconds in a week
    uint256 public constant WEEK = 604800;

    /// @notice starts time for emissions
    /// @dev initialized in the constructor with block.timestamp
    uint256 public immutable emissionsStartTime;

    /// @notice returns the amount of emitted TAP for a specific week
    /// @dev week is computed using (timestamp - emissionStartTime) / WEEK
    mapping(uint256 => uint256) public emissionForWeek;

    /// @notice returns the amount minted for a specific week
    /// @dev week is computed using (timestamp - emissionStartTime) / WEEK
    mapping(uint256 => uint256) public mintedInWeek;

    /// @notice returns the minter address
    address public minter;

    /// @notice LayerZero governance chain identifier
    uint256 public governanceChainIdentifier;

    /// @notice returns the pause state of the contract
    bool public paused;

    // ==========
    // *EVENTS*
    // ==========
    /// @notice event emitted when a new minter is set
    event MinterUpdated(address indexed _old, address indexed _new);
    /// @notice event emitted when a new emission is called
    event Emitted(uint256 week, uint256 amount);
    /// @notice event emitted when new TAP is minted
    event Minted(address indexed _by, address indexed _to, uint256 _amount);
    /// @notice event emitted when new TAP is burned
    event Burned(address indexed _from, uint256 _amount);
    /// @notice event emitted when the governance chain identifier is updated
    event GovernanceChainIdentifierUpdated(uint256 _old, uint256 _new);
    /// @notice event emitted when pause state is changed
    event PausedUpdated(bool oldState, bool newState);

    modifier notPaused() {
        require(!paused, "TAP: paused");
        _;
    }

    // ==========
    // * METHODS *
    // ==========
    /// @notice Creates a new TAP OFT type token
    /// @dev The initial supply of 100M is not minted here as we have the wrap method
    /// @param _lzEndpoint the layer zero address endpoint deployed on the current chain
    /// @param _contributors address of the  contributors
    /// @param _investors address of investors
    /// @param _lbp address of the LBP
    /// @param _dao address of the DAO
    /// @param _airdrop address of the airdrop contract
    /// @param _governanceChainId LayerZero governance chain identifier
    /// @param _conservator address of the conservator/owner
    constructor(
        address _lzEndpoint,
        address _contributors,
        address _investors,
        address _lbp,
        address _dao,
        address _airdrop,
        uint16 _governanceChainId,
        address _conservator
    ) OFTV2("Tapioca", "TAP", 8, _lzEndpoint) ERC20Permit("Tapioca") {
        require(_lzEndpoint != address(0), "LZ endpoint not valid");
        governanceChainIdentifier = _governanceChainId;
        if (_getChainId() == governanceChainIdentifier) {
            _mint(_contributors, 1e18 * 15_000_000);
            _mint(_investors, 1e18 * 11_000_000);
            _mint(_lbp, 1e18 * 5_000_000);
            _mint(_dao, 1e18 * 10_000_000);
            _mint(_airdrop, 1e18 * 2_500_000);
            require(
                totalSupply() == INITIAL_SUPPLY,
                "initial supply not valid"
            );
        }
        emissionsStartTime = block.timestamp;

        transferOwnership(_conservator);
    }

    ///-- Owner methods --
    /// @notice sets the governance chain identifier
    /// @param _identifier LayerZero chain identifier
    function setGovernanceChainIdentifier(
        uint256 _identifier
    ) external onlyOwner {
        emit GovernanceChainIdentifierUpdated(
            governanceChainIdentifier,
            _identifier
        );
        governanceChainIdentifier = _identifier;
    }

    /// @notice updates the pause state of the contract
    /// @param val the new value
    function updatePause(bool val) external onlyOwner {
        require(val != paused, "TAP: same state");
        emit PausedUpdated(paused, val);
        paused = val;
    }

    /// @notice sets a new minter address
    /// @param _minter the new address
    function setMinter(address _minter) external onlyOwner {
        require(_minter != address(0), "address not valid");
        emit MinterUpdated(minter, _minter);
        minter = _minter;
    }

    //-- View methods --
    /// @notice returns token's decimals
    function decimals() public pure override returns (uint8) {
        return 18;
    }

    /// @notice Returns the current week given a timestamp
    function timestampToWeek(
        uint256 timestamp
    ) external view returns (uint256) {
        if (timestamp == 0) {
            timestamp = block.timestamp;
        }
        if (timestamp < emissionsStartTime) return 0;

        return _timestampToWeek(timestamp);
    }

    /// @notice Returns the current week
    function getCurrentWeek() external view returns (uint256) {
        return _timestampToWeek(block.timestamp);
    }

    /// @notice Returns the current week emission
    function getCurrentWeekEmission() external view returns (uint256) {
        return emissionForWeek[_timestampToWeek(block.timestamp)];
    }

    ///-- Write methods --
    /// @notice Emit the TAP for the current week
    function emitForWeek() external notPaused returns (uint256) {
        require(_getChainId() == governanceChainIdentifier, "chain not valid");

        uint256 week = _timestampToWeek(block.timestamp);
        if (emissionForWeek[week] > 0) return 0;

        // Update DSO supply from last minted emissions
        dso_supply -= mintedInWeek[week - 1];

        // Compute unclaimed emission from last week and add it to the current week emission
        uint256 unclaimed = emissionForWeek[week - 1] - mintedInWeek[week - 1];
        uint256 emission = uint256(_computeEmission());
        emission += unclaimed;
        emissionForWeek[week] = emission;

        emit Emitted(week, emission);

        return emission;
    }

    /// @notice extracts from the minted TAP
    /// @param _to Address to send the minted TAP to
    /// @param _amount TAP amount
    function extractTAP(address _to, uint256 _amount) external notPaused {
        require(msg.sender == minter, "unauthorized");
        require(_amount > 0, "amount not valid");

        uint256 week = _timestampToWeek(block.timestamp);
        require(emissionForWeek[week] >= _amount, "exceeds allowable amount");
        _mint(_to, _amount);
        mintedInWeek[week] += _amount;
        emit Minted(msg.sender, _to, _amount);
    }

    /// @notice burns TAP
    /// @param _amount TAP amount
    function removeTAP(uint256 _amount) external notPaused {
        _burn(msg.sender, _amount);
        emit Burned(msg.sender, _amount);
    }

    ///-- Internal methods --
    function _timestampToWeek(
        uint256 timestamp
    ) internal view returns (uint256) {
        return ((timestamp - emissionsStartTime) / WEEK) + 1; // Starts at week 1
    }

    ///-- Private methods --
    /// @notice Return the current chain ID.
    /// @dev Useful for testing.
    function _getChainId() private view returns (uint256) {
        return block.chainid;
    }

    /// @notice returns the available emissions for a given supply
    function _computeEmission() internal view returns (uint256 result) {
        result = (dso_supply * decay_rate) / DECAY_RATE_DECIMAL;
    }
}
