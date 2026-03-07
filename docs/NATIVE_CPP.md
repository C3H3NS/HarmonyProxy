# Native C++ 代理服务器实现指南

## 一、Native C++ 架构

```
┌─────────────────────────────────────┐
│      ArkTS 层 (NAPI接口)            │
│  ┌──────────────────────────────┐  │
│  │   ProxyManager               │  │
│  │   - startProxy()             │  │
│  │   - stopProxy()              │  │
│  │   - getStatus()              │  │
│  └──────────────────────────────┘  │
├─────────────────────────────────────┤
│      NAPI 绑定层                    │
│  ┌──────────────────────────────┐  │
│  │   napi_init.cpp              │  │
│  │   - NAPI方法注册             │  │
│  │   - 类型转换                 │  │
│  └──────────────────────────────┘  │
├─────────────────────────────────────┤
│      C++ 核心层                     │
│  ┌──────────────────────────────┐  │
│  │   LocalProxyServer           │  │
│  │   - Socket监听               │  │
│  │   - 连接处理                 │  │
│  │   - 数据转发                 │  │
│  └──────────────────────────────┘  │
├─────────────────────────────────────┤
│      协议实现层                     │
│  ┌──────────────────────────────┐  │
│  │   Shadowsocks / VMess / ...  │  │
│  │   - 协议封装                 │  │
│  │   - 加密解密                 │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 二、项目目录结构

```
entry/src/main/cpp/
├── CMakeLists.txt              # CMake配置文件
├── types/
│   └── libentry/
│       └── index.d.ts          # TypeScript类型定义
├── napi/
│   ├── napi_init.cpp           # NAPI初始化
│   ├── napi_proxy.cpp          # 代理相关NAPI
│   └── napi_protocol.cpp       # 协议相关NAPI
├── proxy/
│   ├── proxy_server.h          # 代理服务器头文件
│   ├── proxy_server.cpp        # 代理服务器实现
│   ├── connection.h            # 连接管理
│   └── connection.cpp
├── protocol/
│   ├── base_protocol.h         # 协议基类
│   ├── shadowsocks.h           # Shadowsocks协议
│   ├── shadowsocks.cpp
│   ├── vmess.h                 # VMess协议
│   ├── vmess.cpp
│   ├── trojan.h                # Trojan协议
│   └── trojan.cpp
├── crypto/
│   ├── aes.h                   # AES加密
│   ├── aes.cpp
│   ├── chacha20.h              # ChaCha20加密
│   └── chacha20.cpp
└── utils/
    ├── logger.h                # 日志工具
    ├── logger.cpp
    ├── socket_utils.h          # Socket工具
    └── socket_utils.cpp
```

## 三、CMakeLists.txt 配置

文件路径：`entry/src/main/cpp/CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.4.1)
project(HarmonyProxy)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 设置编译选项
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -fvisibility=hidden")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -fvisibility=hidden")

# 定义源文件
set(PROXY_SOURCES
    napi/napi_init.cpp
    napi/napi_proxy.cpp
    proxy/proxy_server.cpp
    proxy/connection.cpp
    protocol/shadowsocks.cpp
    protocol/vmess.cpp
    protocol/trojan.cpp
    crypto/aes.cpp
    crypto/chacha20.cpp
    utils/logger.cpp
    utils/socket_utils.cpp
)

# 创建共享库
add_library(entry SHARED ${PROXY_SOURCES})

# 包含头文件目录
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/proxy
    ${CMAKE_CURRENT_SOURCE_DIR}/protocol
    ${CMAKE_CURRENT_SOURCE_DIR}/crypto
    ${CMAKE_CURRENT_SOURCE_DIR}/utils
)

# 链接系统库
target_link_libraries(entry PUBLIC
    libace_napi.z.so          # NAPI库
    libhilog_ndk.z.so         # 日志库
    libcurl.so                # HTTP库
    libssl.so                 # OpenSSL
    libcrypto.so              # 加密库
    libz.so                   # 压缩库
)
```

## 四、NAPI 接口实现

### 1. NAPI初始化 - napi_init.cpp

文件路径：`entry/src/main/cpp/napi/napi_init.cpp`

```cpp
#include <napi/native_api.h>
#include <hilog/log.h>
#include "proxy_server.h"

constexpr int DOMAIN = 0xFF00;
constexpr const char* TAG = "HarmonyProxy";

// 启动代理服务器
static napi_value StartProxy(napi_env env, napi_callback_info info) {
    size_t argc = 2;
    napi_value args[2];
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    // 获取端口号
    int port;
    napi_get_value_int32(env, args[0], &port);

    // 获取配置对象
    napi_value config = args[1];

    // 提取配置参数
    napi_value serverAddr, password, method;
    napi_get_named_property(env, config, "serverAddress", &serverAddr);
    napi_get_named_property(env, config, "password", &password);
    napi_get_named_property(env, config, "method", &method);

    char serverAddress[256];
    char pwd[256];
    char meth[64];

    napi_get_value_string_utf8(env, serverAddr, serverAddress, sizeof(serverAddress), nullptr);
    napi_get_value_string_utf8(env, password, pwd, sizeof(pwd), nullptr);
    napi_get_value_string_utf8(env, method, meth, sizeof(meth), nullptr);

    // 启动代理服务器
    ProxyConfig proxyConfig;
    proxyConfig.localPort = port;
    strcpy(proxyConfig.serverAddress, serverAddress);
    strcpy(proxyConfig.password, pwd);
    strcpy(proxyConfig.method, meth);

    bool result = ProxyServer::GetInstance()->Start(proxyConfig);

    // 返回结果
    napi_value returnValue;
    napi_get_boolean(env, result, &returnValue);
    return returnValue;
}

// 停止代理服务器
static napi_value StopProxy(napi_env env, napi_callback_info info) {
    ProxyServer::GetInstance()->Stop();

    napi_value returnValue;
    napi_get_boolean(env, true, &returnValue);
    return returnValue;
}

// 获取代理状态
static napi_value GetProxyStatus(napi_env env, napi_callback_info info) {
    bool isRunning = ProxyServer::GetInstance()->IsRunning();

    napi_value returnValue;
    napi_get_boolean(env, isRunning, &returnValue);
    return returnValue;
}

// 注册NAPI方法
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "startProxy", nullptr, StartProxy, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "stopProxy", nullptr, StopProxy, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "getProxyStatus", nullptr, GetProxyStatus, nullptr, nullptr, nullptr, napi_default, nullptr },
    };

    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

// 模块注册
static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) {
    napi_register_module(&demoModule);
}
```

### 2. TypeScript类型定义 - index.d.ts

文件路径：`entry/src/main/cpp/types/libentry/index.d.ts`

```typescript
export interface ProxyConfig {
    serverAddress: string;
    serverPort: number;
    password: string;
    method: string;
    protocol: string;
}

export const startProxy: (port: number, config: ProxyConfig) => boolean;
export const stopProxy: () => void;
export const getProxyStatus: () => boolean;
```

## 五、代理服务器实现

### 1. 代理服务器头文件 - proxy_server.h

文件路径：`entry/src/main/cpp/proxy/proxy_server.h`

```cpp
#ifndef PROXY_SERVER_H
#define PROXY_SERVER_H

#include <string>
#include <thread>
#include <atomic>
#include <vector>
#include <mutex>

struct ProxyConfig {
    int localPort;
    char serverAddress[256];
    int serverPort;
    char password[256];
    char method[64];
    char protocol[32];
};

class ProxyServer {
public:
    static ProxyServer* GetInstance();

    bool Start(const ProxyConfig& config);
    void Stop();
    bool IsRunning() const;

private:
    ProxyServer();
    ~ProxyServer();

    void ServerLoop();
    void HandleClient(int clientSocket);
    bool ConnectToRemote(int& remoteSocket, const std::string& address, int port);

    std::atomic<bool> running_;
    int serverSocket_;
    std::thread serverThread_;
    ProxyConfig config_;
    std::mutex mutex_;

    // 禁止拷贝
    ProxyServer(const ProxyServer&) = delete;
    ProxyServer& operator=(const ProxyServer&) = delete;
};

#endif // PROXY_SERVER_H
```

### 2. 代理服务器实现 - proxy_server.cpp

文件路径：`entry/src/main/cpp/proxy/proxy_server.cpp`

```cpp
#include "proxy_server.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <hilog/log.h>
#include <cstring>
#include <fcntl.h>

constexpr int DOMAIN = 0xFF00;
constexpr const char* TAG = "ProxyServer";
constexpr int BUFFER_SIZE = 8192;
constexpr int BACKLOG = 10;

ProxyServer* ProxyServer::GetInstance() {
    static ProxyServer instance;
    return &instance;
}

ProxyServer::ProxyServer()
    : running_(false)
    , serverSocket_(-1) {
}

ProxyServer::~ProxyServer() {
    Stop();
}

bool ProxyServer::Start(const ProxyConfig& config) {
    if (running_) {
        OH_LOG_INFO(LOG_APP, "Proxy server is already running");
        return true;
    }

    std::lock_guard<std::mutex> lock(mutex_);
    config_ = config;

    // 创建Socket
    serverSocket_ = socket(AF_INET, SOCK_STREAM, 0);
    if (serverSocket_ < 0) {
        OH_LOG_ERROR(LOG_APP, "Failed to create socket");
        return false;
    }

    // 设置Socket选项
    int opt = 1;
    setsockopt(serverSocket_, SOL_SOCKET, SO_REUSEADDR, &opt, sizeof(opt));

    // 绑定地址
    struct sockaddr_in address;
    memset(&address, 0, sizeof(address));
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(config_.localPort);

    if (bind(serverSocket_, (struct sockaddr*)&address, sizeof(address)) < 0) {
        OH_LOG_ERROR(LOG_APP, "Failed to bind socket");
        close(serverSocket_);
        serverSocket_ = -1;
        return false;
    }

    // 监听
    if (listen(serverSocket_, BACKLOG) < 0) {
        OH_LOG_ERROR(LOG_APP, "Failed to listen on socket");
        close(serverSocket_);
        serverSocket_ = -1;
        return false;
    }

    // 启动服务器线程
    running_ = true;
    serverThread_ = std::thread(&ProxyServer::ServerLoop, this);

    OH_LOG_INFO(LOG_APP, "Proxy server started on port %{public}d", config_.localPort);
    return true;
}

void ProxyServer::Stop() {
    if (!running_) {
        return;
    }

    running_ = false;

    // 关闭服务器Socket
    if (serverSocket_ >= 0) {
        close(serverSocket_);
        serverSocket_ = -1;
    }

    // 等待线程结束
    if (serverThread_.joinable()) {
        serverThread_.join();
    }

    OH_LOG_INFO(LOG_APP, "Proxy server stopped");
}

bool ProxyServer::IsRunning() const {
    return running_;
}

void ProxyServer::ServerLoop() {
    struct sockaddr_in clientAddress;
    socklen_t clientLen = sizeof(clientAddress);

    while (running_) {
        // 接受客户端连接
        int clientSocket = accept(serverSocket_, (struct sockaddr*)&clientAddress, &clientLen);
        if (clientSocket < 0) {
            if (running_) {
                OH_LOG_ERROR(LOG_APP, "Failed to accept client connection");
            }
            continue;
        }

        OH_LOG_INFO(LOG_APP, "Client connected");

        // 在新线程中处理客户端
        std::thread clientThread(&ProxyServer::HandleClient, this, clientSocket);
        clientThread.detach();
    }
}

void ProxyServer::HandleClient(int clientSocket) {
    char buffer[BUFFER_SIZE];

    // 1. 接收SOCKS5握手请求
    int bytesRead = recv(clientSocket, buffer, BUFFER_SIZE, 0);
    if (bytesRead <= 0) {
        close(clientSocket);
        return;
    }

    // 2. 验证SOCKS5版本
    if (buffer[0] != 0x05) {
        OH_LOG_ERROR(LOG_APP, "Invalid SOCKS version");
        close(clientSocket);
        return;
    }

    // 3. 发送SOCKS5响应（无需认证）
    char response[] = { 0x05, 0x00 };
    send(clientSocket, response, 2, 0);

    // 4. 接收连接请求
    bytesRead = recv(clientSocket, buffer, BUFFER_SIZE, 0);
    if (bytesRead <= 0) {
        close(clientSocket);
        return;
    }

    // 5. 解析目标地址
    if (buffer[0] != 0x05 || buffer[1] != 0x01) {
        OH_LOG_ERROR(LOG_APP, "Invalid SOCKS request");
        close(clientSocket);
        return;
    }

    std::string targetAddress;
    int targetPort;

    if (buffer[3] == 0x01) {
        // IPv4地址
        char ip[16];
        snprintf(ip, sizeof(ip), "%d.%d.%d.%d",
                 (unsigned char)buffer[4], (unsigned char)buffer[5],
                 (unsigned char)buffer[6], (unsigned char)buffer[7]);
        targetAddress = ip;
        targetPort = (unsigned char)buffer[8] * 256 + (unsigned char)buffer[9];
    } else if (buffer[3] == 0x03) {
        // 域名
        int domainLen = (unsigned char)buffer[4];
        targetAddress = std::string(buffer + 5, domainLen);
        targetPort = (unsigned char)buffer[5 + domainLen] * 256 + (unsigned char)buffer[6 + domainLen];
    } else {
        OH_LOG_ERROR(LOG_APP, "Unsupported address type");
        close(clientSocket);
        return;
    }

    OH_LOG_INFO(LOG_APP, "Connecting to %{public}s:%{public}d", targetAddress.c_str(), targetPort);

    // 6. 连接到远程服务器（通过代理协议）
    int remoteSocket;
    if (!ConnectToRemote(remoteSocket, targetAddress, targetPort)) {
        // 发送连接失败响应
        char failResponse[] = { 0x05, 0x01, 0x00, 0x01, 0, 0, 0, 0, 0, 0 };
        send(clientSocket, failResponse, 10, 0);
        close(clientSocket);
        return;
    }

    // 7. 发送连接成功响应
    char successResponse[] = { 0x05, 0x00, 0x00, 0x01, 0, 0, 0, 0, 0, 0 };
    send(clientSocket, successResponse, 10, 0);

    // 8. 数据转发
    fd_set readSet;
    int maxFd = std::max(clientSocket, remoteSocket) + 1;

    while (running_) {
        FD_ZERO(&readSet);
        FD_SET(clientSocket, &readSet);
        FD_SET(remoteSocket, &readSet);

        struct timeval timeout;
        timeout.tv_sec = 1;
        timeout.tv_usec = 0;

        int ready = select(maxFd, &readSet, nullptr, nullptr, &timeout);
        if (ready < 0) {
            break;
        }

        if (FD_ISSET(clientSocket, &readSet)) {
            bytesRead = recv(clientSocket, buffer, BUFFER_SIZE, 0);
            if (bytesRead <= 0) {
                break;
            }
            send(remoteSocket, buffer, bytesRead, 0);
        }

        if (FD_ISSET(remoteSocket, &readSet)) {
            bytesRead = recv(remoteSocket, buffer, BUFFER_SIZE, 0);
            if (bytesRead <= 0) {
                break;
            }
            send(clientSocket, buffer, bytesRead, 0);
        }
    }

    close(remoteSocket);
    close(clientSocket);
}

bool ProxyServer::ConnectToRemote(int& remoteSocket, const std::string& address, int port) {
    // TODO: 根据协议类型连接到远程代理服务器
    // 这里需要实现具体的协议（Shadowsocks/VMess等）

    // 简化实现：直接连接（仅用于测试）
    remoteSocket = socket(AF_INET, SOCK_STREAM, 0);
    if (remoteSocket < 0) {
        return false;
    }

    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    inet_pton(AF_INET, address.c_str(), &serverAddr.sin_addr);

    if (connect(remoteSocket, (struct sockaddr*)&serverAddr, sizeof(serverAddr)) < 0) {
        close(remoteSocket);
        return false;
    }

    return true;
}
```

## 六、在ArkTS中调用Native代码

### 1. 创建NativeProxy.ets

文件路径：`entry/src/main/ets/utils/NativeProxy.ets`

```typescript
import nativeModule from 'libentry.so';

export interface ProxyConfig {
    serverAddress: string;
    serverPort: number;
    password: string;
    method: string;
    protocol: string;
}

export class NativeProxy {
    /**
     * 启动代理服务器
     */
    static startProxy(port: number, config: ProxyConfig): boolean {
        try {
            return nativeModule.startProxy(port, config);
        } catch (error) {
            console.error('Failed to start proxy:', error);
            return false;
        }
    }

    /**
     * 停止代理服务器
     */
    static stopProxy(): void {
        try {
            nativeModule.stopProxy();
        } catch (error) {
            console.error('Failed to stop proxy:', error);
        }
    }

    /**
     * 获取代理状态
     */
    static getProxyStatus(): boolean {
        try {
            return nativeModule.getProxyStatus();
        } catch (error) {
            console.error('Failed to get proxy status:', error);
            return false;
        }
    }
}
```

### 2. 在VPNService中使用

修改 `entry/src/main/ets/service/VPNService.ets`：

```typescript
import { NativeProxy, ProxyConfig } from '../utils/NativeProxy';

export class VPNService {
    // ... 其他代码

    private async startLocalProxy(config: VpnConfig): Promise<void> {
        const proxyConfig: ProxyConfig = {
            serverAddress: config.serverAddress,
            serverPort: config.serverPort,
            password: config.password || '',
            method: config.method || 'aes-256-gcm',
            protocol: config.protocol
        };

        const result = NativeProxy.startProxy(this.localProxyPort, proxyConfig);
        if (!result) {
            throw new Error('Failed to start local proxy');
        }
    }

    private async stopLocalProxy(): Promise<void> {
        NativeProxy.stopProxy();
    }
}
```

## 七、编译和调试

### 1. 编译Native代码

```bash
# 在项目根目录执行
cd E:\鸿蒙\HarmonyProxy-Dev
hvigorw assembleHap
```

### 2. 查看日志

```bash
# 使用hdc工具查看日志
hdc shell hilog | grep HarmonyProxy
```

### 3. 调试技巧

- 使用 `OH_LOG_INFO`、`OH_LOG_ERROR` 输出日志
- 检查Socket返回值，处理错误情况
- 使用 `netstat` 查看端口占用情况

## 八、下一步

Native C++代理服务器实现后，需要：

1. **实现具体的代理协议**（Shadowsocks、VMess等）
2. **添加加密支持**（AES、ChaCha20等）
3. **优化性能**（连接池、多线程等）
4. **添加错误处理**和重连机制

---

**完成Native C++配置后，项目基础框架就搭建完成了！**
