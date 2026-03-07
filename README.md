# HarmonyProxy

鸿蒙版网络代理工具 - 类似Shadowrocket的HarmonyOS应用

## 项目简介

HarmonyProxy是一款专为鸿蒙系统设计的网络代理工具，支持多种主流代理协议，提供完善的节点管理和规则配置功能。

## 功能特性

### 支持的代理协议
- Shadowsocks (SS)
- ShadowsocksR (SSR)
- VMess (V2Ray)
- Trojan
- HTTP/HTTPS
- SOCKS5

### 核心功能
- 节点管理（添加、编辑、删除、分组）
- 订阅管理（URL订阅、自动更新）
- 规则配置（分流规则、直连/代理/拒绝）
- 实时连接状态监控
- 流量统计
- 延迟测试
- QR码扫描导入
- 配置文件导入导出

### 高级功能
- URL重写
- DNS配置与防污染
- 代理链配置
- MITM配置

## 技术架构

```
┌─────────────────────────────────┐
│      UI层 (ArkUI)               │
├─────────────────────────────────┤
│    业务逻辑层 (ArkTS)            │
├─────────────────────────────────┤
│    服务层 (VPN/代理/DNS)        │
├─────────────────────────────────┤
│  核心引擎层 (Native C++)        │
├─────────────────────────────────┤
│    数据持久层 (RDB/Prefs)       │
└─────────────────────────────────┘
```

## 开发环境

- DevEco Studio 4.0+
- HarmonyOS SDK (API 10+)
- NDK r23+
- Node.js 16+

## 项目结构

```
HarmonyProxy/
├── entry/              # 主模块
│   ├── src/main/
│   │   ├── ets/        # ArkTS代码
│   │   ├── cpp/        # Native C++代码
│   │   └── resources/  # 资源文件
│   └── build-profile.json5
├── common/             # 公共模块
├── features/           # 功能特性模块
├── docs/               # 文档
├── assets/             # 资源文件
└── screenshots/        # 截图
```

## 开发路线

- [x] 项目初始化
- [ ] 基础框架搭建
- [ ] 核心协议实现
- [ ] 业务功能开发
- [ ] 高级功能与优化
- [ ] 测试与发布

## 构建与运行

```bash
# 克隆项目
git clone https://github.com/yourusername/HarmonyProxy.git

# 使用DevEco Studio打开项目
# 同步项目依赖
# 连接鸿蒙设备或启动模拟器
# 点击运行
```

## 贡献指南

欢迎提交Issue和Pull Request！

1. Fork本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 创建Pull Request

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 免责声明

本项目仅供学习和研究使用，请遵守当地法律法规。使用本软件所产生的一切后果由用户自行承担。

## 联系方式

- 项目主页: https://github.com/yourusername/HarmonyProxy
- 问题反馈: https://github.com/yourusername/HarmonyProxy/issues

## 致谢

感谢以下开源项目的启发和参考：
- [shadowsocks-libev](https://github.com/shadowsocks/shadowsocks-libev)
- [v2ray-core](https://github.com/v2ray/v2ray-core)
- [sing-box](https://github.com/SagerNet/sing-box)
