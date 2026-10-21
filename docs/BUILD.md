# 构建与推送流程

本文档记录 Slay the Tower 的开发推送、自动构建与发版流程。

---

## 一、日常开发推送流程

### 1. 环境准备（一次性）

```bash
# SSH 走 443 端口（绕过 22 端口封锁）
mkdir -p ~/.ssh
cat > ~/.ssh/config << 'EOF'
Host github.com
    HostName ssh.github.com
    Port 443
    User git
EOF
chmod 600 ~/.ssh/config
```

> 这个文件丢失后 `git push` 会退回 22 端口并报 `Connection refused`，重建即可。

### 2. 开发一个功能

```bash
cd /c/Projects/slay-the-tower
git checkout -b feat/功能名      # 开分支
# ...改代码、F5 测试...
git add .
git commit -m "feat: 功能描述"
git checkout main
git merge feat/功能名
git push
git branch -d feat/功能名
```

### 3. 提交信息规范

| 前缀 | 用途 |
|------|------|
| `feat:` | 新功能 |
| `fix:` | 修 bug |
| `refactor:` | 重构（不改行为） |
| `docs:` | 文档 |
| `ci:` | 构建/工作流 |
| `build:` | 构建配置（导出预设等） |

---

## 二、两套自动构建

### 文件位置

```
.github/workflows/
  build-windows.yml   ← Windows 构建
  build-android.yml   ← Android 构建
```

### 对比

| | Windows | Android |
|---|---|---|
| 工作流名 | `Build Windows` | `Build Android` |
| 触发 | 手动 / 推 `v*` tag | 手动 / 推 `v*` tag |
| 运行环境 | `ubuntu-latest` | `ubuntu-latest` |
| Godot | `setup-godot@v2`（4.7.2） | 手动下载 4.7.2 Linux 版 |
| 导出模板 | action 自动带 | 只解压 `android*`（省磁盘） |
| 额外依赖 | 无 | JDK 17 + Android SDK |
| 导出命令 | `--export-release "Windows Desktop"` | `--export-debug "Android"` |
| 产物 | `.exe`（+ `.pck`） | `.apk` |
| artifact 名 | `SlayTheTower-Windows` | `SlayTheTower-Android` |

### Android 工作流的关键步骤

```
1. 缓存 Godot + 模板（第二次起很快）
2. 下载 Godot 4.7.2 Linux 版
3. 只解压 android* 模板（避免 disk full）
4. setup-java 17
5. setup-android（packages: platform-tools，跳过废弃的 tools 包）
6. sdkmanager 装 platforms;android-35 + build-tools;35.0.0
7. 用 keytool 生成 debug.keystore
8. 写 Godot 编辑器设置（SDK 路径 + keystore）
9. --import → --export-debug "Android"
10. 上传 artifact / 附加到 Release
```

---

## 三、手动构建

1. 打开 https://github.com/td1ql/slay-the-tower/actions
2. 左侧选 **Build Windows** 或 **Build Android**
3. 右侧 **Run workflow** → 分支 `main` → 绿按钮
4. 等 1~5 分钟（首次 5~10 分钟，有缓存后 1 分钟）
5. 运行详情页**底部** → **Artifacts** → 下载 zip

---

## 四、发版流程

```bash
cd /c/Projects/slay-the-tower

# 1. 确认 main 干净且已推送
git status -sb

# 2. 打 tag
git tag -a v1.0.1 -m "v1.0.1 - 支持 Android"
git push origin v1.0.1
```

推 tag 后会自动发生：

1. `build-windows.yml` 和 `build-android.yml` **同时触发**
2. 各自构建，产物上传 artifact
3. 因为工作流里有 `Attach to release` 步骤（`softprops/action-gh-release@v2`），**Windows exe 和 Android apk 会自动附加到 v1.0.1 的 Release**

然后去 https://github.com/td1ql/slay-the-tower/releases 编辑 v1.0.1，写说明、发布。

---

## 五、必须提交的关键文件

| 文件 | 作用 | 注意 |
|------|------|------|
| `export_presets.cfg` | 导出预设 | **被 .gitignore 忽略**，要用 `git add -f` |
| `project.godot` | 含 ETC2 开关、手机适配 | Android 导出必需 `import_etc2_astc=true` |
| `.github/workflows/*.yml` | 工作流 | 改动后要 push 才生效 |
| `.gitignore` | 忽略 `.godot/`、`build/` | 不要忽略 `export_presets.cfg` |

### 当前 `export_presets.cfg` 内容

```
name="Windows Desktop"  → build/SlayTheTower.exe
name="Android"          → build/SlayTheTower.apk
                          package/unique_name="com.td1ql.slaythetower"
```

---

## 六、常见报错速查

| 报错 | 原因 | 解决 |
|------|------|------|
| `Connection refused` (port 22) | SSH config 丢失 | 重建 `~/.ssh/config`（见第一节） |
| `No export preset named "X"` | 预设名不匹配 | 检查 `export_presets.cfg` 的 `name=` |
| `export_presets.cfg` 找不到 | 被 gitignore | `git add -f export_presets.cfg` |
| `disk full` | 解压全量模板 | 只解压 `android*` |
| `Failed to find package 'tools'` | tools 包已废弃 | `packages: "platform-tools"` |
| `ETC2/ASTC texture compression is required` | 没开移动纹理压缩 | 开启 `import_etc2_astc` |
| `Android SDK path is not set` | CI 没写编辑器设置 | 检查 `Configure Godot editor settings` 步骤 |
| `Invalid package name` | 包名是 `com.example.$genname` | 改成正式包名 |
| 构建成功但 artifact 没有 | 步骤顺序/路径错 | 检查 `Upload artifact` 的 `path` |

---

## 七、本地辅助命令

```bash
# 看当前状态
git status -sb

# 看提交历史
git log --oneline -5

# 看 tag
git tag

# 看工作流文件是否已提交
git ls-files .github/workflows/

# 检查 SSH 连接
ssh -T git@github.com
```

---

## 八、手机安装 APK

1. 下载 artifact `SlayTheTower-Android`（zip）
2. 解压出 `SlayTheTower.apk`
3. 传到手机（微信 / QQ / 数据线）
4. 手机上点击安装，允许「安装未知来源应用」

游戏为 1280×720 横向，手机上是等比缩放 + 黑边。

---

*最后更新：v1.0.0 之后*
