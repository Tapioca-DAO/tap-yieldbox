# MasterContractFullCycleMock









## Methods

### deployer

```solidity
function deployer() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### erc1155

```solidity
function erc1155() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### erc1155Strategy

```solidity
function erc1155Strategy() external view returns (contract IStrategy)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStrategy | undefined |

### ethStrategy

```solidity
function ethStrategy() external view returns (contract IStrategy)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStrategy | undefined |

### init

```solidity
function init(bytes data) external payable
```

Init function that gets called from `BoringFactory.deploy`. Also kown as the constructor for cloned contracts. Any ETH send to `BoringFactory.deploy` ends up here.



#### Parameters

| Name | Type | Description |
|---|---|---|
| data | bytes | Can be abi encoded arguments or anything else. |

### run

```solidity
function run() external payable
```






### token

```solidity
function token() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### tokenStrategy

```solidity
function tokenStrategy() external view returns (contract IStrategy)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract IStrategy | undefined |

### yieldBox

```solidity
function yieldBox() external view returns (contract YieldBox)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | contract YieldBox | undefined |




