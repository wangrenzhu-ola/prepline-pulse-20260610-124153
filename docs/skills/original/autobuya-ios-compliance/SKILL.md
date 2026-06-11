---
name: autobuya-ios-compliance
description: "Flutter iOS 合规实现与审查；支持通过 review compliance / 审查 iOS 合规逻辑 / 检查 ATT 与权限链路 这类简单 prompt 进入逻辑审查模式。配置权限、ATT、协议入口、数据持久化；ATT、相机、相册、麦克风均为 Stage 3A 必配权限项，不做适用性跳过；若项目已有相关代码，则优先审查 ATT 时序、权限请求顺序、相对路径持久化、协议入口可用性等实现逻辑，并默认边审边改；只有明确要求只审查不改时才只输出报告。"
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
---

# autobuya-ios-compliance

> **本 skill 的定位**：Flutter iOS **Stage 3A 合规**实现与审查（ATT、权限、相对路径持久化、协议入口）。
> tracker 字段 SSOT：`autobuya-plan/reference-stage3-artifact-templates.md`。
> Stage 5 专项复核**必须再次调用本 skill**，不可用 `autobuya-code-review` 代替。

Flutter iOS 应用合规和平台特定实现指南。涵盖 ATT 流程、权限配置、沙盒安全持久化。

## 0. 单独调用时

先 Read `.claude/stage3/compliance_tracker.md` + `autobuya-plan/reference-shallow-probe-ban.md`；恢复时若读 `CLAUDE_STATE.md`，必须先读 `## Active Executors` 再读 Pointer。禁止只读 STATE 就宣称合规已完成。无 tracker 则按 `reference-stage3-artifact-templates.md` 初始化。

## 重要边界

- **Compliance Contract Checklist** 为本 skill 独占 SSOT。
- 审查默认**边审边改**；仅当调用方明确要求「只审查不改」时才只出报告。
- 与 `autobuya-code-review` / `autobuya-project-review` 分工见 `autobuya-code-review/references/skill-boundaries.md`。
- 本 skill 的 iOS 合规结论不考虑 `.storekit`、StoreKit Configuration 或本地沙盒测试配置文件是否存在。

## Supporting References

| 文件 | 职责 |
|------|------|
| `~/.claude/skills/autobuya-plan/reference-stage3-artifact-templates.md` | `compliance_tracker.md` 字段合同 |
| `autobuya-code-review/references/skill-boundaries.md` | 与 code-review / project-review / Stage 5 分工 |
| 本 skill 正文 | 实现/审查流程、checklist 条目、命令入口 |

## 产物回写协议

- Stage 3A Flutter 的 phase、compliance requirement、blocker、verification evidence 与 contract checklist，禁止只留在对话里。
- 下列 `.claude/...` 产物均指**当前目标项目根目录**下的路径（`$PROJECT_ROOT/.claude/...`），不是用户 home 目录；禁止到 `~/.claude/` 查找或写入这些项目运行产物。
- 至少同步到：
  - `.claude/stage3/compliance_tracker.md`
  - `.claude/test_matrix.md`
  - `.claude/event_log.ndjson`
  - 若影响路径重建、资源回填、权限后回刷或删除语义，`.claude/stage2/regression_matrix.md`
  - 若影响协议入口、设置页或其他 UI surface，`.claude/stage4/layout_audit.md`
- 以 `~/.claude/skills/autobuya-plan/reference-stage3-artifact-templates.md` 作为 Stage 3 tracker 字段 SSOT；历史 tracker 缺段、字段漂移或旧格式残留时，先按 supporting file 补齐再回写
- Stage 3 子任务只准备 tracker handoff，不直接写 `.claude/CLAUDE_STATE.md`；由编排层在 `claude_state_handoff_ready` 收口后统一合并
- `Compliance Contract Checklist` 与 `Compliance Contract Evidence Map` 必须成对回写；ATT、相机、相册、麦克风权限项不得写 `n_a`，必须是 `passed` 或 `failed`；`n_a` 仅允许用于 stack-specific 非权限项，且必须写原因
- `.claude/test_matrix.md` 中本次触达的功能 / 页面 / 联动测试条目必须写最终状态 `passed / failed / pending_recheck / not_applicable`；ATT、相机、相册、麦克风权限验证不得写 `not_applicable`，其他允许的 `not_applicable` 必须附原因
- 若任一 contract checklist 条目、evidence 或 blocker 未写回 tracker，不得宣称本 skill 已完成。

## 执行方式（实现或审查）

执行本命令时，必须先判断项目当前是否已存在 iOS 合规相关代码（通过 `Grep` / `Glob` / `Read` 搜索 `app_tracking_transparency`、`NSUserTrackingUsageDescription`、`permission_handler`、`getApplicationDocumentsDirectory`、用户协议 WebView 等关键词和文件）。

- **若已存在相关代码**：进入**审查模式**。审查重心必须放在 ATT 请求时序、权限请求顺序、拒绝后的降级逻辑、相对路径持久化、运行时路径重建、协议入口可访问性、相关页面返回后的状态一致性等**实现逻辑**。发现不符合规范的地方，必须在报告中明确指出问题位置、原因和修复建议，并**直接修改代码修复**。只有当调用方明确要求“只审查不改”时，才只输出审查报告。
- **若不存在相关代码**：进入**实现模式**。按照下方「实现模式执行流程」完整从零实现，不得省略 ATT、相机、相册、麦克风权限配置。

### 审查模式边界（必须遵守）

- 调用审查时，默认审的是**代码逻辑、请求时序、状态恢复和合规链路正确性**，不是优先审权限文案是否“像模板”、协议页面文案润色是否充分、UI 装饰是否够丰富。
- 审查范围只围绕 ATT、权限、持久化和协议入口；不得把签名、证书、Bundle ID、包名、`.storekit` 文件配置或 StoreKit Configuration 文件存在性作为默认结论维度。
- 只要权限文案、ATT 文案、协议占位内容**不会导致审核风险、权限用途错误、功能链路错误或误导用户**，就不要把它们当成主问题。
- ATT、相机、相册、麦克风是本 Stage 3A 清单列出的必配权限项，不做适用性跳过；缺少对应配置、请求链路或验证证据时，必须判为 `failed` 并直接补齐。
- 文案/展示类问题，只有在以下情况才升级为有效问题：
  - 与真实功能不匹配，存在明显审核风险；
  - 直接导致权限链路、协议访问、图片读取/保存或数据恢复失败；
  - 造成明显的状态不同步、错误提示、不可恢复流程或错误降级。
- 协议入口是默认审查项；必须确认用户协议/隐私协议入口存在、应用内可访问、WebView 或等价应用内承载可稳定加载。协议入口视觉、提示文案措辞、轻微排版问题不得压过 ATT、权限、持久化和协议可访问性这些主逻辑审查。

无论哪种模式，最终都必须通过 `flutter analyze`。

在进入实现或审查前，必须先读取：
- `.claude/project_harness.md`，确认 `tech_stack: flutter`、Required Commands、Layout Guardrails
- `.claude/test_matrix.md`，确认 ATT、权限、协议入口、相对路径持久化对应的验证项
  - 必须区分：功能测试（权限/ATT 逻辑）、页面测试（协议入口/布局）、联动测试（权限结果 -> 页面回显 / 持久化）
- `.claude/event_log.ndjson` 最后 20 行，恢复最近一次权限、测试或恢复失败证据
- 若任一 harness 工件缺失，先补齐再继续

## 实施前子规划（必须）

- 在开始实现或审查前，先把本次子计划写入 `.claude/stage3/compliance_tracker.md` 的 Planning / Next Actions 区域
- 子计划至少包含：
  - Scope：本次涉及 ATT、权限、持久化、协议入口中的哪些项
  - Files：准备修改或重点审查的文件清单
  - Order：执行顺序
  - Verification：准备执行的功能测试 / 页面测试 / 联动测试 / analyze / 布局检查
  - Risks：权限文案、图片/文件相对路径迁移、协议入口可访问性、小屏布局风险、资源回填/回显与删除清理风险
- 如果进入审查模式，也必须先写审查子计划，再开始读代码
- 实现或审查完成前，必须把下列条目回写到 `.claude/stage3/compliance_tracker.md` 的 `Compliance Contract Checklist`，不能只写笼统“已完成”：
  - `att_requested_at_app_start`
  - `att_prefixed_storage_key`
  - `tracking_usage_description_localized`
  - `permission_keys_complete`
  - `permission_copy_matches_real_usage`
  - `podfile_macros_configured`
  - `relative_path_storage_only`
  - `runtime_path_rebuild_correct`
  - `image_refill_uses_rebuilt_full_path`
  - `privacy_policy_entry_present`
  - `user_agreement_entry_present`
  - `protocol_webview_accessible`
  - `small_screen_protocol_layout_safe`
- 每一项都必须写成 `passed` / `failed` / `n_a`，并附至少一个 evidence file 或 evidence test
- 进入**审查模式**时，以下条目必须作为**逻辑主审项**优先核对并给出证据：`att_requested_at_app_start`、`att_prefixed_storage_key`、`permission_keys_complete`、`permission_copy_matches_real_usage`、`podfile_macros_configured`、`relative_path_storage_only`、`runtime_path_rebuild_correct`、`image_refill_uses_rebuilt_full_path`、`protocol_webview_accessible`
- 进入**审查模式**时，以下条目默认属于**展示次审项**：`tracking_usage_description_localized`、`privacy_policy_entry_present`、`user_agreement_entry_present`、`small_screen_protocol_layout_safe`；除非它们已经影响审核、理解、可访问性或真实功能链路，否则不要把它们当成主结论
- ATT 相关 checklist 不得写 `n_a`：`att_requested_at_app_start`、`att_prefixed_storage_key`、`tracking_usage_description_localized` 必须按 `passed / failed` 处理；缺少 `NSUserTrackingUsageDescription`、ATT 请求代码或前缀存储键均为失败。
- 若任一必做项不是 `passed`，本次 skill 不得宣告完成；`n_a` 只允许用于 stack-specific 非权限项。

> 本技能提供 iOS 特定实现细节的**方法**。架构、命名和 UI 规则见 `CLAUDE.md`、`full-auto-create` 和 `autobuya-ui-polish`。

## 使用方式

```text
/autobuya-ios-compliance
```

若项目里已经有 iOS 合规相关代码，以下这类简单调用也应理解为**逻辑审查优先**，而不是优先检查文案润色或产物包装：

```text
/autobuya-ios-compliance review
/autobuya-ios-compliance 审查 iOS 合规逻辑
/autobuya-ios-compliance 检查 ATT 与权限链路
/autobuya-ios-compliance review compliance
```

## 1. 应用追踪透明度（ATT）

### 强制口径

- ATT 是 Stage 3A 必配权限链路，不做适用性跳过。
- 即使当前产品没有广告功能，也必须配置 `app_tracking_transparency`、`NSUserTrackingUsageDescription`、ATT 启动请求、前缀存储键和 Podfile 宏，并验证请求时序。
- 审查时不得把 ATT 标记为 `n_a`；缺少任何 ATT 配置或证据均按 `failed` 处理并补齐。

### 时序

- **在 `runApp()` 之前请求 ATT**：在 `main()` 函数中，调用 `WidgetsFlutterBinding.ensureInitialized()` 之后、`runApp()` 之前，直接 `await` ATT 请求方法。
- 确保首次启动时 ATT 原生弹窗**一定**出现，不进入主界面后再延迟触发。
- 虽然阻塞了启动流程，但循环重试机制能保证弹窗被调起后才继续运行应用。

### 流程（runApp 前执行）

1. 在 `main()` 中调用 `WidgetsFlutterBinding.ensureInitialized()`。
2. `await` ATT 请求函数。
3. ATT 请求函数内部：
   - 读取 `SharedPreferences` 中名为 `{appName}AttRequested` 的标志（**所有变量和存储键必须以应用名作为前缀**，而非通用键）。
   - 如果为 `true`，跳过 — 已请求过一次。
   - 如果尚未请求：
     - 在生成当前项目代码时，先确定一个 **15-30** 之间的具体最大重试整数，并把这个固定值直接写进代码。
     - 调用 `trackingAuthorizationStatus()`。
     - 如果状态为 `notDetermined`，延迟 200ms 后调用 `requestTrackingAuthorization()`。
     - 若结果不再是 `notDetermined`，将标志写入 `SharedPreferences` 并退出循环。
     - 若仍是 `notDetermined`，计数器加一，延迟 150ms 后继续下一次循环。

### 代码骨架要求

不要直接复制固定函数名、固定变量名、固定键名或整段参考实现。必须按**当前应用名**、**当前工程结构**、**当前入口文件**重写，并满足以下骨架约束：

1. 在 `main()` 中调用 `WidgetsFlutterBinding.ensureInitialized()`
2. 在 `runApp()` 前 `await` ATT 请求封装函数
3. ATT 请求封装函数内部必须：
   - 平台判断：非 iOS 直接返回
   - 读取 `SharedPreferences`
   - 使用**带应用名前缀**的布尔键记录“是否已请求过 ATT”
   - 若已请求过，直接返回
   - 若未请求过，按上一步已经确定并写死在代码里的 ATT 最大重试整数执行循环
   - 每轮先读取 `trackingAuthorizationStatus()`
   - 若仍是 `notDetermined`，先延迟 200ms，再请求 `requestTrackingAuthorization()`
   - 若结果不再是 `notDetermined`，写入“已请求”标志并退出
   - 若状态已不是 `notDetermined`，也要写入“已请求”标志并退出
   - 若仍未决，计数器加一，延迟 150ms 再继续

> **命名规则**：所有变量、函数、SharedPreferences 键必须带应用名前缀，前缀来自当前应用真实名称；禁止直接复用 `autobuyaResolveAttConsent`、`autobuyaAttRequested`、`autobuyaAttAttemptCount` 这类固定示例名。系统 API 名如 `requestTrackingAuthorization()` 属于框架方法名，可直接调用；禁止的是你自己新增的包装函数名、状态变量名、存储键名使用无前缀通用命名。

### Info.plist

```xml
<key>NSUserTrackingUsageDescription</key>
<string>[Write one clear, natural English sentence of about 60-70 words that explicitly names the app, explains the ATT tracking-permission purpose in the context of this product, clarifies what user experience or service improvement depends on it, and avoids vague privacy boilerplate, generic advertising language, or empty template phrasing.]</string>
```

> **严禁输出完整固定文案模板让下游直接照抄。** 这里只能保留结构约束：必须是英文、必须点名当前应用、必须对应 ATT 权限用途、必须避免空泛隐私套话。最终文本应根据软件主题、数据用途、广告/归因/分析场景单独生成。

### 关键规则

- **只使用 iOS 原生 ATT 弹窗**，禁止添加任何自定义解释弹窗或预弹窗。
- 在 `main()` 中、`runApp()` 之前触发，确保首次启动必须弹出。
- 不要所有项目都固定写死 20 次；应在生成当前项目代码时先确定一个 15-30 之间的具体重试上限，并把这个固定值直接写进代码，避免模板化，同时仍保持有限重试。
- 每次安装只请求一次（受标志保护）。
- 在收集任何追踪数据前展示 ATT。
- 使用 `app_tracking_transparency` 包。

## 2. iOS 权限配置

### Info.plist 模板

不要照抄文本，要基于软件扩展完善权限文本描述。这里的 XML 只能当字段结构示例，不可逐字复用整句；必须把 `[App Name]`、用途、资源使用场景都换成当前应用真实语义。

```xml
<!-- 相机 -->
<key>NSCameraUsageDescription</key>
<string>[English only; mention the real app name; describe the actual camera use in this product; no template phrasing.]</string>

<!-- 麦克风 -->
<key>NSMicrophoneUsageDescription</key>
<string>[English only; mention the real app name; describe the actual microphone/audio use in this product; no template phrasing.]</string>

<!-- 照片库 - 写入 -->
<key>NSPhotoLibraryAddUsageDescription</key>
<string>[English only; mention the real app name; describe the actual save/export-to-library use and user-visible benefit; no template phrasing.]</string>

<!-- 照片库 - 读取 -->
<key>NSPhotoLibraryUsageDescription</key>
<string>[English only; mention the real app name; describe the actual library import/read use in this product; no template phrasing.]</string>

<!-- ATT -->
<key>NSUserTrackingUsageDescription</key>
<string>[English only; about 60-70 words; mention the real app name; describe the ATT tracking-permission purpose in this product's compliance context; explain the concrete user-facing benefit or service improvement; no vague privacy boilerplate, generic advertising language, or template phrasing.]</string>
```

### Podfile permission_handler 宏

在 `ios/Podfile` 的 `post_install` 块中添加：

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)

    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_MICROPHONE=1',
        'PERMISSION_PHOTOS=1',
        'PERMISSION_APP_TRACKING_TRANSPARENCY=1',
      ]
    end
  end
end
```

### 权限原则

- `Info.plist` 中的描述必须与实际应用功能完全匹配。
- 当用户拒绝权限时，只允许做克制说明与功能降级；**绝不**展示任何设置引导，绝不提供“去设置 / 打开设置 / 前往设置”按钮，也不得调用系统设置跳转。
- 应用必须优雅降级 — 核心功能在可选权限缺失时仍然可用。
- 涉及相册导入或保存到系统相册时，权限顺序必须严格正确：**先检查当前授权状态，需要时先触发系统权限请求，再根据结果继续、降级或提示**。禁止尚未请求权限就直接展示“无权限”错误。
- 相册相关失败处理必须使用友好提醒、轻量反馈或应用内替代/降级反馈；**禁止直接展示爆红错误文案**。权限拒绝后的下一步不得引导用户去设置、不得展示设置按钮、不得跳转系统设置；只有真正的不可恢复异常才允许进入错误态，且文案仍需克制、可理解。
- 确保 `Info.plist` 描述、`Podfile` 宏和 Dart 权限请求三者同步；ATT、相机、相册、麦克风均为必配权限，缺任何一项都不得写 `n_a`。

## 3. 数据持久化 — 沙盒安全策略

### 核心规则

应用必须能够在重启后正确定位所有存储的资源文件，尽管 iOS 沙盒路径可能变化。

### 存储策略

- **仅用相对路径**：存储文件名 + 相对文件夹关系。**绝不存储绝对路径**。
  - **错误示例**：`"/Users/xxx/Library/.../Documents/image.jpg"` — iOS 沙盒路径在重启后可能变化，导致文件永久丢失。
  - **正确示例**：`"images/20250413_abc123.jpg"` — 只记录相对于应用文档目录的路径。
- **启动时重建路径**：每次启动使用 `getApplicationDocumentsDirectory()` 动态拼接出完整路径。
  ```dart
  final directory = await getApplicationDocumentsDirectory();
  final fullPath = join(directory.path, relativePath);
  ```
- **回填显示禁忌**：若数据库或持久化层保存的是 `photos/xxx.jpg` 这类相对路径，任何资源回填、回显或二次使用场景显示图片/文件时，禁止直接 `File(relativePath)`、`Image.file(File(relativePath))` 或其他等价写法；必须先基于应用文档目录重建完整路径，再读取文件。
- **唯一文件 ID**：使用 UUID 或时间戳保证文件名唯一性，避免覆盖。
- **资源关联**：通过键值映射将图片资源与数据项关联，删除数据时同步清理磁盘文件。
- **禁止行为**：
  - 禁止将 `File(path).path` 的绝对路径直接写入数据库或 SharedPreferences。
  - 禁止依赖 `path_provider` 返回的绝对路径在下次启动时仍然有效。

### 历史记录管理

- 新记录必须立即刷新到历史列表。
- 所有记录按时间倒序显示。
- 通过唯一 ID 删除，防止误删错误项。
- 删除时同时清理磁盘上的关联图片/资源文件。

## 4. 网络权限与请求时序

### 目标

确保核心网络功能不会因 iOS 无线数据权限尚未授权或网络切换而失败。

### 策略

- **状态感知**：在启动和关键请求前检查网络状态。
- **请求队列**：当网络不可用时，队列待处理请求并向用户显示非阻塞自定义通知。
- **自动恢复**：监听网络状态变化；当连接恢复时自动重试队列中的请求。

### 时序顺序

```
runApp() -> 第一帧 -> ATT 请求 -> 网络状态服务初始化 -> 核心网络业务初始化
```

网络状态服务必须在 ATT 流程完成后建立，但在核心网络业务初始化之前。

## 5. 对话框样式规则

- **系统对话框（必须使用原生样式）**：
  - ATT 隐私追踪对话框
  - 相机、照片库、麦克风权限对话框
  - 其他系统级对话框（分享表单、评分提示）

- **应用对话框（必须使用自定义主题样式）**：
  - SnackBar / Toast 通知
  - 确认对话框、底部操作表单
  - 加载指示器、错误消息
  - 错误对话框应样式化为警告对话框，而非错误对话框

- **自定义对话框要求**：
  - 匹配应用主题色
  - 与整体 UI 设计语言一致
  - 包含适当的动画和过渡效果

## 6. 用户协议与隐私协议 WebView 入口

- 通过应用内置 WebView 展示，而非外部浏览器，更不是本地页面展示。
- 开发期间使用 `https://developer.apple.com/support/terms/` 作为占位符。
- 必须实现预加载或自动重试以防止首次加载白屏（尤其是当网络权限待定时）。
- 协议入口是 iOS 合规审查项；`.storekit` / StoreKit Configuration 文件存在性不是 iOS 合规审查项。

## 最低 iOS 版本

- iOS 14.0
- 应用默认使用浅色模式，覆盖系统设置。

---

## 审查输出要求（调用 review 时必须满足）

- 必须优先回答这些问题，而不是先点评权限文案或协议文字：
  - ATT 是否真的发生在 `runApp()` 之前？是否存在首次启动漏弹、晚弹、异步未等待的问题？
  - ATT 请求是否只请求一次？前缀键、重试上限、退出条件是否正确？
  - 相机/相册/麦克风链路是否严格遵守“先检查/请求权限，再继续或降级”的顺序？
  - 用户拒绝权限后，是否只做克制说明与功能降级，而不是直接报错、卡死、引导或跳转系统设置？
  - 图片/文件路径是否只存相对路径？重启后是否能正确重建并回填？
  - 删除、资源回填、资源回显或二次使用时，是否会因为路径处理错误而丢图、错图或残留脏数据？
- 审查结论必须显式包含：
  - `总体结论`：只能写 `符合要求` / `不符合要求` / `需完善`。
  - `符合要求`：列出 ATT、权限、持久化、协议入口中已满足的项目，并附文件或验证证据。
  - `不符合要求`：只列 ATT、权限、持久化、协议入口中的真实不符合项，并写文件/位置、原因、影响和修复动作。
  - `需完善 / 建议`：只放不阻塞的权限文案、降级反馈、持久化回填体验、协议入口体验或验证补强。
  - `修复`：明确 `已修复` / `建议修复` / `待验证`，并写验证证据。
- 不得把签名、证书、Bundle ID、包名、StoreKit Configuration 或 `.storekit` 文件配置写入默认 `不符合要求`；协议入口缺失或应用内不可访问仍应写入 `不符合要求`。
- 如果逻辑没问题，但权限文案、协议标题、占位页面内容还不理想，要明确标成**次要问题**，不要把它们写成“iOS 合规未完成”。
- 如果项目用的是项目化权限文案或协议内容，只要真实用途匹配、权限顺序正确、链路可用，就不要因为它和模板示例不一样而判失败。

## 审查模式执行流程

当项目已存在 iOS 合规相关代码时，进入审查模式。本模式下**默认边审边改**；只有当调用方明确要求“只审查不改”时，才只输出审查报告。

### Step 1: 扫描与定位

- 审查或实现结束后，必须同步：
  - 更新 `.claude/test_matrix.md` 中合规相关验证项状态
  - 向 `.claude/event_log.ndjson` 追加 `task_completed`、`tracker_synced`、`test_passed` / `test_failed`、`blocker_recorded`
  - 若修改了协议入口或设置页布局，更新 `.claude/stage4/layout_audit.md`

使用 `Grep`/`Glob`/`Read` 全面扫描项目中的 iOS 合规相关代码：
- ATT：`main.dart` 中是否调用 ATT 请求函数、`app_tracking_transparency` 导入
- 权限：`Info.plist` 中的 `NSUserTrackingUsageDescription`、`NSCameraUsageDescription`、`NSMicrophoneUsageDescription`、`NSPhotoLibraryUsageDescription`、`NSPhotoLibraryAddUsageDescription`
- Podfile：`ios/Podfile` 中 `PERMISSION_*` 宏配置
- 持久化：`getApplicationDocumentsDirectory()` 使用、图片/文件保存服务、相对路径存储、SharedPreferences/Hive/SQLite 中的路径处理、资源回填/回显场景的图片显示、删除时磁盘资源清理
- 协议：用户协议/隐私协议 WebView 入口，而非外部浏览器，更不是本地页面展示
- webview 页面是否支持自动重试

### Step 2: 逐项维度审查

对每个维度，**必须实际 Read 相关文件**，逐条对照规范判断：

#### ATT 审查
- [ ] `main()` 中、`runApp()` 之前是否 `await` ATT 请求函数？
- [ ] 是否实现了一个在生成时确定、并被直接写入代码的 ATT 有限重试上限（15-30 次之间）？
- [ ] 所有 ATT 相关变量和 SharedPreferences 键是否带有**应用名前缀**？
- [ ] 是否只使用 iOS 原生 ATT 弹窗，**无自定义预弹窗/解释弹窗**？
- [ ] `Info.plist` 中 `NSUserTrackingUsageDescription` 是否为英文且与应用功能相关？
- [ ] 是否每次安装只请求一次（有标志位保护）？

#### 权限配置审查
- [ ] `Info.plist` 是否包含 ATT、相机、相册、麦克风权限描述？
- [ ] 权限描述是否为英文且与实际功能完全匹配？
- [ ] `ios/Podfile` 中是否添加 `PERMISSION_CAMERA`、`PERMISSION_MICROPHONE`、`PERMISSION_PHOTOS`、`PERMISSION_APP_TRACKING_TRANSPARENCY` 宏？
- [ ] `Info.plist`、`Podfile`、Dart 代码三者是否同步？
- [ ] 用户拒绝权限时是否优雅降级（只说明与降级；不引导去设置、不提供设置按钮、不跳转系统设置）？
- [ ] 相册读取/写入链路是否先检查或请求权限，再进入成功/拒绝/失败分支？
- [ ] 是否不存在“尚未触发权限请求就先报权限错误”的顺序问题？
- [ ] 相册失败提示是否为友好提醒，而非爆红错误或高攻击性文案？

#### 数据持久化审查
- [ ] 所有文件/图片路径是否使用**相对路径**存储？
- [ ] 是否使用 `getApplicationDocumentsDirectory()` 在运行时动态重建完整路径？
- [ ] 文件名是否使用 UUID 或时间戳保证唯一性？
- [ ] 删除记录时是否同步清理磁盘上的关联文件？
- [ ] 历史记录是否按时间倒序显示？


#### 对话框样式审查
- [ ] 系统级对话框（ATT、相机/相册/麦克风权限）是否使用原生样式？
- [ ] 应用级对话框（SnackBar、确认框、加载指示器）是否使用自定义主题样式？
- [ ] 自定义对话框是否与整体 UI 设计语言一致？

#### 用户协议与隐私协议审查
- [ ] 是否提供应用内置 WebView 入口展示两个协议？
- [ ] 开发期间占位 URL 是否为 `https://developer.apple.com/support/terms/`？
- [ ] WebView 是否实现预加载或自动重试机制？

### Step 3: 输出审查报告

```markdown
## iOS 合规审查报告

### 总体结论
- 符合要求 / 不符合要求 / 需完善

### 符合要求
- ATT / 权限 / 持久化 / 协议入口中已经满足的项目，必须附文件或验证证据

### 不符合要求
- 只列 ATT、权限、持久化、协议入口中的真实不符合项；每项写文件/位置、原因、影响和修复动作

### 需完善 / 建议
- 不阻塞但可优化的权限文案、降级反馈、持久化回填体验、协议入口体验或验证补强

### 修复
- 已修复 / 建议修复 / 待验证，并写明验证证据
```

### Step 4: 处理审查结果

- **默认行为**：
  1. 按严重级别直接修复问题
  2. 修复后重新运行 `flutter analyze`
  3. 对修复的部分再次执行对应维度的审查，确认通过
  4. 输出更新后的审查结论与剩余风险
- **若调用方明确要求只审查不改**：
  1. 输出分层审查报告
  2. 不修改代码
  3. 清楚标出阻塞问题、风险问题与建议项

---

## 实现模式执行流程

当项目尚未存在 iOS 合规相关代码时，按以下步骤完整实现：

### Step 1: ATT 配置
- 在 `main()` 中、`runApp()` 之前 `await` ATT 请求函数
- ATT 请求函数内使用 `SharedPreferences` 存储 `{appName}AttRequested` 标志
- 实现一个在生成时确定、并被直接写入代码的 ATT 有限重试上限（15-30 次之间），直到状态不再是 `notDetermined`
- 在 `Info.plist` 中添加英文 `NSUserTrackingUsageDescription`
- 在 `ios/Podfile` 中添加 `PERMISSION_APP_TRACKING_TRANSPARENCY=1`
- **只使用 iOS 原生 ATT 弹窗**，禁止添加自定义预弹窗
- 确保描述文案与应用功能相关，不逐字复制模板

### Step 2: 权限配置
- 根据应用实际需求在 `Info.plist` 中添加权限描述
- 在 `ios/Podfile` 中添加 `permission_handler` 宏
- 确保权限描述与实际功能完全匹配
- 确保 `Info.plist`、`Podfile` 和 Dart 权限请求三者同步

### Step 3: 数据持久化配置
- 确保所有文件存储使用相对路径
- 使用 `getApplicationDocumentsDirectory()` 动态重建路径
- 使用 UUID 或时间戳保证文件名唯一性
- 实现历史记录管理（按时间倒序、唯一 ID 删除）

### Step 4: 对话框样式配置
- 确保系统对话框使用原生样式
- 确保应用对话框使用自定义主题样式
- 实现自定义对话框组件
- 确定非系统权限隐私弹窗需要自定义

### Step 5: 用户协议与隐私协议两个协议 **必须有**
- 实现应用内置 WebView 展示
- 使用 `https://developer.apple.com/support/terms/` 作为占位符
- 实现预加载或自动重试机制

### Step 6: 自审自检（必须）
完成 iOS 合规配置后，检查以下项目：

#### ATT 配置检查
- [ ] ATT 请求是否在 `main()` 中、`runApp()` 之前执行？
- [ ] 是否使用了一个在生成时确定、并被直接写入代码的 ATT 有限重试上限（15-30 次之间），同时确保弹窗被调起？
- [ ] 所有 ATT 相关变量和 SharedPreferences 键是否带有应用名前缀？
- [ ] 是否使用 `SharedPreferences` 存储标志？
- [ ] `Info.plist` 中是否添加英文 `NSUserTrackingUsageDescription`？
- [ ] 描述文案是否与应用功能相关（非模板复制）？
- [ ] 是否每次安装只请求一次？
- [ ] 是否只使用 iOS 原生 ATT 弹窗，无自定义预弹窗？

#### 权限配置检查
- [ ] `Info.plist` 中是否添加所有需要的权限描述？（ATT、相机、相册、麦克风权限一定需要）
- [ ] 权限描述是否与实际功能完全匹配？
- [ ] `ios/Podfile` 中是否添加 `permission_handler` 宏？
- [ ] `Info.plist`、`Podfile` 和 Dart 权限请求是否同步？
- [ ] 用户拒绝权限时是否优雅降级（只说明与降级；不引导去设置、不提供设置按钮、不跳转系统设置）？

#### 数据持久化检查
- [ ] 是否所有文件存储使用相对路径？
- [ ] 是否使用 `getApplicationDocumentsDirectory()` 动态重建路径？
- [ ] 文件名是否使用 UUID 或时间戳保证唯一性？
- [ ] 历史记录是否按时间倒序显示？
- [ ] 删除记录时是否同时清理关联文件？

#### 对话框样式检查
- [ ] 系统对话框是否使用原生样式？
- [ ] 应用对话框是否使用自定义主题样式？
- [ ] 自定义对话框是否匹配应用主题色？
- [ ] 自定义对话框是否有适当的动画？

#### 用户协议检查
- [ ] 是否使用应用内置 WebView 展示？
- [ ] 是否使用 `https://developer.apple.com/support/terms/` 作为占位符？
- [ ] 是否实现预加载或自动重试机制？

### Step 8: 修复问题
- 如果自审发现问题，立即修复
- 修复后再次自审，确保通过
