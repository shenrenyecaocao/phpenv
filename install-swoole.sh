#!/bin/bash
# 安装 PHP Swoole 扩展

__DIR__=$(cd `dirname $0`; pwd)

if [ ! -f "$__DIR__/swoole-version.php" ]; then
    downloadUrl="https://gitee.com/yurunsoft/php-env/raw/master/swoole-version.php"
    if (type wget >/dev/null 2>&1); then
        echo -e "\033[32m正在使用 wget 下载 swoole-version.php...\033[0m"
        wget -O swoole-version.php $downloadUrl
    elif (type curl >/dev/null 2>&1); then
        echo -e "\033[32m正在使用 curl 下载 swoole-version.php...\033[0m"
        curl -o swoole-version.php $downloadUrl
    else
        echo -e "\033[31mError: 没有找到 wget / curl\033[0m"
        exit 1
    fi
fi

php $__DIR__/swoole-version.php

echo -e "\033[32m请输入您想要安装的版本（不用带v开头）：\033[0m"
read -p "" swooleVersion

echo -e "\033[32m安装完成后是否保留源代码？(y/n):\033[0m"
read -p "" keepSource

# make
if !(type make >/dev/null 2>&1); then
    # 安装 make
    echo -e "\033[32m安装 make...\033[0m"
    if (type apt >/dev/null 2>&1); then
        apt update
        apt install -y make
    elif (type yum >/dev/null 2>&1); then
        yum install -y make
    else
        echo -e "\033[31mError: 没有找到 apt / yum\033[0m"
        exit 1
    fi
fi

function version_gt() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" != "$1"; }
function version_le() { test "$(echo "$@" | tr " " "\n" | sort -V | head -n 1)" == "$1"; }
function version_lt() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" != "$1"; }
function version_ge() { test "$(echo "$@" | tr " " "\n" | sort -rV | head -n 1)" == "$1"; }

# gcc
if (type gcc >/dev/null 2>&1); then
    if version_lt $(gcc -dumpversion) "4.8"; then
        echo -e "\033[32m更新 gcc...\033[0m"
        if (type apt >/dev/null 2>&1); then
            apt update
            apt install -y gcc
        elif (type yum >/dev/null 2>&1); then
            yum install -y gcc
        else
            echo -e "\033[31mError: 没有找到 apt / yum\033[0m"
            exit 1
        fi
    fi
else
    # 安装 make
    echo -e "\033[32m安装 gcc...\033[0m"
    if (type apt >/dev/null 2>&1); then
        apt update
        apt install -y gcc
    elif (type yum >/dev/null 2>&1); then
        yum install -y gcc
    else
        echo -e "\033[31mError: 没有找到 apt / yum\033[0m"
        exit 1
    fi
fi

# autoconf
if !(type autoconf >/dev/null 2>&1); then
    # 安装 autoconf
    echo -e "\033[32m安装 autoconf...\033[0m"
    if (type apt >/dev/null 2>&1); then
        apt update
        apt install -y autoconf
    elif (type yum >/dev/null 2>&1); then
        yum install -y autoconf
    else
        echo -e "\033[31mError: 没有找到 apt / yum\033[0m"
        exit 1
    fi
fi

downloadUrl="https://github.com/swoole/swoole-src/archive/v$swooleVersion.tar.gz"
if (type wget >/dev/null 2>&1); then
    echo "\033[32m正在使用 wget 下载 Swoole v$swooleVersion...\033[0m"
    wget -O swoole.tar.gz $downloadUrl
elif (type curl >/dev/null 2>&1); then
    echo "\033[32m正在使用 curl 下载 Swoole v$swooleVersion...\033[0m"
    curl -o swoole.tar.gz $downloadUrl
else
    echo "\033[31mError: 没有找到 wget / curl\033[0m"
    exit 1
fi

tar -xzf swoole.tar.gz
rm swoole.tar.gz

swooleDir="swoole-src-${swooleVersion}"
if [ ! -d "$swooleDir" ]; then
    echo "\033[31mError: 下载或解压失败\033[0m"
    exit 1
fi

cd $swooleDir

phpize

./configure

make -j

make install

if [ "" == "$(php -m | grep swoole)" ]; then
    if [ "" == "$phpdPath" ]; then
        echo "extension=swoole.so" >> $phpIniPath
    else
        echo "extension=swoole.so" >> $phpdPath/30-swoole.ini
    fi
fi

cd ../

if [[ $keepSource = "n" ]]; then
    rm -rf $swooleDir
fi

# 测试
echo "\033[32m测试:\033[0m"

php --ri swoole
