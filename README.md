#在 Abstract Testnet 上部署智能合约
前提条件
您需要在 Abstract Testnet 上拥有用于支付 Gas 费用的资金。
可以通过 水龙头 获取 Gas 费用，或者使用 官方桥接 从 Sepolia 网络桥接。
您可以选择在本地终端（例如 Ubuntu）或虚拟 IDE（例如 codespaces）上操作。
安装步骤
可以使用以下任一命令运行安装脚本：

使用 curl：

bash
复制代码
[ -f "abstract.sh" ] && rm abstract.sh; curl -sSL -o abstract.sh https://raw.githubusercontent.com/zunxbt/Abstract-Chain/refs/heads/main/abstract.sh && chmod +x abstract.sh && ./abstract.sh
使用 wget：

bash
复制代码
[ -f "abstract.sh" ] && rm abstract.sh; wget -q -O abstract.sh https://raw.githubusercontent.com/zunxbt/Abstract-Chain/refs/heads/main/abstract.sh && chmod +x abstract.sh && ./abstract.sh
重要提示 Abstract-Chain
