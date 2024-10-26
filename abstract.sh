#!/bin/bash

# ========== 下载并显示 Logo ==========
curl -s https://raw.githubusercontent.com/ziqing888/logo.sh/refs/heads/main/logo.sh | bash
sleep 3

# ========== 样式和图标变量 ==========
BOLD='\033[1m'
UNDERLINE='\033[4m'
NORMAL='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'

INFO_ICON="ℹ️ "
SUCCESS_ICON="✅ "
WARNING_ICON="⚠️ "
ERROR_ICON="❌ "

LOG_FILE="script.log"
> "$LOG_FILE"  # 每次运行脚本时清空日志文件

# ========== 信息显示函数 ==========
log_info() {
    local message=$1
    echo -e "${BLUE}${BOLD}${INFO_ICON} ${message}${NORMAL}"
    echo "[INFO] ${message}" >> "$LOG_FILE"
}

log_success() {
    local message=$1
    echo -e "${GREEN}${BOLD}${SUCCESS_ICON} ${message}${NORMAL}"
    echo "[SUCCESS] ${message}" >> "$LOG_FILE"
}

log_warning() {
    local message=$1
    echo -e "${YELLOW}${BOLD}${WARNING_ICON} ${message}${NORMAL}"
    echo "[WARNING] ${message}" >> "$LOG_FILE"
}

log_error() {
    local message=$1
    echo -e "${RED}${BOLD}${ERROR_ICON} ${message}${NORMAL}"
    echo "[ERROR] ${message}" >> "$LOG_FILE"
}

# ========== 环境检查 ==========
check_environment() {
    log_info "检查 Node.js 版本..."
    NODE_VERSION=$(node -v | grep -oP '\d+')
    if [[ "$NODE_VERSION" -lt 18 ]]; then
        log_warning "当前 Node.js 版本低于推荐的 18.x 版本。请考虑升级以避免潜在问题。"
    else
        log_success "Node.js 版本满足要求。"
    fi
}

# ========== 安装依赖函数 ==========
install_node_and_dependencies() {
    log_info "安装 Node.js 和依赖..."

    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install -y nodejs || { log_error "Node.js 安装失败"; exit 1; }
    fi

    if [ ! -d "node_modules" ]; then
        log_info "初始化 npm 并安装依赖..."
        npm init -y
        npm install --save-dev hardhat @matterlabs/hardhat-zksync @matterlabs/zksync-contracts zksync-ethers@6 ethers@6 typescript ts-node || { log_error "依赖安装失败"; exit 1; }
        log_info "初始化 TypeScript 项目..."
        npx hardhat init --typescript --yes || { log_error "Hardhat 初始化失败"; exit 1; }
        log_success "依赖安装和项目初始化完成"
    else
        log_info "依赖已安装，跳过安装步骤。"
    fi
}

# ========== 配置函数 ==========
configure_hardhat() {
    log_info "配置 Hardhat 项目..."
    
    cat <<CONFIG > hardhat.config.ts
import { HardhatUserConfig } from "hardhat/config";
import "@matterlabs/hardhat-zksync";
import "@matterlabs/hardhat-zksync-deploy";

const config: HardhatUserConfig = {
  zksolc: {
    version: "latest",
    settings: {
      enableEraVMExtensions: false,
    },
  },
  defaultNetwork: "abstractTestnet",
  networks: {
    abstractTestnet: {
      url: "https://api.testnet.abs.xyz",
      ethNetwork: "sepolia",
      zksync: true,
      verifyURL: "https://api-explorer-verify.testnet.abs.xyz/contract_verification",
    },
  },
  solidity: {
    version: "0.8.24",
  },
};

export default config;
CONFIG

    log_info "创建 TypeScript 配置文件..."
    cat <<TSCONFIG > tsconfig.json
{
  "compilerOptions": {
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "target": "ES2020",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["hardhat.config.ts", "deploy/**/*.ts", "scripts/**/*.ts", "test/**/*.ts"]
}
TSCONFIG

    log_success "Hardhat 配置和 TypeScript 配置完成"
}

# ========== 编译合约函数 ==========
compile_contracts() {
    log_info "清理旧编译文件并重新编译合约..."

    mkdir -p contracts
    cat <<EOF > contracts/HelloAbstract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract HelloAbstract {
    function sayHello() public pure returns (string memory) {
        return "Hello from zkSync with Bash!";
    }
}
EOF

    npx hardhat clean && npx hardhat compile || { log_error "合约编译失败"; exit 1; }
    log_success "合约编译完成"
}

# ========== 部署合约函数 ==========
deploy_contract() {
    read -s -p "请输入你的钱包私钥（不含 0x）： " wallet_key
    echo

    if [[ -z "$wallet_key" ]]; then
        log_error "私钥不能为空，请重试。"
        return 1
    fi

    log_info "生成合约部署脚本..."
    cat <<DEPLOY > deploy.ts
import { Wallet } from "zksync-ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Deployer } from "@matterlabs/hardhat-zksync";

export default async function (hre: HardhatRuntimeEnvironment) {
    const wallet = new Wallet("$wallet_key");
    const deployer = new Deployer(hre, wallet);
    const artifact = await deployer.loadArtifact("HelloAbstract");
    const contract = await deployer.deploy(artifact);
    console.log("合约已部署，地址:", await contract.getAddress());
}
DEPLOY

    if [[ ! -f "deploy.ts" ]]; then
        log_error "部署脚本生成失败，请检查脚本创建逻辑。"
        return 1
    fi

    npx hardhat deploy-zksync --script deploy.ts || { log_error "合约部署失败"; exit 1; }
    log_success "合约部署完成"
}

# ========== 验证合约函数 ==========
verify_contract() {
    read -p "请输入要验证的合约地址： " contract_address

    if [[ -z "$contract_address" ]]; then
        log_error "合约地址不能为空，请重试。"
        return 1
    fi

    log_info "验证合约 $contract_address 中..."
    npx hardhat verify --network abstractTestnet "$contract_address" || { log_error "合约验证失败"; exit 1; }
    log_success "合约验证完成"
}

# ========== 菜单显示和控制逻辑 ==========
display_menu() {
    echo -e "\n${YELLOW}============ 选择操作 ============${NORMAL}"
    echo "1. 检查环境"
    echo "2. 安装 Node.js 和依赖"
    echo "3. 配置 Hardhat 项目"
    echo "4. 编译合约"
    echo "5. 部署合约"
    echo "6. 验证合约"
    echo "7. 退出"
    echo -e "${YELLOW}==================================${NORMAL}"
}

execute_option() {
    local choice=$1
    case "$choice" in
        1) check_environment ;;
        2) install_node_and_dependencies ;;
        3) configure_hardhat ;;
        4) compile_contracts ;;
        5) deploy_contract ;;
        6) verify_contract ;;
        7) 
            read -p "确定要退出吗？(y/n): " confirm
            if [[ "$confirm" == "y" ]]; then
                log_info "退出脚本"; exit 0
            fi
            ;;
        *) log_error "无效选项，请重新选择。" ;;
    esac
}

# ========== 主循环 ==========
while true; do
    display_menu
    read -p "请选择一个选项： " user_choice
    execute_option "$user_choice"
done
