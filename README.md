# 云上友谊 - iOS 版

## 这是怎么工作的？

```
你的 Windows 电脑
    ↓  git push（上传代码）
GitHub 仓库
    ↓  自动触发 Actions
GitHub 云端 Mac 服务器
    ↓  xcodebuild 编译
生成 .ipa 文件
    ↓  下载到本地
你的 iPhone（通过 Sideloadly 安装）
```

---

## 第一步：创建 GitHub 仓库

1. 登录 https://github.com
2. 点击右上角 **+** → **New repository**
3. 仓库名填：`yunshangyouyi`（随意）
4. 选 **Public**（免费用户必须公开才能无限使用 Actions）
5. **不要**勾选 "Add a README file"
6. 点击 **Create repository**

---

## 第二步：安装 Git（如果还没装）

去 https://git-scm.com/download/win 下载安装，一路 Next 即可。

---

## 第三步：上传代码到 GitHub

在本项目文件夹 `e:\iOSAPV1` 下，双击运行 `push-to-github.bat`

它会提示你输入：
- GitHub 用户名
- GitHub 邮箱
- GitHub Personal Access Token（下面教你怎么获取）

### 获取 GitHub Token：

1. 打开 https://github.com/settings/tokens
2. 点击 **Generate new token** → **Generate new token (classic)**
3. Note 随便填，如 `ios-build`
4. Expiration 选 **No expiration**
5. 勾选 **repo**（第一个大选项，全选）
6. 点击底部 **Generate token**
7. **立即复制** token（离开页面后看不到了）

---

## 第四步：等待自动编译

代码推送完成后：
1. 打开你的 GitHub 仓库页面
2. 点击顶部 **Actions** 标签
3. 能看到一个名叫 **Build iOS** 的任务正在运行
4. 等待约 **3-5 分钟**，状态变成绿色 ✓ 表示编译成功

---

## 第五步：下载 .ipa 文件

1. 在 Actions 页面点击成功的那次运行
2. 拉到页面最底部，找到 **Artifacts** 区域
3. 点击 **ResidentCollection-ipa** 下载
4. 解压后得到 `ResidentCollection.ipa` 文件

---

## 第六步：安装到 iPhone

### 方法 A：Sideloadly（推荐，Windows 可用）

1. 电脑安装 [iTunes](https://www.apple.com/itunes/)（64位版）
2. 电脑安装 [Sideloadly](http://sideloadly.io/)
3. iPhone 用数据线连接电脑
4. 打开 Sideloadly
   - Apple ID 填你的 Apple ID
   - 拖入 `ResidentCollection.ipa`
   - 点击 **Start**
5. 等待安装完成，iPhone 桌面出现"云上友谊"图标

> ⚠️ 免费开发者证书签名后 App 有效期 **7 天**，过期后重新用 Sideloadly 签一次即可。

### 方法 B：AltStore

1. 电脑安装 [AltServer](https://altstore.io/)
2. iPhone 连接电脑
3. 通过 AltServer 在 iPhone 安装 AltStore
4. 在 AltStore 中导入 `ResidentCollection.ipa` 安装

---

## 后续更新代码

每次修改代码后，双击运行 `push-to-github.bat` 即可，GitHub 会自动重新编译。

---

## 常见问题

**Q: Actions 运行失败怎么办？**
A: 点击失败的运行查看日志，把错误信息发给我，我帮你排查。

**Q: App 安装后闪退？**
A: 可能是签名问题，确保用 Sideloadly 签名时输入了正确的 Apple ID。

**Q: 每次只能用 7 天太麻烦？**
A: 花每年 ¥688 购买 Apple Developer Program 会员后，签名有效期 1 年。
