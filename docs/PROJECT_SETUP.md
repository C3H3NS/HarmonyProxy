# HarmonyProxy 项目配置指南

## 一、DevEco Studio 项目创建步骤

### 1. 创建新项目
1. 打开 DevEco Studio
2. File → New → Create Project
3. 选择 Application → Empty Ability
4. 配置项目信息：
   - Project name: HarmonyProxy
   - Bundle name: com.gfop.harmonyproxy
   - Save location: E:\鸿蒙\HarmonyProxy-Dev
   - Language: ArkTS
   - Compatible SDK: API 10+
   - Model: Stage

### 2. 项目创建后的目录结构
```
HarmonyProxy-Dev/
├── entry/                          # 主模块
│   ├── src/main/
│   │   ├── ets/                    # ArkTS代码
│   │   │   ├── entryability/
│   │   │   │   └── EntryAbility.ets
│   │   │   └── pages/
│   │   │       └── Index.ets
│   │   ├── resources/              # 资源文件
│   │   │   ├── base/
│   │   │   │   ├── element/        # 颜色、字符串等
│   │   │   │   ├── media/          # 图片资源
│   │   │   │   └── profile/        # 配置文件
│   │   │   └── rawfile/            # 原始文件
│   │   └── module.json5            # 模块配置（重要！）
│   ├── build-profile.json5         # 构建配置
│   ├── hvigorfile.ts               # 构建脚本
│   └── oh-package.json5            # 依赖配置
├── build-profile.json5             # 项目构建配置
├── hvigorfile.ts                   # 项目构建脚本
├── hvigorw                         # Linux/Mac构建工具
├── hvigorw.bat                     # Windows构建工具
└── oh-package.json5                # 项目依赖配置
```

## 二、必要权限配置

### 1. 修改 entry/src/main/module.json5

在 `module.json5` 中添加以下权限：

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:startIcon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:permission_internet_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "$string:permission_network_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.CONNECT_VPN",
        "reason": "$string:permission_vpn_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

### 2. 添加权限说明字符串

在 `entry/src/main/resources/base/element/string.json` 中添加：

```json
{
  "string": [
    {
      "name": "module_desc",
      "value": "HarmonyProxy - 鸿蒙网络代理工具"
    },
    {
      "name": "EntryAbility_desc",
      "value": "HarmonyProxy主入口"
    },
    {
      "name": "EntryAbility_label",
      "value": "HarmonyProxy"
    },
    {
      "name": "permission_internet_reason",
      "value": "需要网络权限以建立代理连接"
    },
    {
      "name": "permission_network_reason",
      "value": "需要获取网络状态以优化连接"
    },
    {
      "name": "permission_vpn_reason",
      "value": "需要VPN权限以创建虚拟网络接口"
    }
  ]
}
```

## 三、项目依赖配置

### 1. 修改 entry/oh-package.json5

```json5
{
  "name": "entry",
  "version": "1.0.0",
  "description": "HarmonyProxy main entry",
  "main": "",
  "author": "",
  "license": "MIT",
  "dependencies": {
    // 添加常用依赖
  },
  "devDependencies": {
    // 开发依赖
  }
}
```

### 2. 修改项目根目录 oh-package.json5

```json5
{
  "name": "harmonyproxy",
  "version": "1.0.0",
  "description": "鸿蒙版网络代理工具",
  "main": "",
  "author": "面向女朋友编程",
  "license": "MIT",
  "dependencies": {}
}
```

## 四、Native C++ 开发环境配置

### 1. 创建 C++ 目录结构

在 `entry/src/main/` 下创建 `cpp` 目录：

```
entry/src/main/cpp/
├── CMakeLists.txt          # CMake配置
├── types/
│   └── libentry/
│       └── index.d.ts      # NAPI类型定义
├── napi/
│   └── napi_init.cpp       # NAPI初始化
├── proxy/
│   ├── proxy_server.cpp    # 代理服务器
│   └── proxy_server.h
└── protocol/
    ├── shadowsocks.cpp     # SS协议
    ├── shadowsocks.h
    ├── vmess.cpp           # VMess协议
    └── vmess.h
```

### 2. CMakeLists.txt 配置

```cmake
cmake_minimum_required(VERSION 3.4.1)
project(HarmonyProxy)

set(NATIVERENDER_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR})

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 添加编译选项
add_compile_options(-fvisibility=hidden)

# 添加源文件
add_library(entry SHARED
    napi/napi_init.cpp
    proxy/proxy_server.cpp
    protocol/shadowsocks.cpp
    protocol/vmess.cpp
)

# 包含头文件目录
include_directories(
    ${NATIVERENDER_ROOT_DIR}
    ${NATIVERENDER_ROOT_DIR}/proxy
    ${NATIVERENDER_ROOT_DIR}/protocol
)

# 链接依赖库
target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
    libcurl.so
    libssl.so
    libcrypto.so
)
```

### 3. 修改 entry/build-profile.json5

```json5
{
  "apiType": "stageMode",
  "buildOption": {
    "externalNativeOptions": {
      "path": "./src/main/cpp/CMakeLists.txt",
      "arguments": "",
      "cppFlags": "-std=c++17",
      "targets": [
        {
          "name": "entry",
          "runtimeOS": "HarmonyOS"
        }
      ]
    }
  },
  "targets": [
    {
      "name": "default"
    }
  ]
}
```

## 五、Git 配置

### 1. 合并到现有仓库

项目创建完成后，执行以下命令：

```bash
# 进入新创建的项目目录
cd E:\鸿蒙\HarmonyProxy-Dev

# 初始化Git
git init

# 复制现有文件
copy ..\HarmonyProxy\README.md .
copy ..\HarmonyProxy\LICENSE .
copy ..\HarmonyProxy\.gitignore .

# 添加所有文件
git add .

# 提交
git commit -m "feat: Initialize HarmonyOS project with DevEco Studio"

# 连接到GitHub
git remote add origin https://github.com/GF-OrientedProgramming/HarmonyProxy.git

# 拉取远程内容
git pull origin main --allow-unrelated-histories

# 推送（如果需要强制推送）
git push -u origin main --force
```

## 六、开发环境检查清单

创建项目后，请检查以下内容：

- [ ] DevEco Studio 版本 >= 4.0
- [ ] HarmonyOS SDK API >= 10
- [ ] Node.js 版本 >= 16
- [ ] NDK 已安装
- [ ] 项目可以成功编译
- [ ] 可以在模拟器或真机上运行
- [ ] Git 仓库已正确配置

## 七、下一步开发计划

项目创建完成后，按以下顺序开发：

1. **UI框架搭建**
   - 创建主页面布局
   - 实现底部导航
   - 创建节点列表页面

2. **VPN服务实现**
   - 创建VPN服务类
   - 实现VPN连接/断开
   - 处理VPN权限请求

3. **代理服务器**
   - 实现本地SOCKS5代理
   - 集成到VPN服务
   - 测试代理功能

4. **协议实现**
   - 实现Shadowsocks协议
   - 实现VMess协议
   - 实现其他协议

## 八、常见问题

### Q1: VPN权限无法获取？
A: VPN权限需要系统签名或特殊申请，开发阶段可以使用普通网络代理方式测试。

### Q2: Native C++ 编译失败？
A: 检查NDK版本和CMake配置，确保路径正确。

### Q3: 项目无法运行？
A: 检查API版本兼容性，确保设备或模拟器API版本 >= 项目配置的API版本。

---

**创建项目后，请告诉我，我会继续提供具体的代码实现！**
