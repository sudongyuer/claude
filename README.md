# claude

我的 Claude Code 全局配置：规则、子 agent、命令、输出风格和插件清单。

## 安装

```bash
git clone https://github.com/sudongyuer/claude.git ~/git/claude
git clone https://github.com/sudongyuer/skills.git ~/git/skills
cd ~/git/claude
./install.sh --dry-run                           # 先看会做什么
./install.sh --plugins --skills ~/git/skills     # 链接配置、安装插件、安装 skills
```

- `CLAUDE.md`、`agents/`、`commands/`、`output-styles/` 以软链接放进 `~/.claude/`，之后 `git pull` 即更新。
- 已存在的同名文件不会被覆盖；加 `--force` 会先备份到 `~/.claude/backup-<时间>/` 再替换。
- `settings.json` 只在 `~/.claude/settings.json` 不存在时复制；已存在时只打印差异，由你手动合并。

## 文件说明

| 路径 | 作用 |
| --- | --- |
| `CLAUDE.md` | 全局规则：默认零注释、优先检索与查原始资料、编号选项与先讨论后实现、不自动提交、不加 AI 署名、iOS 不关签名、只检查改动文件、事故教训写成规则、设计文档收尾、Superpowers 用法 |
| `settings.json` | 读取 `.env` 前询问、默认 `acceptEdits`、关闭提交和 PR 署名、启用 5 个插件 |
| `agents/` | 子 agent：`planner`、`architect`（只读）、`tdd-guide`、`security-reviewer`、`build-error-resolver`、`e2e-runner`、`refactor-cleaner`、`doc-updater` |
| `commands/cc.md` | `/cc` 快速模式：跳过设计流程，最多问 1–2 个问题就动手 |
| `commands/handoff.md` | `/handoff`：调用 `session-handoff` 生成交接说明 |
| `commands/pr.md` | `/pr <目标分支>`：从当前分支创建 PR |
| `commands/update-pr.md` | `/update-pr [编号]`：按最新 diff 更新 PR 标题和描述 |
| `commands/gp.md` | `/gp [提交信息]`：提交所有改动并推送到当前分支（只在你主动调用时执行） |
| `output-styles/structural-thinking.md` | 分层、结构化的表达风格，可在 `/output-style` 中选择 |

## 插件

`settings.json` 的 `enabledPlugins` 启用以下插件，都来自官方市场 `claude-plugins-official`：

| 插件 | 用途 |
| --- | --- |
| `superpowers` | 脑暴、设计文档、实施计划、子 agent 驱动执行、TDD、调试等工作流 |
| `context7` | 查询库和框架的最新文档 |
| `code-simplifier` | 简化和清理刚写好的代码 |
| `linear` | 读写 Linear 的 issue |
| `vercel` | Vercel 部署与项目操作 |

`enabledPlugins` 只负责开关，不会自动安装。`./install.sh --plugins` 会帮你安装；也可以手动安装：

```bash
# 官方市场在第一次打开交互式会话时会自动添加；如果没有：
claude plugin marketplace add anthropics/claude-plugins-official

claude plugin install superpowers@claude-plugins-official
claude plugin install context7@claude-plugins-official
claude plugin install code-simplifier@claude-plugins-official
claude plugin install linear@claude-plugins-official
claude plugin install vercel@claude-plugins-official
```

在 Claude Code 里也可以用 `/plugin install <名字>@claude-plugins-official`。

## 规则怎么演进

出了事故，就把教训写成规则：只对某个项目成立的，写进那个项目的 `AGENTS.md`；在两个以上项目都成立的，才上升到这里的 `CLAUDE.md`；可重复的流程做成 skill，放进 `skills` 仓库。
