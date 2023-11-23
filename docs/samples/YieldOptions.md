# YieldOptions









## Methods

### create

```solidity
function create(uint32 asset, uint32 currency, uint128 price, uint32 expiry) external nonpayable returns (uint256 optionId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| asset | uint32 | undefined |
| currency | uint32 | undefined |
| price | uint128 | undefined |
| expiry | uint32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| optionId | uint256 | undefined |

### exercise

```solidity
function exercise(uint256 optionId, uint256 amount) external nonpayable
```



*Exercise options.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId | uint256 | undefined |
| amount | uint256 | The amount to exercise expressed in units of currency. |

### mint

```solidity
function mint(uint256 optionId, uint256 amount, address optionTo, address minterTo) external nonpayable
```



*Mint options.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId | uint256 | undefined |
| amount | uint256 | The amount to mint expressed in units of currency. |
| optionTo | address | undefined |
| minterTo | address | undefined |

### options

```solidity
function options(uint256) external view returns (uint32 asset, uint32 currency, uint32 expiry, uint32 optionAssetId, uint32 minterAssetId, uint256 price)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| asset | uint32 | undefined |
| currency | uint32 | undefined |
| expiry | uint32 | undefined |
| optionAssetId | uint32 | undefined |
| minterAssetId | uint32 | undefined |
| price | uint256 | undefined |

### swap

```solidity
function swap(uint256 optionId, uint256 assetAmount, address to) external nonpayable
```



*If some of the options are exercised, but the price of the asset goes back up, anyone can swap the assets for the original currency. The main reason for this is that minted gets locked once any option is exercised. When all assets are swapped back for currency, further minting can happen again.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId | uint256 | undefined |
| assetAmount | uint256 | The amount to swap. This is denominated in asset (NOT currency!) so it&#39;s always possible to swap ALL assets, and rounding won&#39;t leave dust behind. |
| to | address | undefined |

### withdraw

```solidity
function withdraw(uint256 optionId, uint256 amount, address to) external nonpayable
```



*Withdraw from the pool. Asset and currency are withdrawn to the proportion in which they are exercised.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId | uint256 | undefined |
| amount | uint256 | The amount to withdraw expressed in units of the option. |
| to | address | undefined |

### withdrawEarly

```solidity
function withdrawEarly(uint256 optionId, uint256 amount, address to) external nonpayable
```



*Withdraw from the pool before expiry by returning the options. In this case Assets are withdrawn first if available. Only currency is returned if assets run to 0.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId | uint256 | undefined |
| amount | uint256 | The amount to withdraw expressed in units of the option. |
| to | address | undefined |

### yieldBox

```solidity
function yieldBox() external view returns (contract YieldBox)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract YieldBox | undefined |



## Events

### Exercise

```solidity
event Exercise(uint256 optionId, address indexed by, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId  | uint256 | undefined |
| by `indexed` | address | undefined |
| amount  | uint256 | undefined |

### Mint

```solidity
event Mint(uint256 optionId, address indexed by, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId  | uint256 | undefined |
| by `indexed` | address | undefined |
| amount  | uint256 | undefined |

### Swap

```solidity
event Swap(uint256 optionId, address indexed by, uint256 assetAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId  | uint256 | undefined |
| by `indexed` | address | undefined |
| assetAmount  | uint256 | undefined |

### Withdraw

```solidity
event Withdraw(uint256 optionId, address indexed by, uint256 amount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| optionId  | uint256 | undefined |
| by `indexed` | address | undefined |
| amount  | uint256 | undefined |



