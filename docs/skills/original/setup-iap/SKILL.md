---
name: setup-iap
description: Flutter iOS 内购实现与审查；支持从零实现，也支持通过“review iap / 审查内购逻辑 / 审查内购入口 / 检查购买流程”进入审查模式。默认 27 个商品数据（473900–473926）；若项目已有 IAP 代码，则审查购买链路、发币幂等、余额同步，并审查应用内是否具备可发现、可跳转的内购入口（balance_entry_navigation），发现问题直接改代码。
tools:
  - Read
  - Write
  - Edit
  - Bash
  - Grep
  - Glob
  - Skill
  - Agent
---

# Flutter iOS 内购实现命令

> **本 skill 的定位**：Flutter **Stage 3B IAP** 实现与审查；`iap_tracker.md` checklist 为 SSOT。
> Stage 5 **必须再次调用本 skill** 专项复核。

在当前 Flutter iOS 项目中实现完整内购能力：三层容错初始化、商品展示、购买流程、金币/虚拟货币与持久化，并严格符合 App Store 审核与本项目 iOS 规范。

## 重要边界

- **IAP Contract Checklist** 独占；不用 `autobuya-code-review` skill 代替 Stage 5 IAP 关门。
- 分工见 `autobuya-code-review/references/skill-boundaries.md`。
- **示例代码勿复用**：正文中的 Dart 代码块**仅说明语义与审查要点**；禁止整段照抄进项目，禁止复用示例里的变量名、类型名、返回值或结构。实现须按项目既有 Store/分层与命名自行编写；该改名就改名。

## Supporting References

| 文件 | 职责 |
|------|------|
| `autobuya-plan/reference-stage3-artifact-templates.md` | `iap_tracker.md` 字段合同 |
| `autobuya-code-review/references/skill-boundaries.md` | 与 code-review / project-review / Stage 5 |
| 本 skill 正文 | 实现/审查、商品数据、命令入口 |

## 产物回写协议

- Stage 3B Flutter 的 phase、IAP requirement、唯一花费点、blocker、verification evidence 与 contract checklist，禁止只留在对话里。
- 下列 `.claude/...` 产物均指**当前目标项目根目录**下的路径（`$PROJECT_ROOT/.claude/...`），不是用户 home 目录；禁止到 `~/.claude/` 查找或写入这些项目运行产物。
- 至少同步到：
  - `.claude/stage3/iap_tracker.md`
  - `.claude/stage3/iap_closeout_review.md`
  - `.claude/feature_coverage_matrix.md`
  - `.claude/test_matrix.md`
  - `.claude/event_log.ndjson`
  - 若影响余额入口、内购页、商品卡片或其他 UI surface，`.claude/stage4/layout_audit.md`
- 以 `~/.claude/skills/autobuya-plan/reference-stage3-artifact-templates.md` 作为 Stage 3 tracker 字段 SSOT；历史 tracker 缺段、字段漂移或旧格式残留时，先按 supporting file 补齐再回写
- Stage 3 子任务只准备 tracker handoff，不直接写 `.claude/CLAUDE_STATE.md`；由编排层在 `claude_state_handoff_ready` 收口后统一合并
- `IAP Contract Checklist` 与 `IAP Contract Evidence Map` 必须成对回写；`n_a` 只允许用于真实不适用项，且必须写原因
- `.claude/test_matrix.md` 中本次触达的功能 / 页面 / 联动测试条目必须写最终状态 `passed / failed / pending_recheck / not_applicable`；`not_applicable` 必须附原因
- `.claude/stage3/iap_tracker.md`、`.claude/stage3/iap_closeout_review.md`、`.claude/test_matrix.md`、`.claude/event_log.ndjson` 必须登记 `skill_name: setup-iap`，或在结构化 evidence 中让 `verification_skill_names` 明确包含 `setup-iap`
- `.claude/stage3/iap_closeout_review.md` 必须独立回读 tracker / evidence map / test_matrix / feature_coverage_matrix / stage4 layout refs 后写出 `allowed_to_close_stage3_branch: yes/no`
- 若任一 contract checklist 条目、evidence、closeout decision、feature coverage 映射或 blocker 未写回对应产物，不得宣称本 skill 已完成。

## 执行方式（实现或审查）

执行本命令时，必须先判断项目当前是否已存在 IAP 相关代码（通过 `Grep` / `Glob` 搜索 `in_app_purchase`、`buyConsumable`、`queryProductDetails`、`purchaseStream` 等关键词）。

- **若已存在 IAP 代码**：进入**审查模式**。审查重心必须放在初始化链路、商品查询与缓存、购买流程、交易完成与状态清理、余额持久化、唯一花费点绑定、全局刷新、错误处理、页面返回后状态一致性等**实现逻辑**。发现不符合规范的地方，必须明确指出问题所在，并**直接修改代码修复**，不得仅给出建议后结束。
- **若不存在 IAP 代码**：进入**实现模式**。按照下方「实现要点」完整从零实现，不得省略任何步骤。

### 审查模式边界（必须遵守）

- 调用审查时，默认审的是**代码逻辑和实现正确性**，不是优先审商品数量、商品文案、价格表、美术图标或卡片装饰是否“像模板要求”。
- IAP 审查不关注 Xcode StoreKit Configuration 文件、`.storekit` 文件、沙盒配置文件或其他本地测试配置是否存在；这些只能作为本地测试辅助，缺失不得判为 `failed` / 不符合要求。
- 这里的“配置”只限代码内商品 ID、商品数据、入口与状态链路，不扩展为签名、Bundle ID、Capabilities、StoreKit 配置文件存在性审查。
- 只要现有商品数据、商品 ID、商品展示文案**不会导致购买链路错误、查询失败、余额错误、交易状态错误或审核风险**，就**不要**把它们当成主问题。
- 商品数据类问题，只有在以下情况才升级为有效问题：
  - 直接导致 `queryProductDetails`、购买、恢复、完成交易或余额发放失败；
  - 与当前 skill 的硬约束明确冲突，且会影响 IAP 正常运行或审核；
  - 造成明显的状态不同步、错误消费、重复购买、无入口、无刷新或不可恢复问题。
- 商品卡片视觉、logo 风格、价格文案、展示层包装，不得压过实现逻辑审查；除非它们已经阻塞理解、操作或审核。

无论哪种模式，最终都必须通过 `flutter analyze`。

在进入实现或审查前，必须先读取：
- `.claude/project_harness.md`，确认 `tech_stack: flutter`、Required Commands、Layout Guardrails
- `.claude/test_matrix.md`，确认购买链路、余额刷新、唯一花费点、商品卡片布局对应的验证项
  - 必须区分：功能测试（初始化/商品/余额规则）、页面测试（商品卡/购买页布局）、联动测试（购买 -> 发币 -> 页面刷新）
- `.claude/event_log.ndjson` 最后 20 行，恢复最近一次初始化失败、购买失败、overflow 或测试证据
- 若任一 harness 工件缺失，先补齐再继续

## 实施前子规划（必须）

- 在开始实现或审查前，先把本次子计划写入 `.claude/stage3/iap_tracker.md` 的 Planning / Next Actions 区域
- 子计划至少包含：
  - Scope：本次涉及初始化、商品数据、购买流程、余额、唯一花费点、内购 UI 的哪些项
  - Files：准备修改或重点审查的文件清单
  - Order：执行顺序
  - Verification：准备执行的功能测试 / 页面测试 / 联动测试 / analyze / 商品卡片布局检查
  - Risks：商品 code 替换、重复购买、`purchaseStream` 重复回调导致重复发币、余额不同步、商品卡片 overflow
- 在子计划中先明确唯一花费点绑定哪个现有功能，再开始实现
- 实现或审查完成前，必须把下列条目回写到 `.claude/stage3/iap_tracker.md` 的 `IAP Contract Checklist`，不能只写笼统“已完成”：
  - `three_layer_init`
  - `product_catalog_27_items`
  - `product_code_override_applied`
  - `purchase_flow_complete`
  - `transaction_cleanup_complete`
  - `coin_delivery_idempotent`
  - `virtual_currency_persistence`
  - `single_spend_point_bound`
  - `spend_point_cost_fixed_10`
  - `spend_point_notice_visible`
  - `balance_refresh_global`
  - `balance_entry_navigation`
  - `iap_entry_accessible_from_normal_flow`
  - `themed_product_logo_non_system_coin`
  - `iap_page_ui_complete`
  - `small_screen_card_layout_safe`
- 每一项都必须写成 `passed` / `failed` / `n_a`，并附至少一个 evidence file 或 evidence test
- 进入**审查模式**时，以下条目必须作为**逻辑主审项**优先核对并给出证据：`three_layer_init`、`purchase_flow_complete`、`transaction_cleanup_complete`、`coin_delivery_idempotent`、`virtual_currency_persistence`、`single_spend_point_bound`、`spend_point_cost_fixed_10`、`spend_point_notice_visible`、`balance_refresh_global`、`balance_entry_navigation`、`iap_entry_accessible_from_normal_flow`
- IAP 不要求交易历史或用户可见购买记录；只要求为发币幂等保留必要的内部已处理交易标记
- 进入**审查模式**时，以下条目默认属于**数据/展示次审项**：`product_catalog_27_items`、`product_code_override_applied`、`themed_product_logo_non_system_coin`、`iap_page_ui_complete`、`small_screen_card_layout_safe`；除非它们已经影响 IAP 逻辑、状态一致性、可操作性或审核风险，否则不要把它们当成主结论
- 若任一必做项既不是 `passed`，也不存在充分的 `n_a` 原因与证据，本次 skill 不得宣告完成

## 使用方式

```
/setup-iap
```

若项目里已经有 IAP 代码，以下这类简单调用也应理解为**审查模式**（边审边改），而不是优先检查商品表、美术或产物包装：

```text
/setup-iap review
/setup-iap 审查内购逻辑
/setup-iap 审查内购入口
/setup-iap 检查购买流程
/setup-iap review iap logic
/setup-iap review iap entry
```

其中 **`审查内购入口` / `review iap entry`** 表示：重点审查目标 App **是否已实现内购页，以及用户从常用界面能否明显进入内购页**（对应 checklist `balance_entry_navigation` / `iap_entry_accessible_from_normal_flow`），不是只审 `purchaseStream` 或发币逻辑；它要求的是购买入口，不是额外的内购说明页。

或附带自定义商品数据（每行一条，留空则使用下方默认 27 个商品）：

```
/setup-iap
<可选：多行商品数据，见下方格式>
```

## 默认商品数据（必须支持）

- **商品数量**：27 个
- **商品 ID 范围**：473900～473926
- **商品 ID 语义**：商品 ID 是 App Store Connect 中配置的完整 product identifier。必须按默认值或用户提供值原样使用，禁止拼接 bundleId、包名、软件名、项目名或任何前缀。
- **前 19 个**：普通商品
- **后 8 个**：促销商品
- **新用户初始化货币（商品）数量**: 100

若技能后未附带商品数据，**必须使用本默认配置**实现，不得留空、不生成半成品。

> **默认商品数据示例（参考实现用，仅代码标识符需按项目语义命名且全英文；商品 ID 字符串必须原样保留）**
>
> 下面是默认 27 个商品的数据，价格和数量对应关系默认下面数据（单位可在 UI 中按软件主题命名考虑命名等）：
>
> ```text 数据不要搞出多份分开，集中一起好修改管理
> # 19 个常规商品
> 473900 -> amount: 110,   price: $0.99,  promotion: false
> 473901 -> amount: 210,   price: $1.99,  promotion: false
> 473902 -> amount: 310,   price: $2.99,  promotion: false
> 473903 -> amount: 400,   price: $3.99,  promotion: false
> 473904 -> amount: 520,   price: $4.99,  promotion: false
> 473905 -> amount: 630,   price: $5.99,  promotion: false
> 473906 -> amount: 740,   price: $6.99,  promotion: false
> 473907 -> amount: 1000,  price: $8.99,  promotion: false
> 473908 -> amount: 1200,  price: $9.99,  promotion: false
> 473909 -> amount: 1600,  price: $12.99, promotion: false
> 473910 -> amount: 2000,  price: $15.99, promotion: false
> 473911 -> amount: 2600,  price: $19.99, promotion: false
> 473912 -> amount: 3300,  price: $24.99, promotion: false
> 473913 -> amount: 4200,  price: $29.99, promotion: false
> 473914 -> amount: 4900,  price: $34.99, promotion: false
> 473915 -> amount: 6000,  price: $39.99, promotion: false
> 473916 -> amount: 8000,  price: $49.99, promotion: false
> 473917 -> amount: 14000, price: $79.99, promotion: false
> 473918 -> amount: 14998, price: $99.99, promotion: false
>
> # 8 个促销商品
> 473919 -> amount: 520,   price: $1.99,  promotion: true
> 473920 -> amount: 800,   price: $2.99,  promotion: true
> 473921 -> amount: 1300,  price: $4.99,  promotion: true
> 473922 -> amount: 1500,  price: $5.99,  promotion: true
> 473923 -> amount: 2700,  price: $11.99, promotion: true
> 473924 -> amount: 2900,  price: $12.99, promotion: true
> 473925 -> amount: 7200,  price: $34.99, promotion: true
> 473926 -> amount: 17000, price: $79.99, promotion: true
> ```

## 自定义商品数据格式（可选）

当用户通过粘贴了商品数据，或消息中在 `/setup-iap` 后附带多行数据时，按以下约定解析（仅代码字段名可按项目语义命名；商品 ID 字符串本身禁止加任何前缀）：

- 每行一条商品。
- 字段含义：商品 ID、虚拟货币数量（金币/能量/燃料等）、本地参考价格、是否促销（true/false）。
- 商品 ID 必须逐字原样进入商品常量与查询集合；不得为了“规范”或“命名空间”做任何字符串拼接、替换、包装或派生。
- 实现时使用强类型模型与常量列表，代码中不出现中文字符；展示用的「金币/能量/燃料」等名称由应用主题或配置决定。

## 实现要点（展开版，避免实现走偏）

实现时应遵循 Flutter iOS 内购规范，按下列清单在项目内完整实现，不得省略或简化关键步骤。

## 审查：应用是否有内购入口（CRITICAL）

> 对应 `IAP Contract Checklist` 的 **`balance_entry_navigation`**。App Store 常因「审核找不到购买入口 / 入口不明显」拒审；实现 IAP 服务不等于用户能买到币。

**审查模式（含单独调用「审查内购入口」）必须执行：**

1. **定位内购页**
   - `Grep` / `Glob`：`shop`、`store`、`purchase`、`iap`、`coin`、`credit`、`wallet` 等路由名、页面类名、`routes:` / `GoRoute` / `Navigator.push` 目标。
   - 确认存在**可渲染商品列表**的内购页（非仅占位空页），且能接到 IAP 购买流程。
2. **枚举进入内购页的路径（至少 2 条，审核可发现）**
   - **余额入口**：所有展示余额的 Widget/页面，`onTap` / `InkWell` / `GestureDetector` 是否 `push` 到内购页（不能只显示数字不可点）。
   - **主导航入口**：Tab / Drawer / 设置 / 首页显眼按钮等，是否另有进入内购页的入口（避免只有深层隐藏路径）。
   - **内购页上的余额**：内购页内余额展示**不得**再跳转（避免循环）；审查时单独记录。
3. **可发现性（人工走查 + 代码证据）**
   - 从 `README.md` / PRD 认定的**主流程首屏**出发，是否在 **≤2 次点击**内能到达内购页；若不能，判 `balance_entry_navigation: failed` 并补入口。
   - 入口文案/图标是否与「充值 / 商店 / 加币」语义一致，避免审核员找不到购买能力。
4. **与唯一花费点关系**
   - 唯一花费点（扣 10 单位）的确认弹窗里，余额不足时是否引导去内购页（推荐，非强制）；若有引导，记入 evidence。
5. **回写**
   - 在 `.claude/stage3/iap_tracker.md` 的 `IAP Contract Evidence Map` 中，`balance_entry_navigation` 必须列出：**内购页文件路径** + **每条入口路径**（文件:行或 widget 名）+ 结论 `passed` / `failed`。
   - `failed` 时必须**直接改代码**补入口或补跳转，不得只写建议。

**实现模式**同样必须满足 §6「统一显示」中的入口要求；交付前按上表自检一遍。

## 审查输出要求（调用 review 时必须满足）

- 必须优先回答这些问题，而不是先点评商品数据或 UI 产物：
  - 初始化是否分层容错，任一层失败是否会优雅降级而不是把整体状态搞乱？
  - 是否只有一个全局购买监听器？是否存在重复监听、重复完成交易或多次发货风险？
  - 发币是否有幂等保护：同一笔购买若 `purchaseStream` 回调两次，余额是否只会增加一次？
  - iOS 是否 **`buyConsumable(..., autoConsume: true)`**（禁止 `false`）？`completePurchase` 是否带 **`pendingCompletePurchase`** 守卫？
  - 内购页是否**无 Restore / 恢复购买**按钮或调用？
  - 商品查询失败时，UI 是否还能稳定工作？本地数据与商店返回是否解耦？
  - 用户取消是否在每条错误路径（含 `buyConsumable` 外层 `PlatformException`）识别 `cancelled`/`canceled`/`storekit2_purchase_cancelled` 等，返回 cancelled 且**不**写对外 error 文案、**不**弹购买失败？实现是否**未照抄**本 skill 示例代码块？
  - 超时、网络错误、非取消平台错误时，状态是否都能正确清理并恢复交互？
  - 购买成功后，余额、记录、依赖页面、返回页、聚合展示是否立即同步？
  - 是否真的只有一个花费点，并且固定消费 10 单位？是否存在绕过或多入口消费？
  - **应用内是否具备内购入口**：内购页是否存在？余额/主导航等是否可跳转？审核员从主流程能否在 ≤2 次点击内找到购买入口？
  - 失败重试、返回重进、热重载/重建后，是否会出现余额不同步、卡死 loading、重复购买或残留 pending？
  - 首页/`main.dart` 启动阶段是否完全不触发 StoreKit：不初始化 `IapPurchaseService`、不注册 `purchaseStream`、不调用 `restorePurchases()`、不调用 `queryProductDetails`？
  - consumable 虚拟币是否默认完全不调用 `restorePurchases()`，进入内购页/商店或发起购买时只注册 `purchaseStream` 并 finish 监听器自然收到的 pending/终态交易？
  - `error` / `canceled` 终态是否也走 `_finishPlatformTransaction`（在 `pendingCompletePurchase` 时 `completePurchase`）？
  - duplicate / pending 错误是否不调用 `restorePurchases()`，而是按 `deliveryKey` 判已发货、等待当前 in-flight 购买、仅重试一次或返回 pending/conflict？
  - 同一 `productId` 进行中购买是否会拦截重复点击？
- 审查结论必须显式包含：
  - `总体结论`：只能写 `符合要求` / `不符合要求` / `需完善`。
  - `符合要求`：列出已满足的 IAP 逻辑项，例如懒初始化、唯一监听、购买流程、交易清理、发币幂等、余额持久化、唯一花费点、内购入口。
  - `不符合要求`：只列会影响购买链路、状态一致性、余额、发币、入口可发现性或审核风险的真实问题，并给出文件/位置、原因和修复动作。
  - `需完善 / 建议`：只放不阻塞的商品展示、文案、视觉、布局或体验建议。
  - `修复`：明确 `已修复` / `建议修复` / `待验证`，并写验证证据。
- 不得把 `.storekit`、StoreKit Configuration、沙盒测试配置文件或本地 StoreKit 文件是否存在写入 `不符合要求`；如未检查这些文件，应直接省略，不要作为结论维度。
- 如果逻辑没问题，但商品数据、视觉包装或商品卡片文案还不理想，要明确标成**次要问题**，不要把它们写成“内购实现未完成”。
- 如果项目已有一套不同于默认 27 商品的业务配置，只要购买链路和状态链路正确，审查时可以标记 `product_catalog_27_items`、`product_code_override_applied` 为 `n_a` 或按项目实际解释，不得机械按默认商品模板判失败。

### 1. 懒初始化（三层容错）

> **CRITICAL：禁止首页启动触发 StoreKit。** `main.dart`、首页 `initState`、全局 provider / service locator 启动阶段不得初始化 `IapPurchaseService`，不得注册 `purchaseStream`，不得调用 `restorePurchases()` 或 `queryProductDetails`。首页只能读取本地虚拟货币余额并显示可跳转入口；真正触达 StoreKit 的动作必须延后到用户进入内购页/商店或发起购买。

1. **阶段一：可用性检查**
   - 使用 `isAvailable()` 检查 IAP 服务状态。
   - 设置 **120 秒超时**；审核环境（由调用方告知或通过构建配置判断）可放宽或不设上限。
   - 使用 `try-catch` 捕获 `PlatformException` 和通用异常，记录完整堆栈。
   - 失败时标记服务状态（如 `lazyIsAvailable=false`），优雅结束本阶段，不崩溃应用。
   - 仅允许由内购页/商店页面初始化、购买按钮、余额入口跳转后的商店加载等用户触达 IAP 的路径调用；禁止冷启动后台预热。
2. **阶段二：监听器注册 + 交易完成**
   - 注册唯一 **全局 purchaseStream 监听器**，不得为每次购买新建临时监听器。
   - 使用 `productId -> Completer` 映射（如 `Map<String, Completer<PurchaseResult>>`）管理购买状态，避免多层状态集合。
   - 正确设置 `onDone` / `onError`，监听器注册失败时将服务标记为不可用并优雅降级。
   - 确保对映射的读写是线程安全的（在同一 isolate 内用同步 Map 即可，不做多线程共享结构）。
   - **consumable 虚拟币默认不得调用 `restorePurchases()`**：它用于恢复可恢复权益，不是购买历史展示，也不是默认队列清理工具；在未登录 Apple ID 的 iOS 模拟器上可能触发系统登录提示。
   - 监听器自然收到 `purchased` / `restored` / `error` / `canceled` 等终态交易时，统一走发币幂等、状态清理与 `_finishPlatformTransaction`；对 `restored` 不发币，除非已能用持久化 `deliveryKey` 证明该交易尚未发放。
3. **阶段三：商品按需查询（异步、非阻塞 UI）**
   - 将 27 个商品 ID 转换为 `Set<String>`，仅在内购页/商店打开或购买确认前调用 `queryProductDetails`。
   - 配置 **180 秒超时 + 最多 3 次自动重试（2s/4s/8s 指数退避）**。
   - 记录详细日志：找到数量、未找到 ID 列表、错误信息。
   - 查询失败仅记日志，不中断初始化，也不把服务整体标记为不可用。
   - 将成功查询到的 `ProductDetails` 缓存在内存中（如 `Map<String, ProductDetails>`）。

> 失败隔离原则：三个阶段互不影响，任意阶段失败都不得导致应用崩溃或整体 IAP 不可用标记失真。

### 2. 商品展示策略

1. **本地优先**
   - UI 展示 **完全依赖本地配置的 27 个商品**（默认或用户自定义），包括名称占位、本地参考价格和促销标记。
   - 不等待网络查询结果即可渲染列表，保证页面秒级打开。
2. **查询解耦**
   - App Store 查询（`queryProductDetails`）仅用于获取真实价格做二次确认，不阻塞列表展示。
   - 查询失败不得导致商品列表缺失或界面错误，只在日志中体现。
3. **多软件差异化**
   - 业务文案中虚拟货币名称可以根据软件主题改为金币/能量/燃料等，但 **代码字段名保持通用，不包含中文**。
   - 商品图标、布局需符合每个软件自身的主题色与视觉风格，用贴切主题的自行设计或改造的图形/插画体现功能，避免模板化样式。

### 3. 购买流程设计
1. **线性 6 步流程**
   1. 检查是否已有进行中的购买（基于 `productId -> Completer` 映射），防止重复点击。
   2. 显示 loading，并暂时禁用其他商品卡片。
   3. 查询商品详情（优先用缓存 `ProductDetails`，必要时重新查询）。
   4. 弹出确认对话框，显示从商店获取的实际价格。
   5. 用户确认后发起购买请求。
   6. 等待全局监听器回调，按结果分支处理。
2. **状态锁定与恢复**
   - 购买进行时，仅当前商品可操作，其他商品禁用；所有结果分支（成功/失败/取消）都必须在逻辑结束后恢复可点击状态。
   - UI 层 loading 至少保持一小段时间（如 300–500ms），避免闪烁；可以在完成后延迟约 2 秒关闭。
3. **自动重试**
   - 对可恢复错误（网络异常、超时、5xx 等）采用最多 3 次自动重试，间隔 2s/4s/8s。
   - 对用户取消或权限类错误不得自动重试，只给出友好提示。
4. **购买队列：duplicate / pending 处理（CRITICAL）**
   - `buyConsumable` 外层 catch 或监听器 `PurchaseStatus.error` 若识别为 **duplicate / pending / unfinished / already owned** 类错误（将 message + code + details 转小写后匹配 `duplicate`、`pending`、`unfinished`、`already` 等，实现可整理项目内关键词表）：
     1. **禁止调用 `restorePurchases()` flush**；不要为了清队列触发 StoreKit 恢复/登录流程。
     2. 若同一 `productId` 已有本地 in-flight 购买 → 复用/等待当前 `Completer`，或返回 `pending`，不得发起第二笔购买。
     3. 计算当前意图购买的 `deliveryKey`；若 key 已在持久化已发货集合 → **直接返回成功**（或 `already_fulfilled`），**不**弹失败、**不**再次 `buyConsumable`。
     4. 若未发货且当前没有 in-flight 购买 → **仅重试一次** `buyConsumable`（同一 `productId`），仍失败则返回 `pending` / `conflict` 友好提示，禁止无限重试。
   - 记 WARN `iap_duplicate_pending` / INFO `iap_duplicate_already_fulfilled`。
5. **iOS `buyConsumable` / `autoConsume`（CRITICAL）**
   - **必须**使用 `buyConsumable(..., autoConsume: true)`。禁止传 `autoConsume: false`。
   - **根因**：`in_app_purchase_storekit` 在 iOS 上把 consumable 按 non-consumable 路径处理，并在 `buyConsumable` 内强制断言 `autoConsume == true`；`autoConsume: false` 在 debug 下会直接 `AssertionError`，**支付 sheet 尚未弹出**购买流程即中断。
   - **幂等与完成交易**：不能靠 `autoConsume: false` 手动控完成时机；应使用：
     - **持久化发币去重**（如 `_fulfilledPurchaseIds` / `delivered_purchase_keys`，与 §5 `deliveryKey` 同一语义）；
     - **`_finishPlatformTransaction` 兜底**：仅在 `purchaseDetails.pendingCompletePurchase == true` 时调用 `InAppPurchase.completePurchase`，避免 `autoConsume: true` 已由插件自动完成后重复 `completePurchase`。
   - 审查时 `Grep` `autoConsume: false` 或 `autoConsume:false` → 必须改为 `true` 并核对上述去重 + `pendingCompletePurchase` 守卫。

### 4. 异常处理与弹窗规范

1. **用户取消 ≠ 购买失败（CRITICAL）**
   - 用户主动取消（关闭支付 sheet、StoreKit 取消回调等）**不得**写入对外展示的 error 文案字段，**不得**走 `error` 购买结果分支，**不得**弹出“购买失败”类错误弹窗。
   - 识别为取消时：返回 `cancelled`（或等价）结果；Store/UI 层清空 error 展示状态（如置 `null`），仅结束 loading、恢复卡片可点（可选轻提示“已取消”，禁止按异常处理）。
2. **用户取消识别（CRITICAL）**
   - `buyConsumable` 外层 catch、监听器 `PurchaseStatus.error`、`IAPError` 等**每条**错误路径都要做取消判定，规则一致。
   - **根因**：`buyConsumable()` 在 iOS 上常直接抛 `PlatformException`；若**外层 catch** 未识别取消，会误判为 `error` 并弹窗——不能假设监听器已处理。
   - 将 `message` + `code` + `details` + `toString()` 拼成文本并 **转小写**，命中任一即视为取消（英式 + 美式拼写都要覆盖）：
     - `cancelled` / `canceled`
     - `user_cancelled` / `user_canceled`
     - `storekit2_purchase_cancelled` / `storekit2_purchase_canceled`
     - `transaction has been cancelled` / `purchase cancelled` / `cancelled by the user`（及 `canceled` 变体）
     - `skerrorpaymentcancelled` / payment sheet dismissed 等等价表述
3. **`buyConsumable` 外层 catch（语义示意，勿复用示例代码）**
   > ⚠️ **禁止**将下方代码块整段照抄进项目，也**禁止**复用其中的变量名（如 `platformErr`、`sheetClosedByUser`）或返回值类型名。仅理解「外层 catch 须先判取消再判失败」；按项目 Store 自行实现。
   ```dart
   try {
     await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
   } catch (e, st) {
     // 示意：拼错误文本 → 匹配 §4.2 关键词 → cancelled，勿写对外 error
     ...
   }
   ```
   - 监听器等其他分支同样须识别取消，实现与命名随项目而定，**不得**复制上例变量名。
4. **非取消错误**
   - 弹出友好失败提示（如“购买失败，请稍后再试”），可附一行简短 code；全量堆栈仅写日志，不展示给用户。
5. **日志**
   - 用户取消记 **INFO**（可选）；真实失败记 **WARN/ERROR**。

### 5. 订单处理与状态清理

1. **订单处理**
   - 成功购买后，验证收据（区分沙盒/生产环境，若接入服务端则以服务端验证为准）。
   - 发放虚拟商品（金币/能量/燃料等）前必须先做**发币幂等**（见下），通过后再更新本地余额与内部已处理交易标记；不要求交易历史或用户可见购买记录。
   - 完成平台交易：封装为 `_finishPlatformTransaction`（或等价函数），**仅当** `purchaseDetails.pendingCompletePurchase == true` 时调用 `completePurchase()`；`autoConsume: true` 时 StoreKit 插件常已自动完成，重复调用须被该守卫挡住。
   - **失败/取消也 finish（CRITICAL）**：`purchaseStream` 监听器在 **`purchased` / `restored` / `error` / `canceled`** 等**所有终态**结束前都必须调用 `_finishPlatformTransaction`。禁止仅在 `purchased` 分支 finish；`error`、`canceled` 若 `pendingCompletePurchase == true` 同样必须 `completePurchase()`。`error`/`canceled` **不得发币**，但仍须 finish + 清理 `productId -> Completer`。
2. **发币幂等（CRITICAL）**
   - **根因**：全局 `purchaseStream` 可能对同一笔 `PurchaseDetails` 回调多次；若发币无去重，会重复入账。
   - **deliveryKey**（实现可用 `_fulfilledPurchaseIds` 等命名，语义相同）：每笔成功购买生成唯一 key，优先级：
     1. `purchaseID`（非空时首选）
     2. 否则 `verificationData.localVerificationData` 或 `serverVerificationData` 的稳定摘要（如 hash）
     3. 再否则 `productID + transactionDate`（毫秒时间戳）组合
   - **持久化已发货集合**：将已成功发币的 `deliveryKey` 写入本地持久化（与余额同一存储层，如 SharedPreferences / 本地 DB），键名语义清晰（如 `delivered_purchase_keys`），应用重启后仍有效。
   - **发放流程**（须在监听器回调路径内原子化）：
     1. 计算 `deliveryKey`
     2. 若 key 已在已发货集合 → **跳过加币**，仍走 `_finishPlatformTransaction`（内部按 `pendingCompletePurchase` 决定是否 `completePurchase`）与 UI/状态清理，打 INFO 日志 `duplicate_delivery_skipped`
     3. 若 key 不在集合 → 加币 → **立即**把 key 写入持久化（先于或与余额写入同一事务/同一保存批次），再 `_finishPlatformTransaction`
   - **禁止**：仅凭内存 `Set` 去重（进程重启或热重载后会失效）；禁止在加币之后才写 key（崩溃会导致重复发币）。
   - **审查/测试**：代码审查必须能指出 `deliveryKey` 来源与持久化位置；联动测试需覆盖「同一 `purchaseID` 模拟二次回调只加一次币」。
3. **收据缺失兜底**
   - 若状态为 `purchased` 但本地 `verificationData` 为空，记录 WARN 日志，并默认视为成功发放（若未来接入服务端校验，则由服务端最终裁决）。
4. **统一清理**
   - 在所有结果分支（成功/失败/取消/验证失败）中都必须在 `Completer.complete()` 后立即清理 `productId -> Completer` 映射和内部状态。
   - UI 层在短暂延迟后关闭 loading，恢复按钮状态，保证列表状态与内部状态一致。

### 6. 虚拟货币与显示规范

1. **余额与消耗**
   - 默认初始余额：100 单位（金币/能量/燃料等，根据应用主题设计不同商品 图标）。
   - **只从应用已有功能中选取一个最合适的功能作为唯一花费点**（如创建记录、保存、导出等），**每次固定消耗 10 单位**。禁止设置多个不同的花费功能。
   - 余额持久化存储（如 SharedPreferences 或本地数据库）。
2. **统一显示**
   - 所有会消耗或购买虚拟货币的页面，都必须显示当前余额。
   - **在唯一的花费功能入口处，通过弹窗或显眼方式标明：该功能每次使用将花费 10 单位；不要在内购页面添加花费说明。**
   - 除内购页面外，需要在合适的页面给出显眼的内购入口，其他显示余额的位置均可点击跳转到内购页面。
3. **实时刷新**
   - 每次消费或购买成功后，必须刷新所有相关页面的余额显示（通过 Provider 或等价的全局状态管理实现）。

### 7. UI/UX 与命名规范

1. **视觉设计**
   - **内购页面禁止 Restore / 恢复购买按钮**（含 `restorePurchases`、`InAppPurchase.restorePurchases` 触发的 UI）。本项目为 consumable 虚拟货币，不提供恢复购买；审查时 `Grep` `restore` / `Restore` 于内购页相关文件，发现则删除并记 evidence。
   - 内购页面整体布局和商品卡片需符合应用主题色，风格符合软件主题功能。这里的动态反馈必须服务于购买理解与权益表达，例如商品状态切换、选中反馈、价格层级强调、购买完成反馈，而不是单纯加光效或漂浮动画。
   - **商品 logo 必须根据软件主题功能设计相关图标**：
     - 健身类应用：能量、火焰、闪电等
     - 学习类应用：星星、宝石、知识点等
     - 游戏类应用：道具、装备、资源等
     - 工具类应用：积分、点数、权益等
   - **绝对禁止使用原生金币图标**（如 Material Icons 的 monetization_on、attach_money 等）
   - 商品图标要有趣、动态、有互动感等富有设计感，尽量避免直接使用系统原生图标或简单改色的原生组件。
   - 这些视觉项在**实现模式**中必须落实；在**审查模式**中，只有当它们已经影响理解、操作、状态反馈或审核风险时，才提升为主要问题。
2. **命名与代码风格**（与模板约定一致，不依赖打包后不存在的路径）
   - 目录/文件/类/变量命名按下列规则执行：
     - 禁止统一前缀；禁止 utils、helpers、common、shared、base、core、manager、handler 等模板化词；
     - 语义清晰，避免缩写；类名 PascalCase，变量/函数 camelCase，目录/文件名小写+下划线；
     - 目录/文件名在语义基础上可在前/中/后**直接拼接**少量无规则字符（不新增下划线），用于打散可识别模式；
     - 所有代码文件中禁止出现中文字符（含注释和字符串）。

---

## 任务规划

> **规划方式**：执行此命令前，确保 `.claude/CLAUDE_STATE.md` 存在（编排层 Bootstrap skeleton → Stage 1 enriched）。先读 `## Active Executors` + Stage 3 Detail；过程状态写 `.claude/stage3/iap_tracker.md`，不直接改 `CLAUDE_STATE.md`（编排层合并）。

### 实施阶段概览

| 阶段 | 任务内容 | 关键产出 |
|------|---------|---------|
| Phase 1 | 基础架构与数据层 | 商品模型、持久化存储、常量配置 |
| Phase 2 | 核心服务层 | IAP 初始化、购买流程、错误处理、状态管理 |
| Phase 3 | UI 页面实现 | 内购页面、余额组件、弹窗交互 |
| Phase 4 | 集成与测试 | 路由集成、功能验证、错误边界测试 |
| Phase 5 | 代码审查与构建 | 静态检查、构建验证、规范审查 |

### 分 phase 执行要求

- Phase 1 完成前，不得开始 UI 商品卡片和余额入口
- Phase 2 完成前，不得开始唯一花费点接线
- Phase 3 完成前，必须回看 `README.md`，确认 UI 主题和商品 logo 方向
- Phase 4 必须至少覆盖购买成功、购买取消、余额刷新、**同一 deliveryKey 二次回调不重复发币**和小屏布局

## 交付同步（必须）

- 每完成一个关键里程碑，立即更新 `.claude/test_matrix.md`
  - 初始化
  - 购买流程
  - 余额刷新
  - 唯一花费点
  - 商品卡片小屏布局
- 向 `.claude/event_log.ndjson` 追加：
  - `task_completed`
  - `tracker_synced`
  - `test_passed` / `test_failed`
  - `overflow_detected`
  - `blocker_recorded`
- 若内购页、余额入口或商品卡片布局有改动，必须同步更新 `.claude/stage4/layout_audit.md`
- 商品卡片出现 `RenderFlex overflow`、`overflowed by` 或 320x568 布局风险时，视为阻塞项，不得标记完成
