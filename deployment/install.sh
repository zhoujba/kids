#!/bin/bash

# Kids Schedule App 服务器安装脚本
# 适用于 Ubuntu 20.04+

set -e

echo "🚀 开始安装 Kids Schedule App 服务器环境..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
if [[ $EUID -ne 0 ]]; then
   log_error "此脚本需要root权限运行"
   exit 1
fi

# 更新系统
log_info "更新系统包..."
apt update && apt upgrade -y

# 安装基础软件
log_info "安装基础软件包..."
apt install -y curl wget git unzip software-properties-common

# 安装 Nginx
log_info "安装 Nginx..."
apt install -y nginx

# 安装 PHP 8.1
log_info "安装 PHP 8.1..."
add-apt-repository ppa:ondrej/php -y
apt update
apt install -y php8.1 php8.1-fpm php8.1-mysql php8.1-curl php8.1-json php8.1-mbstring php8.1-xml php8.1-zip

# 安装 MySQL
log_info "安装 MySQL 8.0..."
apt install -y mysql-server

# 启动服务
log_info "启动服务..."
systemctl start nginx
systemctl enable nginx
systemctl start php8.1-fpm
systemctl enable php8.1-fpm
systemctl start mysql
systemctl enable mysql

# 配置 MySQL
log_info "配置 MySQL..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root123';"
mysql -u root -proot123 -e "CREATE DATABASE IF NOT EXISTS kids_schedule;"
mysql -u root -proot123 -e "CREATE USER IF NOT EXISTS 'kidsapp'@'%' IDENTIFIED BY 'KidsApp2025!';"
mysql -u root -proot123 -e "GRANT ALL PRIVILEGES ON kids_schedule.* TO 'kidsapp'@'%';"
mysql -u root -proot123 -e "FLUSH PRIVILEGES;"

# 创建数据库表
log_info "创建数据库表..."
mysql -u root -proot123 kids_schedule < deployment/mysql_setup.sql

# 配置 Nginx
log_info "配置 Nginx..."
cp deployment/nginx.conf /etc/nginx/sites-available/kids-api
ln -sf /etc/nginx/sites-available/kids-api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# 创建Web目录
log_info "设置Web目录..."
mkdir -p /var/www/kids-api
cp -r php-mysql-api/* /var/www/kids-api/
chown -R www-data:www-data /var/www/kids-api
chmod -R 755 /var/www/kids-api

# 配置PHP
log_info "配置PHP..."
sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/' /etc/php/8.1/fpm/php.ini

# 重启服务
log_info "重启服务..."
systemctl restart nginx
systemctl restart php8.1-fpm

# 配置防火墙
log_info "配置防火墙..."
ufw allow 'Nginx Full'
ufw allow ssh
ufw --force enable

# 获取服务器IP
SERVER_IP=$(curl -s ifconfig.me)

log_info "✅ 安装完成！"
echo ""
echo "🌐 服务器信息："
echo "   IP地址: $SERVER_IP"
echo "   API地址: http://$SERVER_IP/api"
echo "   健康检查: http://$SERVER_IP/health"
echo ""
echo "📱 iOS应用配置："
echo "   更新 MySQLManager.swift 中的服务器地址："
echo "   private let baseURL = \"http://$SERVER_IP/api\""
echo "   private let healthURL = \"http://$SERVER_IP/health\""
echo ""
echo "🧪 测试命令："
echo "   curl http://$SERVER_IP/health"
echo ""
log_info "部署完成！🎉"
