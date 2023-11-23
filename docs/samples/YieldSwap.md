# YieldSwap









## Methods

### MINIMUM_LIQUIDITY

```solidity
function MINIMUM_LIQUIDITY() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### burn

```solidity
function burn(uint256 pairId, address to) external nonpayable returns (uint256 share0, uint256 share1)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pairId | uint256 | undefined |
| to | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| share0 | uint256 | undefined |
| share1 | uint256 | undefined |

### create

```solidity
function create(uint32 asset0, uint32 asset1) external nonpayable returns (uint256 pairId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| asset0 | uint32 | undefined |
| asset1 | uint32 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| pairId | uint256 | undefined |

### mint

```solidity
function mint(uint256 pairId, address to) external nonpayable returns (uint256 liquidity)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pairId | uint256 | undefined |
| to | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| liquidity | uint256 | undefined |

### pairLookup

```solidity
function pairLookup(uint256, uint256) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### pairs

```solidity
function pairs(uint256) external view returns (uint128 reserve0, uint128 reserve1, uint32 asset0, uint32 asset1, uint32 lpAssetId, uint256 kLast)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| reserve0 | uint128 | undefined |
| reserve1 | uint128 | undefined |
| asset0 | uint32 | undefined |
| asset1 | uint32 | undefined |
| lpAssetId | uint32 | undefined |
| kLast | uint256 | undefined |

### skim

```solidity
function skim(uint256 pairId, address to) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pairId | uint256 | undefined |
| to | address | undefined |

### swap

```solidity
function swap(uint256 pairId, uint256 share0Out, uint256 share1Out, address to) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pairId | uint256 | undefined |
| share0Out | uint256 | undefined |
| share1Out | uint256 | undefined |
| to | address | undefined |

### sync

```solidity
function sync(uint256 pairId) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| pairId | uint256 | undefined |

### yieldBox

```solidity
function yieldBox() external view returns (contract YieldBox)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract YieldBox | undefined |



## Events

### Burn

```solidity
event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | undefined |
| amount0  | uint256 | undefined |
| amount1  | uint256 | undefined |
| to `indexed` | address | undefined |

### Mint

```solidity
event Mint(address indexed sender, uint256 amount0, uint256 amount1)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | undefined |
| amount0  | uint256 | undefined |
| amount1  | uint256 | undefined |

### Swap

```solidity
event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| sender `indexed` | address | undefined |
| amount0In  | uint256 | undefined |
| amount1In  | uint256 | undefined |
| amount0Out  | uint256 | undefined |
| amount1Out  | uint256 | undefined |
| to `indexed` | address | undefined |

### Sync

```solidity
event Sync(uint112 reserve0, uint112 reserve1)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| reserve0  | uint112 | undefined |
| reserve1  | uint112 | undefined |



