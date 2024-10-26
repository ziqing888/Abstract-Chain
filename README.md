
<h2 align=center> 在 Abstract Testnet 上部署智能合约</h2>

## 前提条件
- 您需要在 Abstract Testnet 上拥有用于支付 Gas 费用的资金。
  - 可以通过 [水龙头](https://faucet.triangleplatform.com/abstract/testnet) 获取 Gas 费用，或者使用 [官方桥接](https://portal.testnet.abs.xyz/bridge/) 从 Sepolia 网络桥接。
- 您可以选择在本地终端（例如 Ubuntu）或虚拟 IDE（例如 [codespaces](https://github.com/codespaces)）上操作。

## 安装步骤
- 可以使用以下命令运行脚本：
 ```bash
[ -f "abstract.sh" ] && rm abstract.sh; curl -sSL -o abstract.sh https://raw.githubusercontent.com/ziqing888/Abstract-Chain/refs/heads/main/abstract.sh && chmod +x abstract.sh && ./abstract.sh
