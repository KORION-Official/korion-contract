
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract KORIONToken {
    // --------------------------------------------------
    // Fixed Treasury Address (Multisig)
    // Base58: TSM7ocJQHigW9jhk5yFQKrUmBAXz2FFapa
    // --------------------------------------------------
    address public constant FIXED_TREASURY =
        0xB3A6d33b4C5E74014009B3dB57C9E5eb8e40c9b9;

    // --------------------------------------------------
    // Fixed allocation addresses
    // --------------------------------------------------

    // Cold Wallet (Multisig) - 50%
    // Base58: TWbuSkkRid1st9gSMy1NhpK1KwJMebHNwh
    address public constant FIXED_COLD_WALLET =
        0xE253401d436dDd3Efb2D65B8383027940C676639;

    // Reward Wallet (Multisig) - 23%
    // Base58: TCFD5eZAXGdA8ud4ZH2Dt6cZdeGRFYSiaH
    address public constant FIXED_REWARD_WALLET =
        0x18f6F917010D3420560077E9f034021504Ee3574;

    // Liquidity Wallet (Multisig) - 20%
    // Base58: TLkgBr1vwpkdenM3LZq2hzb33TbCzBYDE3
    address public constant FIXED_LIQUIDITY_WALLET =
        0x764aAB7a283C3b53c5ddB7D31b73d6262AA67347;

    // Marketing Wallet (Regular Wallet) - 4%
    // Base58: TMCUdq7BfaTRCdzUvYmuVoKnjZssYqnJ3s
    address public constant FIXED_MARKETING_WALLET =
        0x7B2Bd77aF42fF4534c604C83b8a0DCB345956CF6;

    // Hot Wallet (Regular Wallet) - 3%
    // Base58: TYKL8DPoR99bccujHXxcyBewCV1NimdRc8
    address public constant FIXED_HOT_WALLET =
        0xf52108638f7118b34c3B0aB7512F33C64248D686;

    // --------------------------------------------------
    // Token basic info
    // --------------------------------------------------
    string public constant name = "KORION";
    string public constant symbol = "KORI";
    uint8 public constant decimals = 6;

    // --------------------------------------------------
    // Supply
    // --------------------------------------------------
    uint256 public constant INITIAL_SUPPLY = 10_000_000_000 * 10**6; // 100억
    uint256 public totalSupply = INITIAL_SUPPLY;

    // Initial distribution amounts (always based on INITIAL_SUPPLY)
    uint256 public constant COLD_ALLOCATION = (INITIAL_SUPPLY * 50) / 100;      // 50%
    uint256 public constant REWARD_ALLOCATION = (INITIAL_SUPPLY * 23) / 100;    // 23%
    uint256 public constant LIQUIDITY_ALLOCATION = (INITIAL_SUPPLY * 20) / 100; // 20%
    uint256 public constant MARKETING_ALLOCATION = (INITIAL_SUPPLY * 4) / 100;  // 4%
    uint256 public constant HOT_ALLOCATION = (INITIAL_SUPPLY * 3) / 100;        // 3%

    // --------------------------------------------------
    // Owner / Treasury
    // owner와 treasury는 항상 같은 주소로 운영
    // --------------------------------------------------
    address public owner;
    address public treasury;

    // --------------------------------------------------
    // ERC20 storage
    // --------------------------------------------------
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // --------------------------------------------------
    // Control flags
    // --------------------------------------------------
    bool public transferEnabled = true;
    bool public mintEnabled = true;
    bool public initialDistributionDone = false;

    // --------------------------------------------------
    // Initial allocation addresses
    // --------------------------------------------------
    address public coldWallet;
    address public rewardWallet;
    address public liquidityWallet;
    address public marketingWallet;
    address public hotWallet;

    // --------------------------------------------------
    // Events
    // --------------------------------------------------
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TreasuryUpdated(address indexed previousTreasury, address indexed newTreasury);

    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);

    event TransferStatusChanged(bool enabled);
    event MintStatusChanged(bool enabled);

    event InitialDistributionExecuted(
        address indexed coldWallet,
        address indexed rewardWallet,
        address indexed liquidityWallet,
        address marketingWallet,
        address hotWallet
    );

    // --------------------------------------------------
    // Modifiers
    // --------------------------------------------------
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier validAddress(address account) {
        require(account != address(0), "Zero address not allowed");
        _;
    }

    // --------------------------------------------------
    // Constructor
    // 배포 시 constructor 입력 필요 없음
    // 초기 100억 KORI는 FIXED_TREASURY로 들어감
    // --------------------------------------------------
    constructor() {
        owner = FIXED_TREASURY;
        treasury = FIXED_TREASURY;

        balances[FIXED_TREASURY] = INITIAL_SUPPLY;

        emit OwnershipTransferred(address(0), FIXED_TREASURY);
        emit TreasuryUpdated(address(0), FIXED_TREASURY);
        emit Transfer(address(0), FIXED_TREASURY, INITIAL_SUPPLY);
    }

    // --------------------------------------------------
    // Read functions
    // --------------------------------------------------
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function allowance(address tokenOwner, address spender) external view returns (uint256) {
        return allowances[tokenOwner][spender];
    }

    // --------------------------------------------------
    // ERC20 transfer functions
    // --------------------------------------------------
    function transfer(address to, uint256 amount)
        external
        validAddress(to)
        returns (bool)
    {
        require(transferEnabled, "Transfers are disabled");
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        validAddress(spender)
        returns (bool)
    {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount)
        external
        validAddress(from)
        validAddress(to)
        returns (bool)
    {
        require(transferEnabled, "Transfers are disabled");

        uint256 currentAllowance = allowances[from][msg.sender];
        require(currentAllowance >= amount, "Allowance exceeded");

        allowances[from][msg.sender] = currentAllowance - amount;
        emit Approval(from, msg.sender, allowances[from][msg.sender]);

        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
        validAddress(spender)
        returns (bool)
    {
        allowances[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        validAddress(spender)
        returns (bool)
    {
        uint256 currentAllowance = allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased below zero");

        allowances[msg.sender][spender] = currentAllowance - subtractedValue;
        emit Approval(msg.sender, spender, allowances[msg.sender][spender]);
        return true;
    }

    // --------------------------------------------------
    // Internal transfer
    // --------------------------------------------------
    function _transfer(address from, address to, uint256 amount) internal {
        require(balances[from] >= amount, "Insufficient balance");

        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    // --------------------------------------------------
    // Initial distribution
    // 50% Cold (Multisig)
    // 23% Reward (Multisig)
    // 20% Liquidity (Multisig)
    // 4% Marketing (Regular Wallet)
    // 3% Hot (Regular Wallet)
    //
    // 초기 100억 기준으로 한 번만 분배
    // 주소 입력 없이 고정 주소로 분배
    // --------------------------------------------------
    function initialDistribute() external onlyOwner returns (bool) {
        require(!initialDistributionDone, "Initial distribution already done");

        coldWallet = FIXED_COLD_WALLET;
        rewardWallet = FIXED_REWARD_WALLET;
        liquidityWallet = FIXED_LIQUIDITY_WALLET;
        marketingWallet = FIXED_MARKETING_WALLET;
        hotWallet = FIXED_HOT_WALLET;

        require(
            COLD_ALLOCATION +
                REWARD_ALLOCATION +
                LIQUIDITY_ALLOCATION +
                MARKETING_ALLOCATION +
                HOT_ALLOCATION ==
                INITIAL_SUPPLY,
            "Distribution mismatch"
        );

        require(balances[treasury] >= INITIAL_SUPPLY, "Treasury balance insufficient");

        _transfer(treasury, FIXED_COLD_WALLET, COLD_ALLOCATION);
        _transfer(treasury, FIXED_REWARD_WALLET, REWARD_ALLOCATION);
        _transfer(treasury, FIXED_LIQUIDITY_WALLET, LIQUIDITY_ALLOCATION);
        _transfer(treasury, FIXED_MARKETING_WALLET, MARKETING_ALLOCATION);
        _transfer(treasury, FIXED_HOT_WALLET, HOT_ALLOCATION);

        initialDistributionDone = true;

        emit InitialDistributionExecuted(
            FIXED_COLD_WALLET,
            FIXED_REWARD_WALLET,
            FIXED_LIQUIDITY_WALLET,
            FIXED_MARKETING_WALLET,
            FIXED_HOT_WALLET
        );

        return true;
    }

    // --------------------------------------------------
    // Mint
    // Treasury(owner) only
    // --------------------------------------------------
    function mint(address to, uint256 amount)
        external
        onlyOwner
        validAddress(to)
        returns (bool)
    {
        require(mintEnabled, "Minting disabled");

        totalSupply += amount;
        balances[to] += amount;

        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
        return true;
    }

    // --------------------------------------------------
    // Burn
    // Treasury(owner) burns its own balance
    // --------------------------------------------------
    function burn(uint256 amount) external onlyOwner returns (bool) {
        require(balances[msg.sender] >= amount, "Insufficient owner balance");

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    // --------------------------------------------------
    // Burn from another address if approved
    // 실무에서는 보통:
    // 다른지갑 -> Treasury 전송 -> burn()
    // --------------------------------------------------
    function burnFrom(address from, uint256 amount)
        external
        onlyOwner
        validAddress(from)
        returns (bool)
    {
        uint256 currentAllowance = allowances[from][msg.sender];
        require(currentAllowance >= amount, "Allowance exceeded");
        require(balances[from] >= amount, "Insufficient balance");

        allowances[from][msg.sender] = currentAllowance - amount;
        balances[from] -= amount;
        totalSupply -= amount;

        emit Approval(from, msg.sender, allowances[from][msg.sender]);
        emit Burn(from, amount);
        emit Transfer(from, address(0), amount);
        return true;
    }

    // --------------------------------------------------
    // Admin functions
    // owner와 treasury를 항상 같이 변경
    // --------------------------------------------------
    function transferOwnership(address newOwner)
        external
        onlyOwner
        validAddress(newOwner)
        returns (bool)
    {
        address oldOwner = owner;
        address oldTreasury = treasury;

        owner = newOwner;
        treasury = newOwner;

        emit OwnershipTransferred(oldOwner, newOwner);
        emit TreasuryUpdated(oldTreasury, newOwner);
        return true;
    }

    function setTransferEnabled(bool enabled) external onlyOwner returns (bool) {
        transferEnabled = enabled;
        emit TransferStatusChanged(enabled);
        return true;
    }

    function setMintEnabled(bool enabled) external onlyOwner returns (bool) {
        mintEnabled = enabled;
        emit MintStatusChanged(enabled);
        return true;
    }
}
