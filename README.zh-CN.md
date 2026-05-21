# claude-flutter-skills

> [English](README.md) · **中文**

面向 Flutter 开发的 [Claude Code](https://claude.com/claude-code) 插件市场。
目前提供一个插件 —— **flutter-html-reproduce**，用于把 HTML 设计稿还原成
Flutter UI 页面。

## 安装

在 Claude Code 中执行：

```
/plugin marketplace add kane313/claude-flutter-skills
/plugin install flutter-html-reproduce@claude-flutter-skills
```

按提示重启 Claude Code。后续获取更新：

```
/plugin marketplace update claude-flutter-skills
```

## 插件内容：flutter-html-reproduce

把 HTML 输入（本地 `.html` / `.css` 文件、URL、截图，或粘贴的代码片段）通过
5 阶段流水线还原成 Flutter 页面：

```
源获取与对齐 → 骨架 → 样式 → 资源与状态 → 校验
```

插件打包了一个编排 skill 加 6 个子 skill：

| Skill | 职责 |
|---|---|
| `flutter-html-reproduce` | 编排整条 5 阶段流水线 |
| `html-source-fetcher` | 把 HTML 输入归一化成单个文件 |
| `html-flutter-align-table` | 把 CSS 设计 token 对齐到项目的 `ThemeData` |
| `html-dom-to-widget-tree` | 把 DOM 翻译成 Flutter widget 树 |
| `html-css-to-flutter-style` | 把 CSS 样式填进 widget 树 |
| `html-asset-export` | 导出图片 / 图标 / 字体并修补 `pubspec.yaml` |
| `html-flutter-pixel-diff` | 把还原结果与设计稿做像素级对比 |

## 用法

在 Claude Code 里打开一个 Flutter 工程（工作目录需包含带 `flutter:` 依赖的
`pubspec.yaml`），然后用自然语言描述需求即可。skill 会在以下情况自动触发：

- 说出「还原这个 HTML」「用 Flutter 实现这个网页」等
- 消息里带 `.html` / `.css` 文件路径，或 `http(s)` URL，并带有还原意图

流水线会尽量复用项目已有的主题，把产物拆分成 `theme/`、`models/`、`data/`、
`widgets/`、`pages/` 多个文件，并在过程中运行 `flutter analyze`。

### 运行模式

| 模式 | 行为 |
|---|---|
| `safe`（默认） | 每个阶段结束后暂停，等你确认 |
| `fast` | 自动串联中间阶段，只在首尾暂停 |
| `auto` | 全程不暂停，端到端跑完 |
| `incremental` | 目标页面文件已存在时自动选用；先做像素 diff，只对差异区域做精准修改，绝不直接覆盖手改过的代码 |

## 环境要求

- 支持插件的 Claude Code
- 工作目录是一个 Flutter 工程
- 可选：`PATH` 上有 `cwebp`（用于 WebP 资源转换）；安装 Patrol（用于像素对比
  校验步骤 —— 未安装时该步会优雅跳过，不会报错）

## 维护本插件

skill 在 `~/.claude/skills/` 下开发，需拷贝进本仓库才能分发。改完 skill 后，
用仓库自带的脚本同步并发布：

```bash
./sync-skills.sh           # 拷入最新 skill，列出改动后停下
./sync-skills.sh --push    # 拷入 + 升 patch 版本号 + 提交并推送
```

`--push` 会把 `plugin.json` 里的 `version` 自增一个 patch 段，这样同事执行
`/plugin marketplace update claude-flutter-skills` 时才会收到更新。

## 许可证

MIT，见 [LICENSE](LICENSE)。
