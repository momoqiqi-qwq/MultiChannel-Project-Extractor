# 解压台：多通道项目解压与任务中心

基于 **Tauri 2 + Rust + Vue 3 + Pinia** 的桌面批量解压应用。每个通道拥有独立文件队列、输出目录、层级规则、重名策略、关键词收件规则、分类、密码与项目辅助工具；全局调度器负责并发、优先级、暂停、恢复、预检查和任务历史。

当前版本：**0.8.4**

## 0.8.4 重点

- 每个通道的“项目辅助工具”新增“解压完成后自动运行 Claude”开关，默认关闭。
- 成功解压后直接使用任务的实际输出目录执行 `claude --dangerously-skip-permissions`，无需再次选择目录。
- 启动器继续支持系统 PATH、npm 全局 `claude.cmd`、官方 `@anthropic-ai/claude-code` 包入口和 Windows 原生二进制。
- 开启开关时会明确提示跳过权限确认的风险；自动任务运行时不再逐个弹窗。
- 同一输出目录 8 秒内只启动一个窗口，避免多个任务写入同一路径时重复打开 Claude。
- 开关可随通道、预设和配置持久化；恢复默认时自动关闭。

完整变更与验收：

- `docs/RELEASE_NOTES_0.8.4.md`
- `docs/IMPLEMENTATION_CHECKLIST_0.8.4.md`
- `docs/TEST_REPORT_0.8.4.md`

## 0.8.3 重点

- 通道中的 Claude 项目按钮直接使用该通道配置的解压目录，不再额外弹出项目目录选择器。
- “指定目录”模式使用 `channel.destination`；“跟随压缩包”模式使用已加入压缩包的所在目录。
- Claude CLI 检测先查系统 PATH，再查 npm 全局前缀、全局 `node_modules` 与官方 `@anthropic-ai/claude-code` 包。
- 即使桌面应用进程没有刷新 PATH，也可以直接使用 npm 全局安装产生的 `claude.cmd`、包入口或 Windows x64 / ARM64 原生二进制。
- CLI 状态卡显示命令来源与实际可执行文件路径，并在未安装时提示官方 npm 安装命令。


### 每通道自动开始

每个通道的详细设置中新增“导入后自动开始”开关。拖拽、文件选择和关键词收件导入时，只会自动提交本次新增的受支持压缩包，不会顺带重跑旧失败项。总设置中的开关改为“新通道默认自动开始”，只影响之后新建或恢复默认的通道。

### 每通道关键词收件与最高版本选择

每个通道可以设置自己的：

- 扫描目录，支持一键使用系统“下载”目录；
- 多个关键词，支持“全部包含”或“任一包含”；
- 是否递归扫描子目录；
- 是否排除 alpha、beta、rc、preview 等预发布文件；
- 是否优先选择最高版本。

扫描只处理受支持的压缩格式。出现多个匹配项时，会优先识别文件名中 `version`、`release`、`版本`、`ver` 或 `v` 后的数字序列，并按数字比较，例如 `2.10.0` 高于 `2.9.9`；无法识别版本时按最后修改时间选择。扫描结果会显示完整候选列表；用户可以自动加入推荐版本，也可以关闭自动加入后先预览，再手动选择任意候选。

总设置新增“关键词收件”页，可配置新通道默认值、启动时自动扫描、扫描后自动加入或仅预览候选、候选数量和队列替换行为。主工具栏与快捷设置均提供“扫描全部关键词通道”入口，快捷键为 `Ctrl+Shift+F`。

### Claude 项目 DAT 启动

通道中的“生成 Claude DAT”和“用 DAT 打开 Claude”直接使用当前通道的解压目录，不再弹出第二次目录选择器。“指定目录”模式使用用户配置的目标目录；“跟随压缩包”模式使用已加入压缩包的所在目录。每个已完成文件旁的 Claude 按钮仍使用该文件自己的实际输出目录。

Windows 启动流程会：

1. 验证通道配置的解压目录真实存在；
2. 查找该目录中的 `我的Claude项目.dat`；
3. 没有 DAT 时自动生成，已有 DAT 时优先直接使用；
4. 先用 `where claude` 查系统 PATH，再查询 `npm prefix -g`、`npm root -g` 和官方 `@anthropic-ai/claude-code` 包；
5. 对找到的命令执行 `--version`，并显示来源和实际路径；
6. 将 DAT 所在目录固定为新命令窗口的工作目录；
7. 执行 `claude --dangerously-skip-permissions`；
8. 返回 DAT 路径与进程 PID，并写入日志。

DAT 为解压台自己的项目描述文件。后端不会执行 DAT 中的任意自定义命令，实际 Claude 命令固定在程序内，以避免文件被篡改后执行其他内容。

该参数会跳过 Claude 工具调用权限确认，只应在可信项目中使用。

### 自定义背景增强

- 图片自动铺满、完整显示或拉伸；
- 可拖动背景焦点，并使用 X/Y 滑杆精调；
- 支持缩放、亮度、对比度、饱和度、模糊、透明度、暗化、暗角和遮罩颜色；
- 提供“清晰原图、文字优先、柔和虚化、鲜艳展示”四套快速效果；
- 通道背景穿透与通道不透明度独立控制；
- 背景复制到应用数据目录，原图移动后仍可使用。

### 体验优化

- 设置中心新增关键词收件分类和 Claude CLI 状态检测；
- 搜索可匹配通道关键词与扫描目录；
- 通道内关键词设置采用分区卡片和响应式布局；
- 候选文件显示版本、格式、大小和当前选择，可展开全部候选、打开扫描目录或清除结果；
- 启动时自动扫描、全局扫描、预览模式、自动加入和手动候选导入均有清晰提示；
- 设置、日志、任务中心保持互斥，临时面板可用 `Esc` 关闭。

完整变更与验收：

- `docs/RELEASE_NOTES_0.8.3.md`
- `docs/IMPLEMENTATION_CHECKLIST_0.8.3.md`
- `docs/TEST_REPORT_0.8.3.md`

## 核心功能

- 多通道新建、删除、重命名、复制、排序、分类和折叠。
- 项目中心自动收录解压结果，支持手动项目、置顶、状态、标签、备注、搜索和归档。
- 文件选择与 Tauri 原生拖放导入。
- 跟随压缩包目录或指定统一输出目录。
- 直接写入或建立压缩包同名文件夹。
- 保留结构、完全展平、保留 N 层、跳过单一公共根目录。
- 重名文件替换、自动改名或跳过。
- 关键词扫描下载目录并自动选择最高版本。
- 全部开始、单通道开始、失败重试、重新解压、暂停、继续、取消和并发限制。
- 高、普通、低文件优先级与按通道、轮询队列策略。
- 开始前自检、输出树预览、磁盘空间估算和冲突提示。
- 任务历史、异常中断恢复、ETA、目标路径锁、结果清单和安全删除。
- ZIP、7Z 密码输入；RAR 密码传给外部工具。
- 11 套主题、字体、自定义背景、透明度、配置导入导出和通道模板。
- Claude 项目 DAT 生成、复用、CLI 检测、通道配置目录/文件实际输出目录启动、解压完成自动运行、npm CLI 探测和新命令窗口。

## 关键词收件示例

下载目录中存在：

```text
project-windows-x64-v2.9.9.zip
project-windows-x64-v2.10.0.zip
project-windows-x64-v3.0.0-rc1.zip
project-linux-x64-v3.1.0.tar.gz
```

通道关键词设为：

```text
project, windows, x64
```

并使用“包含全部关键词、优先最高版本、排除预发布版本”时，会选择：

```text
project-windows-x64-v2.10.0.zip
```

## 层级与输出规则

假设归档内有 `根目录/资料/图片/示例文件.txt`：

| 模式 | 输出结果 |
|---|---|
| 保留结构 | `目标/根目录/资料/图片/示例文件.txt` |
| 完全展平 | `目标/示例文件.txt` |
| 保留 1 层 | `目标/根目录/示例文件.txt` |
| 保留 2 层 | `目标/根目录/资料/示例文件.txt` |
| 跳过外层 | `目标/资料/图片/示例文件.txt` |

## 支持格式

| 格式 | 实现方式 | 备注 |
|---|---|---|
| `.zip` | Rust `zip` | ZipCrypto/AES；路径安全过滤 |
| `.7z` | `sevenz-rust` | 支持密码 |
| `.rar` | 系统 `unrar`，再尝试 `7z` / `7zz` | 不捆绑 RAR 二进制 |
| `.tar` | Rust `tar` | 普通文件和目录 |
| `.tar.gz` / `.tgz` | `tar` + `flate2` |  |
| `.tar.bz2` / `.tbz2` / `.tbz` | `tar` + `bzip2` |  |
| `.tar.xz` / `.txz` | `tar` + `xz2` |  |
| `.gz` / `.bz2` / `.xz` | 单文件流 | 自动移除压缩扩展名 |

## 环境要求与运行

1. Node.js 20.19+ 或 22.12+。
2. 最新稳定版 Rust 工具链。
3. Tauri 对应平台构建依赖。
4. RAR 解压需要 `unrar`、`7z` 或 `7zz` 位于 `PATH`。
5. Claude 一键启动需要 Windows 且 `claude` 位于 `PATH`。

```bash
npm install
npm run tauri dev
```

只预览 Vue 界面：

```bash
npm run dev
```

## 检查与构建

无需安装前端依赖的静态检查：

```bash
npm run check:config
npm run check:layout
```

完整检查与 Windows 构建：

```powershell
npm install
npm run check
npm run tauri build
```

## 配置迁移与隐私

0.8.1 使用：

```text
multichannel-extractor-state-v9
multichannel-extractor-presets-v9
jieyatai-task-history-v2
```

0.8.0 及更早版本的工作区与预设会自动迁移。通道密码不会写入工作区配置；任务历史只保存不含密码的恢复快照。关键词和目录属于通道配置，会随配置导出。

## 目录结构

```text
multichannel-extractor/
├─ src/
│  ├─ components/
│  │  ├─ settings/
│  │  ├─ ChannelCard.vue
│  │  ├─ ChannelInboxSettings.vue
│  │  ├─ SettingsDrawer.vue
│  │  └─ TaskCenterDrawer.vue
│  ├─ config/
│  ├─ domain/
│  ├─ services/
│  ├─ stores/
│  └─ styles/
├─ src-tauri/
│  ├─ resources/
│  └─ src/
│     ├─ archive/
│     ├─ directory_scan.rs
│     ├─ commands.rs
│     ├─ system_tools.rs
│     └─ models.rs
├─ scripts/
└─ docs/
```

## 后续规划

0.9.0 建议聚焦真实归档内容树、选择性解压、关键词规则组、定时目录监控、精确版本策略和 Windows CI。详见 `docs/NEXT_VERSION_0.9.0.md`。
