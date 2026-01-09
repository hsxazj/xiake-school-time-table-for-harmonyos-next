# 霞客课表 HarmonyOS 应用

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0.5-blue)](https://developer.harmonyos.com/)
[![ArkTS](https://img.shields.io/badge/ArkTS-TypeScript-blue)](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/arkts-get-started-0000001504769321)
![Version](https://img.shields.io/badge/版本-2.0.0-brightgreen)

霞客课表是一款基于 HarmonyOS Next 原生开发的校园课程表管理应用，采用 ArkTS 语言开发，通过**双数据源架构**（自建后端API + 教务系统直连）实现课程数据获取、考试安排查询、成绩信息查看、用户信息管理、校园社交树洞等功能，为校园生活提供全方位的数字化服务。

## 项目特色

- **HarmonyOS 原生**：基于 HarmonyOS 5.0.5 SDK 和 ArkTS 语言开发，充分利用系统能力
- **声明式UI**：使用现代化的 ArkTS 声明式UI，提供流畅的用户体验
- **双数据源架构**：自建后端API + 教务系统直连
- **智能缓存策略**：优先缓存、异步更新、离线降级，保障应用可用性
- **Cookie手动管理**：针对HarmonyOS环境的Cookie持久化方案
- **模块化架构**：清晰的服务层、模型层、组件层分离，便于维护和扩展
- **智能配置**：自动计算当前学期、周次，根据班级年级限制数据范围



## 项目架构

### 整体架构设计

采用经典的分层架构模式，实现关注点分离和高内聚低耦合：

```
┌─────────────────────────────────────────────────────────────────┐
│              Presentation Layer                                 │  页面与UI组件
│  (Pages, Components, Navigation)                                │
├─────────────────────────────────────────────────────────────────┤
│              Business Logic Layer                               │  业务逻辑与服务
│  (AppConfigManager, Services, StudentInfoManager)              │
├─────────────────────────────────────────────────────────────────┤
│              Data Access Layer                                  │  数据获取与处理
│  ┌────────────────────┬──────────────────────────────────────┐  │
│  │  自建API系统       │  教务系统直连                        │  │
│  │  (HttpService)    │  (JwxtHttpClient)                   │  │
│  │  - ConfigAPI      │  - JwxtLoginService                 │  │
│  │                   │  - JwxtCourseService                │  │
│  │                   │  - JwxtGetExamService               │  │
│  │                   │  - JwxtGetGradeService              │  │
│  │                   │  - CookieManager                    │  │
│  └────────────────────┴──────────────────────────────────────┘  │
│                     CacheManager (统一缓存)                      │
├─────────────────────────────────────────────────────────────────┤
│              Infrastructure Layer                               │  基础设施支持
│  (Utils, Constants, Models, Parser)                            │
└─────────────────────────────────────────────────────────────────┘
```

### 双数据源架构

本应用采用**双数据源架构**，兼顾校园自建服务和教务系统官方数据：

#### 🔹 数据源1：自建后端API
- **基础地址**：`https://school-time.fjutxiake.com`
- **认证方式**：Token (Bearer Authentication)
- **适用场景**：树洞功能、学期配置、社交互动
- **核心服务**：HttpService + ConfigApiService

#### 🔹 数据源2：教务系统直连
- **基础地址**：福建工程学院教务系统
- **认证方式**：Cookie Session (手动管理)
- **适用场景**：课程数据、考试安排、成绩查询、用户信息
- **核心服务**：JwxtHttpClient + JwxtLogin/Course/Exam/Grade Services

####  统一缓存层
- **CacheManager**：为两套系统提供统一的本地缓存
- **缓存策略**：优先缓存，异步更新，离线降级
- **缓存类型**：配置缓存、课表缓存、学期课程缓存、考试缓存、成绩缓存

### 目录结构

```
entry/src/main/ets/
├── pages/                          # 路由页面
│   ├── OpenPage.ets                # 启动页
│   ├── MainTabNavPage.ets          # 主Tab导航
│   └── ...                         # 其他页面
├── components/                     # UI 组件
│   ├── base/                       # 基础可复用组件
│   │   ├── ImagePreviewDialog.ets  # 图片预览
│   └── pages/                      # 页面级组件
│       ├── HomePage.ets            # 首页
│       ├── SchedulePage.ets        # 课表页
│       ├── MinePage.ets            # 我的页面
│       └── LoginPage.ets           # 登录页
├── services/                       # 业务服务层
│   ├── AppConfigManager.ets        # 应用配置管理器
│   ├── StudentInfoManager.ets      # 学生信息管理器
│   ├── FormService.ets             # 卡片服务
│   ├── api/                        # 自建API服务层
│   │   ├── HttpService.ets         # HTTP请求封装
│   │   ├── ConfigApiService.ets    # 配置API服务
│   └── jwxt/                       # 教务系统服务层
│       ├── JwxtHttpClient.ets      # 教务系统HTTP客户端
│       ├── JwxtLoginService.ets    # 教务系统登录服务
│       ├── JwxtCourseService.ets   # 课程数据服务
│       ├── JwxtGetExamService.ets  # 考试信息服务
│       ├── JwxtGetGradeService.ets # 成绩查询服务
│       ├── JwxtGetInfoService.ets  # 用户信息服务
│       ├── CookieManager.ets       # Cookie管理器
│       └── JwxtCredentialsManager.ets # 凭证管理器
├── models/                         # 数据模型层
│   ├── CourseModels.ets            # 课程数据模型
│   ├── UserModels.ets              # 用户数据模型
│   ├── ConfigModels.ets            # 配置数据模型
│   ├── CollegeModels.ets           # 学院数据模型
│   └── LoginModels.ets             # 登录数据模型
├── common/                         # 公共基础模块
│   ├── constants/                  # 常量定义
│   │   ├── AppConstants.ets        # 应用常量(API地址、RSA公钥等)
│   │   └── ThemeColors.ets         # 主题颜色
│   ├── types/                      # 类型定义
│   │   └── PickerTypes.ets         # 选择器类型
│   └── utils/                      # 工具类库
│       ├── DateUtil.ets            # 日期工具
│       ├── CourseTimeUtil.ets      # 课程时间工具
│       ├── PreferencesUtil.ets     # 持久化存储工具
│       ├── UserInfoManager.ets     # 用户信息管理器
│       ├── CacheManager.ets        # 缓存管理器
│       └── RsaPkcs1Util.ets        # RSA加密工具
├── todaycourse/                    # 今日课程卡片
│   └── pages/TodayCourseCard.ets   # 卡片UI
└── entryability/                   # 应用能力
    └── EntryAbility.ets            # 应用入口
```

## 核心功能

### 数据拉取架构

#### 双认证系统

**1. 自建API认证 (Token-Based)**
```typescript
// Token存储在AppStorage中，自动添加到请求头
HttpService -> 请求拦截器 -> 添加Authorization: Bearer {token}
```

**2. 教务系统认证 (Cookie-Based)**

```typescript
// 手动Cookie管理（HarmonyOS中axios不自动管理Cookie）
JwxtLoginService -> 登录 -> CookieManager存储Cookie
JwxtHttpClient -> 请求拦截器 -> 添加Cookie请求头
```

#### 数据流转流程

**自建API数据流程**

```
1. 用户操作 → ConfigApiService/TreeHoleApiService
2. HttpService发起请求 (自动添加Token)
3. 后端API返回数据
4. CacheManager异步缓存
5. 更新UI显示
```

**教务系统数据流程**
```
1. 首次使用 → JwxtLoginService登录 → 保存Cookie
2. 用户操作 → JwxtCourseService/JwxtGetExamService等
3. JwxtHttpClient发起请求 (自动添加Cookie)
4. 教务系统返回数据 → CourseParser解析
5. CacheManager异步缓存
6. 更新UI显示
```

#### 缓存优先策略

**设计理念**：优先返回缓存，异步更新，保障离线可用

```typescript
// ConfigApiService示例
async getConfig() {
  // 1. 立即尝试读取缓存
  const cached = await CacheManager.getConfigCache();

  if (cached) {
    // 2. 立即返回缓存数据
    // 3. 异步发起API请求更新缓存（不阻塞返回）
    this.updateConfigCacheInBackground();
    return { code: 200, data: cached, msg: '缓存数据' };
  }

  // 4. 无缓存：等待API请求完成
  return await this.fetchAndCacheConfig();
}
```

**离线降级**：网络失败时自动使用缓存数据，保证应用基本可用

#### 核心服务说明

| 服务类 | 职责 | 认证方式 | 缓存支持 |
|-------|------|---------|---------|
| **ConfigApiService** | 学期配置管理，自动计算周次 | Token | ✅ 配置缓存 |
| **JwxtLoginService** | 教务系统登录，Cookie管理 | Cookie | ✅ 凭证缓存 |
| **JwxtCourseService** | 从教务系统拉取课程数据 | Cookie | ✅ 学期课程缓存 |
| **JwxtGetExamService** | 从教务系统拉取考试安排 | Cookie | ✅ 考试缓存 |
| **JwxtGetGradeService** | 从教务系统拉取成绩信息 | Cookie | ✅ 成绩缓存 |
| **CacheManager** | 统一缓存管理，支持多种数据类型 | - | - |

### 应用初始化

- **智能启动**：自动检查用户信息完整性，智能跳转
- **配置管理**：统一的应用配置初始化和状态管理
- **学期计算**：自动计算当前学期状态和周次信息

### 用户体验

- **学院选择**：支持学院、专业、班级三级联动选择
- **数据持久化**：用户选择自动保存，支持记忆功能
- **加载状态**：完善的加载状态提示和错误处理

### 技术特性

- **双数据源架构**：自建API + 教务系统直连，数据来源多样化
- **双认证系统**：Token认证 + Cookie Session认证，安全可靠
- **手动Cookie管理**：针对HarmonyOS环境的Cookie持久化方案
- **智能缓存策略**：优先缓存、异步更新、离线降级，保障应用可用性
- **模块化设计**：清晰的服务层分离，便于维护扩展
- **类型安全**：完整的 TypeScript 类型定义
- **数据解析**：CourseParser统一处理教务系统数据格式转换
- **网络请求**：基于 @ohos/axios 的双HTTP客户端（HttpService + JwxtHttpClient）
- **日志系统**：完善的hilog日志记录，支持调试追踪

## 技术栈

- **开发框架**：HarmonyOS 5.0.5 SDK
- **开发语言**：ArkTS (TypeScript)
- **UI框架**：ArkUI 声明式UI
- **网络请求**：@ohos/axios
- **构建工具**：hvigor
- **测试框架**：@ohos/hypium, @ohos/hamock



## ⚡快速开始

### 环境要求

- **HarmonyOS SDK**: 5.0.5(17)
- **DevEco Studio**: 5.1.1.Release
- **Node.js**: v18.20.8+
- **ohpm**: HarmonyOS 包管理器

### 启动

使用以下命令安装依赖

```
ohpm install
```



## 开发指南

### 代码规范

项目严格遵循 HarmonyOS ArkTS 开发规范：

- 文件名使用 PascalCase 命名
- 组件使用 @Entry/@Component 装饰器
- 严格的TypeScript类型检查
- 安全代码检查（通过 `code-linter.json5` 配置）

### 核心组件说明

#### 1. 应用入口 (`OpenPage.ets`)

- 启动页面展示和初始化处理
- `AppConfigManager` 配置初始化
- 智能路由跳转逻辑

#### 2. 配置管理 (`AppConfigManager.ets`)

- 单例模式的全局配置管理
- 学期状态自动计算
- 配置数据缓存和初始化

#### 3. 自建API网络服务 (`HttpService.ets`)

- 基于 @ohos/axios 的统一HTTP请求封装
- 自动Token认证（从AppStorage获取）
- 请求/响应拦截器
- 401自动清除Token

#### 4. 教务系统HTTP客户端 (`JwxtHttpClient.ets`)

- 独立的axios实例，专用于教务系统
- 手动Cookie管理（HarmonyOS中axios不自动管理Cookie）
- 支持GET、POST、POST表单等请求
- Cookie自动保存和发送

#### 5. 教务系统登录服务 (`JwxtLoginService.ets`)

- RSA加密密码传输
- Cookie持久化存储
- 教务系统Session管理
- 凭证安全加密存储

#### 6. 缓存管理器 (`CacheManager.ets`)

- 统一的缓存接口（配置、课表、考试、成绩）
- 基于PreferencesUtil的持久化存储
- 支持缓存版本控制
- 静默错误处理，不影响主流程

### 权限配置

应用需要以下权限：

```json
{
  "name": "ohos.permission.INTERNET",
  "reason": "访问网络获取课程数据和学院信息"
}
```

## 应用流程

### 应用启动流程
1. **应用启动**：`EntryAbility.onCreate()` 初始化
2. **Token验证**：验证本地Token有效性
3. **配置初始化**：`AppConfigManager.initialize()` 获取学期配置
4. **加载首页**：`OpenPage.ets` 展示启动画面
5. **状态检查**：检查用户信息完整性
6. **智能跳转**：
    - 有完整信息 → 跳转到主页Tab
    - 无完整信息 → 跳转到学院选择页

### 教务系统数据拉取流程
```
┌─────────────────────────────────────────────────────────┐
│ 1. 首次使用教务系统功能                                 │
│    → JwxtLoginService.login(username, password)        │
│    → RSA加密密码                                        │
│    → 教务系统验证                                        │
│    → CookieManager.saveCookie()                        │
├─────────────────────────────────────────────────────────┤
│ 2. 获取课程数据                                          │
│    → JwxtCourseService.getCourseList()                 │
│    → JwxtHttpClient发起请求（自动添加Cookie）           │
│    → 教务系统返回原始数据                                │
│    → CourseParser.parseCourses() 解析数据               │
│    → CacheManager.saveSemesterCourses() 缓存            │
├─────────────────────────────────────────────────────────┤
│ 3. 获取考试/成绩数据                                     │
│    → JwxtGetExamService / JwxtGetGradeService          │
│    → 同样的Cookie认证流程                               │
│    → 数据解析和缓存                                      │
└─────────────────────────────────────────────────────────┘
```

### 自建API数据拉取流程
```
┌─────────────────────────────────────────────────────────┐
│ 1. 用户登录                                              │
│    → LoginApiService.login()                           │
│    → 获取Token                                          │
│    → AppStorage.setOrCreate('token', token)            │
├─────────────────────────────────────────────────────────┤
│ 2. 获取配置数据                                          │
│    → ConfigApiService.getConfig()                      │
│    → 优先返回缓存，异步更新API                          │
│    → 计算当前学期和周次                                  │
├─────────────────────────────────────────────────────────┤
│ 3. 树洞功能                                              │
│    → TreeHoleApiService（发布、点赞、评论）             │
│    → HttpService自动添加Token认证                       │
│    → 实时数据，不使用缓存                                │
└─────────────────────────────────────────────────────────┘
```
