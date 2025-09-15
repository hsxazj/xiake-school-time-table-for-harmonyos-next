# 霞客课表 HarmonyOS 应用

[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-5.0.5-blue)](https://developer.harmonyos.com/)
[![ArkTS](https://img.shields.io/badge/ArkTS-TypeScript-blue)](https://developer.harmonyos.com/cn/docs/documentation/doc-guides/arkts-get-started-0000001504769321)

霞客课表是一款基于 HarmonyOS Next 原生开发的课程表管理应用，采用 ArkTS 语言开发，提供流畅的原生体验和完整的课表管理功能。

## 🌟 项目特色

- **HarmonyOS 原生**：基于 HarmonyOS 5.0.5 SDK 和 ArkTS 语言开发
- **ArkTS 声明式UI**：使用现代化的 ArkTS 声明式UI开发
- **智能配置管理**：自动初始化应用配置和学期状态管理
- **模块化架构**：清晰的服务层、模型层、组件层分离
- **完善的开发文档**：包含开发规范和技术文档

## 🏗️ 项目架构

```
entry/src/main/ets/
├── pages/                          # 路由页面
├── components/                     # UI 组件
│   ├── base/                       # 基础可复用组件
│   └── pages/                      # 页面级组件
├── services/                       # 业务服务层
│   ├── AppConfigManager.ets        # 应用配置管理
│   └── api/                        # API 服务层
├── models/                         # 数据模型
├── common/                         # 公共模块
│   ├── constants/AppConstants.ets  # 应用常量配置
│   ├── types/PickerTypes.ets       # 选择器类型定义
│   └── utils/                      # 工具类
├── todaycourse/                    # 今日课程卡片
└── entryability/EntryAbility.ets   # 应用入口
```

## 📱 核心功能

### 应用初始化

- **智能启动**：自动检查用户信息完整性，智能跳转
- **配置管理**：统一的应用配置初始化和状态管理
- **学期计算**：自动计算当前学期状态和周次信息

### 用户体验

- **学院选择**：支持学院、专业、班级三级联动选择
- **数据持久化**：用户选择自动保存，支持记忆功能
- **加载状态**：完善的加载状态提示和错误处理

### 技术特性

- **模块化设计**：清晰的服务层分离，便于维护扩展
- **类型安全**：完整的 TypeScript 类型定义
- **网络请求**：基于 @ohos/axios 的统一HTTP服务
- **日志系统**：完善的hilog日志记录

## 🛠️ 技术栈

- **开发框架**：HarmonyOS 5.0.5 SDK
- **开发语言**：ArkTS (TypeScript)
- **UI框架**：ArkUI 声明式UI
- **网络请求**：@ohos/axios
- **构建工具**：hvigor
- **测试框架**：@ohos/hypium, @ohos/hamock

## ⚡ 快速开始

### 环境要求

- **HarmonyOS SDK**: 5.0.5(17)
- **DevEco Studio**: 5.1.1.Release
- **Node.js**: v18.20.8+
- **ohpm**: HarmonyOS 包管理器

## 🔧 开发指南

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

#### 3. 网络服务 (`HttpService.ets`)

- 基于 @ohos/axios 的统一HTTP请求封装
- 请求/响应拦截器
- 错误处理和重试机制

#### 4. 班级选择导航 (`ClassSelectNavPage.ets`)

- 三级联动选择器实现
- 用户选择数据持久化
- 自定义选择器组件使用

### 权限配置

应用需要以下权限：

```json
{
  "name": "ohos.permission.INTERNET",
  "reason": "访问网络获取课程数据和学院信息"
}
```

## 🚀 应用流程

1. **应用启动**：`OpenPage.ets` 展示启动画面
2. **配置初始化**：`AppConfigManager` 获取配置数据
3. **状态检查**：检查用户信息完整性
4. **智能跳转**：
    - 有完整信息 → 跳转到主页Tab
    - 无完整信息 → 跳转到学院选择页
5. **正常使用**：进入主要功能页面

## 📊 项目状态

- **当前版本**: 1.0.1
- **HarmonyOS SDK**: 5.0.5(17)
- **开发状态**: 积极开发中
- **测试状态**: 没有测试捏

## 🤝 贡献

欢迎贡献代码和提交问题！

1. Fork 本项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

**注意**: 本项目专注于 HarmonyOS 原生应用开发，提供最佳的鸿蒙系统原生体验。