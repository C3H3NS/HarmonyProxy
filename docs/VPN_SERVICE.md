# VPN服务实现指南

## 一、VPN服务架构

```
┌─────────────────────────────────────┐
│         应用层 (ArkTS)               │
│  ┌──────────────────────────────┐  │
│  │   VPNServiceManager          │  │
│  │   - startVpn()               │  │
│  │   - stopVpn()                │  │
│  │   - getStatus()              │  │
│  └──────────────────────────────┘  │
├─────────────────────────────────────┤
│      VPN Service (系统API)          │
│  ┌──────────────────────────────┐  │
│  │   @ohos.net.vpn              │  │
│  │   - createVpnConnection()    │  │
│  │   - VpnConfig                │  │
│  └──────────────────────────────┘  │
├─────────────────────────────────────┤
│     本地代理服务器 (Native C++)      │
│  ┌──────────────────────────────┐  │
│  │   LocalProxyServer           │  │
│  │   - Start(port)              │  │
│  │   - HandleConnection()       │  │
│  │   - ForwardTraffic()         │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

## 二、VPN服务实现代码

### 1. 创建 VPNService.ets

文件路径：`entry/src/main/ets/service/VPNService.ets`

```typescript
import vpn from '@ohos.net.vpn';
import hilog from '@ohos.hilog';

const TAG = 'VPNService';
const DOMAIN = 0xFF00;

export interface VpnConfig {
  serverAddress: string;
  serverPort: number;
  protocol: string;
  password?: string;
  method?: string;
}

export class VPNService {
  private vpnConnection: vpn.VpnConnection | null = null;
  private isConnected: boolean = false;
  private localProxyPort: number = 1080;

  /**
   * 启动VPN连接
   */
  async startVpn(config: VpnConfig): Promise<boolean> {
    try {
      hilog.info(DOMAIN, TAG, 'Starting VPN connection...');

      // 1. 创建VPN配置
      const vpnConfig: vpn.VpnConfig = {
        // 虚拟网卡地址
        addresses: [{
          address: {
            address: '10.0.0.2',
            family: 1  // IPv4
          },
          prefixLength: 24
        }],
        // 路由规则 - 拦截所有流量
        routes: [{
          destination: {
            address: '0.0.0.0',
            family: 1
          },
          prefixLength: 0,
          gateway: {
            address: '10.0.0.1',
            family: 1
          }
        }],
        // DNS服务器
        dnsServers: ['8.8.8.8', '8.8.4.4'],
        // 搜索域
        searchDomains: ['local'],
        // MTU
        mtu: 1500
      };

      // 2. 创建VPN连接
      this.vpnConnection = vpn.createVpnConnection(vpnConfig);

      // 3. 连接VPN
      await this.vpnConnection.connect();

      // 4. 启动本地代理服务器
      await this.startLocalProxy(config);

      this.isConnected = true;
      hilog.info(DOMAIN, TAG, 'VPN connection established successfully');
      return true;

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to start VPN: ${error.message}`);
      this.isConnected = false;
      return false;
    }
  }

  /**
   * 停止VPN连接
   */
  async stopVpn(): Promise<void> {
    try {
      hilog.info(DOMAIN, TAG, 'Stopping VPN connection...');

      // 1. 停止本地代理服务器
      await this.stopLocalProxy();

      // 2. 断开VPN连接
      if (this.vpnConnection) {
        await this.vpnConnection.disconnect();
        this.vpnConnection = null;
      }

      this.isConnected = false;
      hilog.info(DOMAIN, TAG, 'VPN connection stopped successfully');

    } catch (error) {
      hilog.error(DOMAIN, TAG, `Failed to stop VPN: ${error.message}`);
    }
  }

  /**
   * 获取VPN连接状态
   */
  getStatus(): boolean {
    return this.isConnected;
  }

  /**
   * 启动本地代理服务器
   */
  private async startLocalProxy(config: VpnConfig): Promise<void> {
    // 调用Native C++代理服务器
    // 这里需要通过NAPI调用C++代码
    hilog.info(DOMAIN, TAG, `Starting local proxy on port ${this.localProxyPort}`);

    // TODO: 调用Native代理服务器
    // await nativeProxy.startProxy(this.localProxyPort, config);
  }

  /**
   * 停止本地代理服务器
   */
  private async stopLocalProxy(): Promise<void> {
    hilog.info(DOMAIN, TAG, 'Stopping local proxy...');

    // TODO: 调用Native代理服务器停止
    // await nativeProxy.stopProxy();
  }
}

// 导出单例
export default new VPNService();
```

### 2. 创建 VPN连接状态管理

文件路径：`entry/src/main/ets/viewmodel/VpnViewModel.ets`

```typescript
import { VPNService, VpnConfig } from '../service/VPNService';

export class VpnViewModel {
  private vpnService: VPNService;
  private isConnected: boolean = false;

  constructor() {
    this.vpnService = new VPNService();
  }

  /**
   * 连接VPN
   */
  async connect(config: VpnConfig): Promise<boolean> {
    const result = await this.vpnService.startVpn(config);
    this.isConnected = result;
    return result;
  }

  /**
   * 断开VPN
   */
  async disconnect(): Promise<void> {
    await this.vpnService.stopVpn();
    this.isConnected = false;
  }

  /**
   * 获取连接状态
   */
  getConnectionStatus(): boolean {
    return this.isConnected;
  }
}
```

## 三、VPN权限处理

### 1. 权限请求流程

```typescript
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';

async function requestVpnPermission(): Promise<boolean> {
  try {
    const atManager = abilityAccessCtrl.createAtManager();
    const bundleInfo = await bundleManager.getBundleInfoForSelf(
      bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
    );

    // 检查VPN权限
    const grantStatus = await atManager.checkAccessToken(
      bundleInfo.appInfo.accessTokenId,
      'ohos.permission.CONNECT_VPN'
    );

    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      return true;
    }

    // 请求权限
    const result = await atManager.requestPermissionsFromUser({
      permissions: ['ohos.permission.CONNECT_VPN']
    });

    return result.authResults[0] === 0;

  } catch (error) {
    hilog.error(DOMAIN, TAG, `Permission request failed: ${error.message}`);
    return false;
  }
}
```

### 2. 在EntryAbility中初始化

文件路径：`entry/src/main/ets/entryability/EntryAbility.ets`

```typescript
import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';

const TAG = 'EntryAbility';
const DOMAIN = 0xFF00;

export default class EntryAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(DOMAIN, TAG, 'Ability onCreate');

    // 初始化VPN服务
    this.initVpnService();
  }

  onDestroy() {
    hilog.info(DOMAIN, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, `Failed to load content: ${err.message}`);
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy() {
    hilog.info(DOMAIN, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(DOMAIN, TAG, 'Ability onForeground');
  }

  onBackground() {
    hilog.info(DOMAIN, TAG, 'Ability onBackground');
  }

  private async initVpnService() {
    // 请求VPN权限
    const hasPermission = await requestVpnPermission();
    if (!hasPermission) {
      hilog.warn(DOMAIN, TAG, 'VPN permission not granted');
    }
  }
}
```

## 四、VPN配置选项

### 1. 完整的VPN配置参数

```typescript
interface VpnConfig {
  // 基础配置
  serverAddress: string;      // 服务器地址
  serverPort: number;         // 服务器端口
  protocol: string;           // 协议类型 (ss/ssr/vmess/trojan)

  // 认证信息
  password?: string;          // 密码
  method?: string;            // 加密方法
  uuid?: string;              // VMess UUID
  alterId?: number;           // VMess alterId

  // 高级配置
  dnsServers?: string[];      // DNS服务器
  mtu?: number;               // MTU大小
  routeAll?: boolean;         // 是否全局代理

  // 协议特定配置
  obfs?: string;              // 混淆类型
  obfsParam?: string;         // 混淆参数
  network?: string;           // 传输协议 (tcp/ws)
  tls?: boolean;              // 是否启用TLS
}
```

### 2. 预设配置模板

```typescript
// Shadowsocks配置
const ssConfig: VpnConfig = {
  serverAddress: 'example.com',
  serverPort: 8388,
  protocol: 'shadowsocks',
  password: 'your-password',
  method: 'aes-256-gcm',
  dnsServers: ['8.8.8.8', '1.1.1.1'],
  mtu: 1500
};

// VMess配置
const vmessConfig: VpnConfig = {
  serverAddress: 'example.com',
  serverPort: 443,
  protocol: 'vmess',
  uuid: 'your-uuid',
  alterId: 0,
  network: 'ws',
  tls: true,
  dnsServers: ['8.8.8.8']
};

// Trojan配置
const trojanConfig: VpnConfig = {
  serverAddress: 'example.com',
  serverPort: 443,
  protocol: 'trojan',
  password: 'your-password',
  tls: true,
  dnsServers: ['8.8.8.8']
};
```

## 五、VPN状态监听

### 1. 创建VPN状态监听器

```typescript
import vpn from '@ohos.net.vpn';

class VpnStateListener {
  private vpnConnection: vpn.VpnConnection | null = null;

  // 监听VPN状态变化
  registerStateListener(callback: (state: vpn.VpnConnectState) => void) {
    if (this.vpnConnection) {
      this.vpnConnection.on('stateChange', callback);
    }
  }

  // 取消监听
  unregisterStateListener() {
    if (this.vpnConnection) {
      this.vpnConnection.off('stateChange');
    }
  }
}
```

### 2. 状态处理

```typescript
function handleVpnState(state: vpn.VpnConnectState) {
  switch (state) {
    case vpn.VpnConnectState.CONNECTING:
      hilog.info(DOMAIN, TAG, 'VPN is connecting...');
      // 更新UI显示连接中
      break;

    case vpn.VpnConnectState.CONNECTED:
      hilog.info(DOMAIN, TAG, 'VPN connected');
      // 更新UI显示已连接
      break;

    case vpn.VpnConnectState.DISCONNECTED:
      hilog.info(DOMAIN, TAG, 'VPN disconnected');
      // 更新UI显示已断开
      break;

    case vpn.VpnConnectState.FAILED:
      hilog.error(DOMAIN, TAG, 'VPN connection failed');
      // 显示错误信息
      break;
  }
}
```

## 六、测试VPN功能

### 1. 单元测试

```typescript
import { describe, it, expect } from '@ohos/hypium';
import VPNService from '../service/VPNService';

describe('VPNService Tests', () => {
  it('should start VPN successfully', async () => {
    const vpnService = new VPNService();
    const config = {
      serverAddress: '127.0.0.1',
      serverPort: 1080,
      protocol: 'socks5'
    };

    const result = await vpnService.startVpn(config);
    expect(result).assertTrue();
  });

  it('should stop VPN successfully', async () => {
    const vpnService = new VPNService();
    await vpnService.stopVpn();
    expect(vpnService.getStatus()).assertFalse();
  });
});
```

## 七、常见问题与解决方案

### Q1: VPN连接失败
**原因**：权限未授予或配置错误
**解决**：
1. 检查VPN权限是否已授予
2. 验证服务器地址和端口是否正确
3. 检查网络连接状态

### Q2: 无法拦截流量
**原因**：路由配置不正确
**解决**：
1. 确保路由规则设置为 0.0.0.0/0
2. 检查虚拟网卡地址配置
3. 验证DNS服务器配置

### Q3: VPN断开后无法上网
**原因**：路由表未恢复
**解决**：
1. 确保正确调用 disconnect()
2. 重启网络服务
3. 检查系统网络设置

## 八、下一步

VPN服务实现后，需要：

1. **实现本地代理服务器**（Native C++）
2. **集成代理协议**（SS/VMess等）
3. **创建UI界面**（连接按钮、状态显示）
4. **添加节点管理功能**

---

**完成VPN服务后，继续实现本地代理服务器！**
