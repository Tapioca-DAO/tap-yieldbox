# Salary









## Methods

### available

```solidity
function available(uint256 salaryId) external view returns (uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| salaryId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| share | uint256 | undefined |

### batch

```solidity
function batch(bytes[] calls, bool revertOnFail) external payable
```

Allows batched call to self (this contract).



#### Parameters

| Name | Type | Description |
|---|---|---|
| calls | bytes[] | An array of inputs for each call. |
| revertOnFail | bool | If True then reverts after a failed call and stops doing further calls. |

### cancel

```solidity
function cancel(uint256 salaryId, address to) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| salaryId | uint256 | undefined |
| to | address | undefined |

### create

```solidity
function create(address recipient, uint256 assetId, uint32 cliffTimestamp, uint32 endTimestamp, uint32 cliffPercent, uint128 amount) external nonpayable returns (uint256 salaryId, uint256 share)
```

Create a salary



#### Parameters

| Name | Type | Description |
|---|---|---|
| recipient | address | undefined |
| assetId | uint256 | undefined |
| cliffTimestamp | uint32 | undefined |
| endTimestamp | uint32 | undefined |
| cliffPercent | uint32 | undefined |
| amount | uint128 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| salaryId | uint256 | undefined |
| share | uint256 | undefined |

### info

```solidity
function info(uint256 salaryId) external view returns (address funder, address recipient, uint256 assetId, uint256 withdrawnAmount, uint32 cliffTimestamp, uint32 endTimestamp, uint64 cliffPercent, uint256 amount, uint256 availableAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| salaryId | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| funder | address | undefined |
| recipient | address | undefined |
| assetId | uint256 | undefined |
| withdrawnAmount | uint256 | undefined |
| cliffTimestamp | uint32 | undefined |
| endTimestamp | uint32 | undefined |
| cliffPercent | uint64 | undefined |
| amount | uint256 | undefined |
| availableAmount | uint256 | undefined |

### permitToken

```solidity
function permitToken(contract IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external nonpayable
```

Call wrapper that performs `ERC20.permit` on `token`. Lookup `IERC20.permit`.



#### Parameters

| Name | Type | Description |
|---|---|---|
| token | contract IERC20 | undefined |
| from | address | undefined |
| to | address | undefined |
| amount | uint256 | undefined |
| deadline | uint256 | undefined |
| v | uint8 | undefined |
| r | bytes32 | undefined |
| s | bytes32 | undefined |

### salaries

```solidity
function salaries(uint256) external view returns (address funder, address recipient, uint256 assetId, uint256 withdrawnShare, uint32 cliffTimestamp, uint32 endTimestamp, uint64 cliffPercent, uint256 share)
```

Array of all salaries managed by the contract



#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| funder | address | undefined |
| recipient | address | undefined |
| assetId | uint256 | undefined |
| withdrawnShare | uint256 | undefined |
| cliffTimestamp | uint32 | undefined |
| endTimestamp | uint32 | undefined |
| cliffPercent | uint64 | undefined |
| share | uint256 | undefined |

### salaryCount

```solidity
function salaryCount() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### withdraw

```solidity
function withdraw(uint256 salaryId, address to) external nonpayable
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| salaryId | uint256 | undefined |
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

### LogCancel

```solidity
event LogCancel(uint256 indexed salaryId, address indexed to, uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| salaryId `indexed` | uint256 | undefined |
| to `indexed` | address | undefined |
| share  | uint256 | undefined |

### LogCreate

```solidity
event LogCreate(address indexed funder, address indexed recipient, uint256 indexed assetId, uint32 cliffTimestamp, uint32 endTimestamp, uint32 cliffPercent, uint256 totalShare, uint256 salaryId)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| funder `indexed` | address | undefined |
| recipient `indexed` | address | undefined |
| assetId `indexed` | uint256 | undefined |
| cliffTimestamp  | uint32 | undefined |
| endTimestamp  | uint32 | undefined |
| cliffPercent  | uint32 | undefined |
| totalShare  | uint256 | undefined |
| salaryId  | uint256 | undefined |

### LogWithdraw

```solidity
event LogWithdraw(uint256 indexed salaryId, address indexed to, uint256 share)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| salaryId `indexed` | uint256 | undefined |
| to `indexed` | address | undefined |
| share  | uint256 | undefined |



