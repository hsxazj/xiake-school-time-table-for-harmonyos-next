# 侠客课表 - HarmonyOS ArkTS

一个基于HarmonyOS ArkTS开发的课程表管理应用，提供课程查看、学院选择、个人信息管理等功能。

## 项目结构

```
entry/src/main/ets/
├── common/              # 公共模块
│   ├── constants/       # 常量定义（API配置、RSA密钥等）
│   ├── utils/          # 工具类（日期、偏好设置、用户信息管理等）
│   └── types/          # 类型定义
├── components/         # 组件
│   ├── base/          # 基础组件
│   └── pages/         # 页面组件（首页、课表页、个人页）
├── pages/             # 路由页面
├── services/          # 服务层
│   ├── api/          # API服务（HTTP服务、各业务API）
│   └── AppConfigManager.ets  # 全局配置管理
├── models/           # 数据模型
└── todaycourse/      # 今日课程组件
```

## 开发环境

- **HarmonyOS SDK**: 5.0.5(17)
- **开发工具**: DevEco Studio
- **目标设备**: 手机

## 主要功能

- **课程表管理**: 查看今日课程、周视图完整课程表
- **学院选择**: 支持多学院课程信息获取
- **个人中心**: 用户信息管理、设置配置
- **网络通信**: 基于axios的HTTP服务，支持RSA加密
- **数据持久化**: 使用Preferences进行本地数据存储

## 技术特性

### 架构模式
- **单例模式**: HttpService、AppConfigManager等核心服务
- **响应式UI**: 使用@State、@Prop、@Consume装饰器
- **导航管理**: 基于NavPathStack的页面导航

### 网络层
- 基于@ohos/axios的HTTP客户端
- 统一的ApiResponse<T>响应格式
- 请求/响应拦截器支持
- RSA加密通信支持

### 组件化开发
- 可复用的基础组件
- @Builder模式的UI构建器
- 资源引用: `$r('app.media.icon')`

## 依赖管理

```json5
{
  "dependencies": {
    "@ohos/axios": "^2.2.6"
  },
  "devDependencies": {
    "@ohos/hypium": "1.0.21",
    "@ohos/hamock": "1.0.0"
  }
}
```

## 权限配置

应用需要以下权限：
- `ohos.permission.INTERNET`: 网络访问权限

## 开发指南

### 组件开发
- 遵循PascalCase命名规范
- 页面组件使用"Page"后缀
- 使用TypeScript严格类型检查

### API集成
- 所有网络请求通过HttpService统一管理
- 敏感数据使用RsaPkcs1Util进行RSA加密
- 遵循ApiResponse接口规范

## 构建配置

- **API类型**: Stage模式
- **目标SDK版本**: 5.0.5(17)
- **兼容SDK版本**: 5.0.5(17)
- **运行系统**: HarmonyOS
- **代码混淆**: 发布模式可选启用