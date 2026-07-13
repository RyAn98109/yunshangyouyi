@echo off
chcp 65001 >nul
title 推送代码到 GitHub

echo ============================================
echo   云上友谊 iOS - 推送代码到 GitHub
echo ============================================
echo.

cd /d "e:\iOSAPV1"

:: 检查 Git 是否安装
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo [错误] 未检测到 Git，请先安装：https://git-scm.com/download/win
    pause
    exit /b 1
)

:: 首次配置
if not exist .git (
    echo [步骤 1/4] 初始化 Git 仓库...
    git init
    echo.

    set /p username="请输入 GitHub 用户名: "
    set /p email="请输入 GitHub 邮箱: "
    git config user.name "%username%"
    git config user.email "%email%"
    echo.

    echo [步骤 2/4] 请提供你的 GitHub 仓库地址
    echo   格式: https://github.com/用户名/仓库名
    echo   例如: https://github.com/zhangsan/yunshangyouyi
    echo.
    set /p repo_url="请粘贴仓库地址: "

    :: 移除可能已有的 origin
    git remote remove origin 2>nul
    git remote add origin "%repo_url%.git"
) else (
    echo [信息] Git 仓库已存在，直接推送更新...
)

echo.
echo [步骤 3/4] 添加文件并提交...
git add -A
git commit -m "Update iOS project"
echo.

echo [步骤 4/4] 推送到 GitHub...
echo   如果提示输入密码，请粘贴你的 GitHub Personal Access Token
echo   （不是 GitHub 登录密码！Token 获取见 README.md）
echo.

:: 尝试推送到 main 分支
git branch -M main
git push -u origin main

if %errorlevel% neq 0 (
    echo.
    echo [提示] 如果推送失败，可能是因为：
    echo   1. Token 输入错误 - 重新生成 Token 再试
    echo   2. 仓库地址不对 - 检查仓库 URL 是否正确
    echo   3. 网络问题 - 需要科学上网
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   推送成功！
echo ============================================
echo.
echo   现在去 GitHub 仓库点击 Actions 标签
echo   等待编译完成（约 3-5 分钟）
echo   编译成功后下载 .ipa 文件
echo.
pause
