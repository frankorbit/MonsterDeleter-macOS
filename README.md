# 大将怪兽摧毁 for macOS

把枯燥的“移到废纸篓”变成一场桌面特摄：从 Finder 选中一个文件或文件夹，召唤大将怪兽走到目标旁边，确认后将它踢爆，再骑着雷欧离场。

这是 [MonsterDeleter](https://github.com/531149627/MonsterDeleter) 的原生 macOS 移植版。主程序使用 Swift 6、SwiftUI 与 AppKit 编写，不依赖 Python 或 Qt。

> [!IMPORTANT]
> 本仓库以 MIT License 开源 Swift 源码，但不包含上游图片和音频。上游仓库没有提供开源许可证或明确的再分发授权。首次构建前请阅读[素材许可说明](#素材与许可)，并自行确认拥有使用素材的权利。

## 功能

- Finder 右键菜单：运行一次 App 后自动注册“召唤大将怪兽摧毁”服务。
- 可选 Finder Sync 扩展：把入口提升到 Finder 顶层右键菜单。
- 菜单栏常驻：不占用 Dock，左击恐龙图标打开主窗口，右击可打开菜单或退出。
- 完整动画流程：入场、行走、指认、踢击、爆炸、雷欧登场和飞离。
- 支持文件与文件夹：可以从 App 选择、拖入，或直接从 Finder 右键召唤。
- 安全删除：目标只会移入废纸篓，可以恢复，不会执行永久删除。
- 多屏幕与 Finder 定位：从右键菜单启动时，会在目标所在屏幕和位置播放动画。
- 随时取消：动画期间按 `Esc` 即可退出。

## 系统要求

- macOS 14 或更高版本
- Xcode 16 或更高版本
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- Git

安装 XcodeGen：

```bash
brew install xcodegen
```

## 构建与安装

### 1. 克隆源码

```bash
git clone https://github.com/frankorbit/MonsterDeleter-macOS.git
cd MonsterDeleter-macOS
```

### 2. 准备动画和音频素材

确认已阅读素材许可说明后，运行：

```bash
./Scripts/import-upstream-assets.sh --acknowledge-unlicensed-assets
```

脚本会从上游仓库下载素材并放入本机的 `Resources/Images` 与 `Resources/Audio`，不会把素材提交到本仓库。

### 3. 构建 App

```bash
./Scripts/build-local.sh
```

构建完成后，终端会输出 `MonsterDeleter.app` 的完整路径，通常是：

```text
DerivedData/Build/Products/Release/MonsterDeleter.app
```

把这个 App 拖入 `/Applications`，然后运行一次。启动后菜单栏会出现 `🦖` 图标。

也可以生成 Xcode 工程后直接调试：

```bash
xcodegen generate
open MonsterDeleter.xcodeproj
```

## 怎么使用

### 方法一：Finder 右键菜单

1. 先运行一次“大将怪兽摧毁”，让系统注册 Finder 服务。
2. 在 Finder 中只选中一个文件或文件夹。
3. 右键打开菜单，在“快速操作”或“服务”中选择“召唤大将怪兽摧毁”。
4. 怪兽会直接从屏幕外走向目标；确认目标后点击“是的，踢爆它”。

如果服务没有立即出现，请重新启动 Finder，或注销并重新登录当前账户后再试。

### 方法二：顶层 Finder 右键菜单

1. 左击菜单栏的 `🦖` 图标打开 App。
2. 点击“启用顶层 Finder 右键菜单（可选）”。
3. 在 macOS 的扩展管理界面启用“大将怪兽 Finder 扩展”。
4. 之后“召唤大将怪兽摧毁”会直接显示在 Finder 右键菜单中。

macOS 要求用户手动授权 Finder 扩展，第三方 App 无法静默绕过这个步骤。

### 方法三：从 App 启动

1. 左击菜单栏的 `🦖` 图标。
2. 点击“选择目标”，或把文件、文件夹拖入窗口。
3. 在全屏瞄准界面点击目标图标所在位置。
4. 等怪兽到达后确认摧毁。

右击菜单栏图标可以打开 App 或退出常驻进程。

## 开发与测试

项目使用 XcodeGen 维护工程配置，修改 `project.yml` 后需要重新生成工程。

```bash
# 生成 Xcode 工程
just generate

# Debug 构建
just build

# 运行全部测试
just check
```

如果没有安装 `just`，可以使用：

```bash
xcodegen generate
xcodebuild \
  -project MonsterDeleter.xcodeproj \
  -scheme MonsterDeleter \
  -configuration Debug \
  -derivedDataPath DerivedData \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## 工程结构

```text
Sources/
├── App/                 # App 生命周期、菜单栏和路由
├── Models/              # 目标、动画与场景状态
├── Services/            # 文件选择、校验、音频和移入废纸篓
├── Stores/              # @Observable 主线程状态协调
├── Views/               # SwiftUI 界面与逐帧动画
└── WindowControllers/   # AppKit 窗口生命周期
FinderSyncExtension/     # Finder 顶层右键菜单扩展
Resources/               # 本地导入的动画与音频，不提交到 GitHub
Scripts/                 # 素材导入与本地构建脚本
Tests/                   # 路由、Finder、动画、音频和安全校验测试
project.yml              # XcodeGen 工程配置
```

## 安全说明

- 删除操作使用 `FileManager.trashItem`，目标会进入废纸篓。
- 根目录、系统保护目标、已不存在的目标和多选请求会被拒绝。
- 主 App 当前没有启用 App Sandbox。Finder Sync 通过自定义 URL 把所选路径传递给主 App，而该通道不能传递 security-scoped access。
- 当前方案适合本地签名与站外分发。如果要提交 Mac App Store，需要改为 App Group + 安全书签，或使用系统 Quick Action 工作流传递访问权限。

## 素材与许可

Swift 源码使用 [MIT License](LICENSE)。

动画和音频来自 [531149627/MonsterDeleter](https://github.com/531149627/MonsterDeleter)，但该仓库目前没有 OSI 开源许可证，也没有明确授予再分发或商业使用权。因此：

- 本仓库不包含这些媒体文件。
- 导入脚本只帮助你从上游公开地址下载到本机。
- 下载、使用、发布或商业化前，请自行获得相关版权方授权。
- 本项目不主张拥有这些媒体素材的版权。

更多信息见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

## 致谢

- 原始创意与素材：[531149627/MonsterDeleter](https://github.com/531149627/MonsterDeleter)
- macOS 版本：[frankorbit](https://github.com/frankorbit)

欢迎提交 Issue 和 Pull Request，一起完善动画、适配和交互体验。
