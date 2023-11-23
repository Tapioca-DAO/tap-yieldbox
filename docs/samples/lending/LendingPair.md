# LendingPair



> LendingPair





## Methods

### accrue

```solidity
function accrue(uint256 marketId) external nonpayable
```

Accrues the interest on the borrowed tokens.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | undefined |

### addAsset

```solidity
function addAsset(uint256 marketId, address to, uint256 share) external nonpayable returns (uint256 fraction)
```

Adds assets to the lending pair.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | undefined |
| to | address | The address of the user to receive the assets. |
| share | uint256 | The amount of shares to add. |

#### Returns

| Name | Type | Description |
|---|---|---|
| fraction | uint256 | Total fractions added. |

### addCollateral

```solidity
function addCollateral(uint256 marketId, address to, uint256 share) external nonpayable
```

Adds `collateral` from msg.sender to the account `to`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | The id of the market. |
| to | address | The receiver of the tokens. |
| share | uint256 | The amount of shares to add for `to`. |

### borrow

```solidity
function borrow(uint256 marketId, address to, uint256 amount) external nonpayable returns (uint256 part, uint256 share)
```

Sender borrows `amount` and transfers it to `to`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | undefined |
| to | address | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| part | uint256 | Total part of the debt held by borrowers. |
| share | uint256 | Total amount in shares borrowed. |

### createMarket

```solidity
function createMarket(uint32 collateral_, uint32 asset_, contract IOracle oracle_, bytes oracleData_) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| collateral_ | uint32 | undefined |
| asset_ | uint32 | undefined |
| oracle_ | contract IOracle | undefined |
| oracleData_ | bytes | undefined |

### init

```solidity
function init(bytes) external payable
```

No clones are used



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | bytes | undefined |

### liquidate

```solidity
function liquidate(uint256 marketId, address user, uint256 maxBorrowPart, address to, contract ISwapper swapper) external nonpayable
```

Handles the liquidation of users&#39; balances, once the users&#39; amount of collateral is too low.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | undefined |
| user | address | The user to liquidate. |
| maxBorrowPart | uint256 | Maximum (partial) borrow amounts to liquidate. |
| to | address | Address of the receiver if `swapper` is zero. |
| swapper | contract ISwapper | Contract address of the `ISwapper` implementation. |

### marketList

```solidity
function marketList(uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### markets

```solidity
function markets(uint256) external view returns (uint32 collateral, uint32 asset, contract IOracle oracle, bytes oracleData, uint256 totalCollateralShare, uint256 totalAssetShares, struct Rebase totalBorrow, uint256 exchangeRate, uint64 interestPerSecond, uint64 lastAccrued, uint32 assetId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| collateral | uint32 | undefined |
| asset | uint32 | undefined |
| oracle | contract IOracle | undefined |
| oracleData | bytes | undefined |
| totalCollateralShare | uint256 | undefined |
| totalAssetShares | uint256 | undefined |
| totalBorrow | Rebase | undefined |
| exchangeRate | uint256 | undefined |
| interestPerSecond | uint64 | undefined |
| lastAccrued | uint64 | undefined |
| assetId | uint32 | undefined |

### masterContract

```solidity
function masterContract() external view returns (contract LendingPair)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract LendingPair | undefined |

### removeAsset

```solidity
function removeAsset(uint256 marketId, address to, uint256 fraction) external nonpayable returns (uint256 share)
```

Removes an asset from msg.sender and transfers it to `to`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | undefined |
| to | address | The user that receives the removed assets. |
| fraction | uint256 | The amount/fraction of assets held to remove. |

#### Returns

| Name | Type | Description |
|---|---|---|
| share | uint256 | The amount of shares transferred to `to`. |

### removeCollateral

```solidity
function removeCollateral(uint256 marketId, address to, uint256 share) external nonpayable
```

Removes `share` amount of collateral and transfers it to `to`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | undefined |
| to | address | The receiver of the shares. |
| share | uint256 | Amount of shares to remove. |

### repay

```solidity
function repay(uint256 marketId, address to, uint256 part) external nonpayable returns (uint256 amount)
```

Repays a loan.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | undefined |
| to | address | Address of the user this payment should go. |
| part | uint256 | The amount to repay. See `userBorrowPart`. |

#### Returns

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The total amount repayed. |

### updateExchangeRate

```solidity
function updateExchangeRate(uint256 marketId) external nonpayable returns (bool updated, uint256 rate)
```

Gets the exchange rate. I.e how much collateral to buy 1e18 asset. This function is supposed to be invoked if needed because Oracle queries can be expensive.



#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| updated | bool | True if `exchangeRate` was updated. |
| rate | uint256 | The new exchange rate. |

### yieldBox

```solidity
function yieldBox() external view returns (contract YieldBox)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract YieldBox | undefined |



## Events

### LogAccrue

```solidity
event LogAccrue(uint256 accruedAmount, uint64 rate, uint256 utilization)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| accruedAmount  | uint256 | undefined |
| rate  | uint64 | undefined |
| utilization  | uint256 | undefined |

### LogAddAsset

```solidity
event LogAddAsset(address indexed from, address indexed to, uint256 share, uint256 fraction)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| share  | uint256 | undefined |
| fraction  | uint256 | undefined |

### LogAddCollateral

```solidity
event LogAddCollateral(address indexed from, address indexed to, uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| share  | uint256 | undefined |

### LogBorrow

```solidity
event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| amount  | uint256 | undefined |
| part  | uint256 | undefined |

### LogExchangeRate

```solidity
event LogExchangeRate(uint256 rate)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| rate  | uint256 | undefined |

### LogLiquidate

```solidity
event LogLiquidate(uint256 indexed marketId, address indexed user, uint256 borrowPart, address to, contract ISwapper swapper)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| marketId `indexed` | uint256 | undefined |
| user `indexed` | address | undefined |
| borrowPart  | uint256 | undefined |
| to  | address | undefined |
| swapper  | contract ISwapper | undefined |

### LogRemoveAsset

```solidity
event LogRemoveAsset(address indexed from, address indexed to, uint256 share, uint256 fraction)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| share  | uint256 | undefined |
| fraction  | uint256 | undefined |

### LogRemoveCollateral

```solidity
event LogRemoveCollateral(address indexed from, address indexed to, uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| share  | uint256 | undefined |

### LogRepay

```solidity
event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| from `indexed` | address | undefined |
| to `indexed` | address | undefined |
| amount  | uint256 | undefined |
| part  | uint256 | undefined |



