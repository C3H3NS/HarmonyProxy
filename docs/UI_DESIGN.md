# UI界面设计指南

## 一、整体UI架构

```
┌─────────────────────────────────────┐
│          顶部标题栏                  │
├─────────────────────────────────────┤
│                                     │
│          主内容区域                  │
│    (根据Tab切换显示不同页面)         │
│                                     │
│                                     │
├─────────────────────────────────────┤
│          底部导航栏                  │
│  [首页] [节点] [规则] [设置]         │
└─────────────────────────────────────┘
```

## 二、主页面实现

### 1. 创建主页面 Index.ets

文件路径：`entry/src/main/ets/pages/Index.ets`

```typescript
import { Home } from './Home';
import { Nodes } from './Nodes';
import { Rules } from './Rules';
import { Settings } from './Settings';

@Entry
@Component
struct Index {
  @State currentTabIndex: number = 0;

  // 页面列表
  private tabBuilder(index: number, title: string, icon: Resource) {
    TabContent() {
      this.getPageContent(index)
    }
    .tabBar(this.TabBuilder(index, title, icon))
  }

  // 根据索引返回对应页面
  @Builder
  getPageContent(index: number) {
    if (index === 0) {
      Home()
    } else if (index === 1) {
      Nodes()
    } else if (index === 2) {
      Rules()
    } else if (index === 3) {
      Settings()
    }
  }

  // 自定义TabBar
  @Builder
  TabBuilder(index: number, title: string, icon: Resource) {
    Column() {
      Image(icon)
        .width(24)
        .height(24)
        .margin({ bottom: 4 })
        .fillColor(this.currentTabIndex === index ? '#007DFF' : '#8C8C8C')

      Text(title)
        .fontSize(12)
        .fontColor(this.currentTabIndex === index ? '#007DFF' : '#8C8C8C')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Tabs({ barPosition: BarPosition.End }) {
        this.tabBuilder(0, '首页', $r('app.media.ic_home'))
        this.tabBuilder(1, '节点', $r('app.media.ic_node'))
        this.tabBuilder(2, '规则', $r('app.media.ic_rule'))
        this.tabBuilder(3, '设置', $r('app.media.ic_settings'))
      }
      .barHeight(56)
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
```

## 三、首页 - Home.ets

文件路径：`entry/src/main/ets/pages/Home.ets`

```typescript
import VPNService from '../service/VPNService';
import { VpnConfig } from '../service/VPNService';

@Entry
@Component
export struct Home {
  @State isConnected: boolean = false;
  @State selectedNode: string = '未选择节点';
  @State connectionTime: string = '00:00:00';
  @State uploadSpeed: string = '0 B/s';
  @State downloadSpeed: string = '0 B/s';
  private vpnService: VPNService = VPNService;

  build() {
    Column() {
      // 顶部标题
      this.TitleBar()

      // 连接状态卡片
      this.ConnectionCard()

      // 流量统计
      this.TrafficStats()

      // 快捷操作
      this.QuickActions()

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  TitleBar() {
    Row() {
      Text('HarmonyProxy')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')

      Blank()

      Image($r('app.media.ic_notification'))
        .width(24)
        .height(24)
        .fillColor('#1A1A1A')
        .onClick(() => {
          // 打开通知设置
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  ConnectionCard() {
    Column() {
      // 连接状态图标
      Column() {
        Image(this.isConnected ? $r('app.media.ic_connected') : $r('app.media.ic_disconnected'))
          .width(80)
          .height(80)
          .fillColor(this.isConnected ? '#52C41A' : '#8C8C8C')

        Text(this.isConnected ? '已连接' : '未连接')
          .fontSize(16)
          .fontColor(this.isConnected ? '#52C41A' : '#8C8C8C')
          .margin({ top: 8 })

        Text(this.selectedNode)
          .fontSize(14)
          .fontColor('#8C8C8C')
          .margin({ top: 4 })
      }
      .margin({ top: 32, bottom: 24 })

      // 连接按钮
      Button(this.isConnected ? '断开连接' : '连接')
        .width(200)
        .height(48)
        .fontSize(16)
        .fontColor(Color.White)
        .backgroundColor(this.isConnected ? '#FF4D4F' : '#007DFF')
        .borderRadius(24)
        .onClick(() => {
          this.toggleConnection();
        })

      // 连接时长
      if (this.isConnected) {
        Text(`连接时长: ${this.connectionTime}`)
          .fontSize(14)
          .fontColor('#8C8C8C')
          .margin({ top: 16 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ top: 16, left: 16, right: 16 })
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  TrafficStats() {
    Column() {
      Text('流量统计')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')
        .margin({ bottom: 12 })

      Row() {
        // 上传速度
        Column() {
          Image($r('app.media.ic_upload'))
            .width(24)
            .height(24)
            .fillColor('#007DFF')

          Text('上传')
            .fontSize(12)
            .fontColor('#8C8C8C')
            .margin({ top: 4 })

          Text(this.uploadSpeed)
            .fontSize(16)
            .fontColor('#1A1A1A')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 2 })
        }
        .layoutWeight(1)

        // 分隔线
        Divider()
          .vertical(true)
          .height(60)
          .color('#E8E8E8')

        // 下载速度
        Column() {
          Image($r('app.media.ic_download'))
            .width(24)
            .height(24)
            .fillColor('#52C41A')

          Text('下载')
            .fontSize(12)
            .fontColor('#8C8C8C')
            .margin({ top: 4 })

          Text(this.downloadSpeed)
            .fontSize(16)
            .fontColor('#1A1A1A')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 2 })
        }
        .layoutWeight(1)
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ top: 16, left: 16, right: 16 })
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  QuickActions() {
    Column() {
      Text('快捷操作')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1A1A1A')
        .margin({ bottom: 12 })

      Row() {
        this.ActionItem($r('app.media.ic_scan'), '扫码导入', () => {
          // 扫码导入
        })

        this.ActionItem($r('app.media.ic_clipboard'), '从剪贴板导入', () => {
          // 从剪贴板导入
        })

        this.ActionItem($r('app.media.ic_speedtest'), '延迟测试', () => {
          // 延迟测试
        })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceAround)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ top: 16, left: 16, right: 16 })
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
  }

  @Builder
  ActionItem(icon: Resource, title: string, action: () => void) {
    Column() {
      Image(icon)
        .width(32)
        .height(32)
        .fillColor('#007DFF')

      Text(title)
        .fontSize(12)
        .fontColor('#1A1A1A')
        .margin({ top: 8 })
    }
    .onClick(action)
  }

  // 切换连接状态
  private async toggleConnection() {
    if (this.isConnected) {
      await this.vpnService.stopVpn();
      this.isConnected = false;
    } else {
      // TODO: 获取选中的节点配置
      const config: VpnConfig = {
        serverAddress: 'example.com',
        serverPort: 8388,
        protocol: 'shadowsocks',
        password: 'password',
        method: 'aes-256-gcm'
      };

      const result = await this.vpnService.startVpn(config);
      this.isConnected = result;
    }
  }
}
```

## 四、节点管理页面 - Nodes.ets

文件路径：`entry/src/main/ets/pages/Nodes.ets`

```typescript
@Entry
@Component
export struct Nodes {
  @State nodeGroups: Array<NodeGroup> = [
    {
      name: '香港节点',
      nodes: [
        { id: 1, name: '香港-01', address: 'hk1.example.com', port: 8388, latency: 120 },
        { id: 2, name: '香港-02', address: 'hk2.example.com', port: 8388, latency: 150 }
      ]
    },
    {
      name: '日本节点',
      nodes: [
        { id: 3, name: '日本-01', address: 'jp1.example.com', port: 8388, latency: 80 }
      ]
    }
  ];

  build() {
    Column() {
      // 标题栏
      this.TitleBar()

      // 节点列表
      List() {
        ForEach(this.nodeGroups, (group: NodeGroup) => {
          ListItemGroup({ header: this.GroupHeader(group.name) }) {
            ForEach(group.nodes, (node: Node) => {
              ListItem() {
                this.NodeItem(node)
              }
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: '#E8E8E8' })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  TitleBar() {
    Row() {
      Text('节点管理')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1A1A1A')

      Blank()

      // 添加节点按钮
      Image($r('app.media.ic_add'))
        .width(24)
        .height(24)
        .fillColor('#007DFF')
        .onClick(() => {
          // 添加节点
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  GroupHeader(name: string) {
    Row() {
      Text(name)
        .fontSize(14)
        .fontColor('#8C8C8C')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .height(40)
    .padding({ left: 16 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  NodeItem(node: Node) {
    Row() {
      Column() {
        Text(node.name)
          .fontSize(16)
          .fontColor('#1A1A1A')
          .fontWeight(FontWeight.Medium)

        Text(`${node.address}:${node.port}`)
          .fontSize(12)
          .fontColor('#8C8C8C')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      // 延迟显示
      Column() {
        Text(`${node.latency}ms`)
          .fontSize(14)
          .fontColor(this.getLatencyColor(node.latency))
          .fontWeight(FontWeight.Medium)

        Image($r('app.media.ic_more'))
          .width(20)
          .height(20)
          .fillColor('#8C8C8C')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
    .onClick(() => {
      // 选择节点
    })
  }

  // 根据延迟返回颜色
  private getLatencyColor(latency: number): ResourceColor {
    if (latency < 100) {
      return '#52C41A';
    } else if (latency < 200) {
      return '#FAAD14';
    } else {
      return '#FF4D4F';
    }
  }
}

// 数据模型
interface Node {
  id: number;
  name: string;
  address: string;
  port: number;
  latency: number;
}

interface NodeGroup {
  name: string;
  nodes: Array<Node>;
}
```

## 五、规则配置页面 - Rules.ets

文件路径：`entry/src/main/ets/pages/Rules.ets`

```typescript
@Entry
@Component
export struct Rules {
  @State ruleGroups: Array<RuleGroup> = [
    {
      name: '代理规则',
      rules: [
        { domain: 'google.com', action: 'PROXY' },
        { domain: 'youtube.com', action: 'PROXY' }
      ]
    },
    {
      name: '直连规则',
      rules: [
        { domain: 'baidu.com', action: 'DIRECT' },
        { domain: 'taobao.com', action: 'DIRECT' }
      ]
    }
  ];

  build() {
    Column() {
      this.TitleBar()

      List() {
        ForEach(this.ruleGroups, (group: RuleGroup) => {
          ListItemGroup({ header: this.GroupHeader(group.name) }) {
            ForEach(group.rules, (rule: Rule) => {
              ListItem() {
                this.RuleItem(rule)
              }
            })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  TitleBar() {
    Row() {
      Text('规则配置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Blank()

      Image($r('app.media.ic_add'))
        .width(24)
        .height(24)
        .fillColor('#007DFF')
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  GroupHeader(name: string) {
    Row() {
      Text(name)
        .fontSize(14)
        .fontColor('#8C8C8C')
    }
    .width('100%')
    .height(40)
    .padding({ left: 16 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  RuleItem(rule: Rule) {
    Row() {
      Text(rule.domain)
        .fontSize(16)
        .fontColor('#1A1A1A')
        .layoutWeight(1)

      Text(rule.action)
        .fontSize(14)
        .fontColor(rule.action === 'PROXY' ? '#007DFF' : '#52C41A')
        .fontWeight(FontWeight.Medium)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }
}

interface Rule {
  domain: string;
  action: string;
}

interface RuleGroup {
  name: string;
  rules: Array<Rule>;
}
```

## 六、设置页面 - Settings.ets

文件路径：`entry/src/main/ets/pages/Settings.ets`

```typescript
@Entry
@Component
export struct Settings {
  @State autoConnect: boolean = false;
  @State dnsMode: number = 0; // 0: 系统DNS, 1: 自定义DNS

  build() {
    Column() {
      this.TitleBar()

      List() {
        // 连接设置
        ListItemGroup({ header: this.SectionHeader('连接设置') }) {
          ListItem() {
            this.SettingItem('自动连接', () => {
              Toggle({ type: ToggleType.Switch, isOn: this.autoConnect })
                .onChange((isOn: boolean) => {
                  this.autoConnect = isOn;
                })
            })
          }

          ListItem() {
            this.SettingItem('DNS设置', () => {
              Text(this.dnsMode === 0 ? '系统DNS' : '自定义DNS')
                .fontSize(14)
                .fontColor('#8C8C8C')
            })
          }
        }

        // 订阅管理
        ListItemGroup({ header: this.SectionHeader('订阅管理') }) {
          ListItem() {
            this.SettingItem('订阅列表', () => {
              Image($r('app.media.ic_arrow_right'))
                .width(20)
                .height(20)
                .fillColor('#8C8C8C')
            })
          }

          ListItem() {
            this.SettingItem('自动更新订阅', () => {
              Toggle({ type: ToggleType.Switch, isOn: false })
            })
          }
        }

        // 其他设置
        ListItemGroup({ header: this.SectionHeader('其他') }) {
          ListItem() {
            this.SettingItem('关于', () => {
              Image($r('app.media.ic_arrow_right'))
                .width(20)
                .height(20)
                .fillColor('#8C8C8C')
            })
          }

          ListItem() {
            this.SettingItem('反馈', () => {
              Image($r('app.media.ic_arrow_right'))
                .width(20)
                .height(20)
                .fillColor('#8C8C8C')
            })
          }
        }
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  TitleBar() {
    Row() {
      Text('设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  @Builder
  SectionHeader(title: string) {
    Row() {
      Text(title)
        .fontSize(14)
        .fontColor('#8C8C8C')
    }
    .width('100%')
    .height(40)
    .padding({ left: 16 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  SettingItem(title: string, rightContent: () => void) {
    Row() {
      Text(title)
        .fontSize(16)
        .fontColor('#1A1A1A')
        .layoutWeight(1)

      rightContent()
    }
    .width('100%')
    .padding(16)
    .backgroundColor(Color.White)
  }
}
```

## 七、资源文件准备

### 1. 图标资源

需要在 `entry/src/main/resources/base/media/` 目录下添加以下图标：

```
media/
├── ic_home.png           # 首页图标
├── ic_node.png           # 节点图标
├── ic_rule.png           # 规则图标
├── ic_settings.png       # 设置图标
├── ic_connected.png      # 已连接图标
├── ic_disconnected.png   # 未连接图标
├── ic_upload.png         # 上传图标
├── ic_download.png       # 下载图标
├── ic_scan.png           # 扫码图标
├── ic_clipboard.png      # 剪贴板图标
├── ic_speedtest.png      # 测速图标
├── ic_add.png            # 添加图标
├── ic_more.png           # 更多图标
└── ic_arrow_right.png    # 右箭头图标
```

### 2. 颜色资源

在 `entry/src/main/resources/base/element/color.json` 中定义：

```json
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "primary",
      "value": "#007DFF"
    },
    {
      "name": "success",
      "value": "#52C41A"
    },
    {
      "name": "warning",
      "value": "#FAAD14"
    },
    {
      "name": "error",
      "value": "#FF4D4F"
    },
    {
      "name": "text_primary",
      "value": "#1A1A1A"
    },
    {
      "name": "text_secondary",
      "value": "#8C8C8C"
    },
    {
      "name": "divider",
      "value": "#E8E8E8"
    },
    {
      "name": "background",
      "value": "#F5F5F5"
    }
  ]
}
```

## 八、页面路由配置

在 `entry/src/main/resources/base/profile/main_pages.json` 中配置：

```json
{
  "src": [
    "pages/Index",
    "pages/Home",
    "pages/Nodes",
    "pages/Rules",
    "pages/Settings"
  ]
}
```

---

**UI框架搭建完成后，继续实现Native C++代理服务器！**
