# Escrow









## Methods

### cancel

```solidity
function cancel(uint256 offerId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| offerId | uint256 | undefined |

### make

```solidity
function make(uint256 assetFrom, uint256 assetTo, uint256 shareFrom, uint256 shareTo) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| assetFrom | uint256 | undefined |
| assetTo | uint256 | undefined |
| shareFrom | uint256 | undefined |
| shareTo | uint256 | undefined |

### offers

```solidity
function offers(uint256) external view returns (address owner, uint256 assetFrom, uint256 assetTo, uint256 shareFrom, uint256 shareTo, bool closed)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| owner | address | undefined |
| assetFrom | uint256 | undefined |
| assetTo | uint256 | undefined |
| shareFrom | uint256 | undefined |
| shareTo | uint256 | undefined |
| closed | bool | undefined |

### take

```solidity
function take(uint256 offerId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| offerId | uint256 | undefined |

### yieldBox

```solidity
function yieldBox() external view returns (contract YieldBox)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract YieldBox | undefined |




