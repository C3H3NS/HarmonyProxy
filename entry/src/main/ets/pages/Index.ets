@Entry
@Component
struct Index {
  @State message: string = 'HarmonyProxy'

  build() {
    Row() {
      Column() {
        Text(this.message)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007DFF')

        Text('鸿蒙版网络代理工具')
          .fontSize(16)
          .fontColor('#8C8C8C')
          .margin({ top: 8 })

        Button('开始使用')
          .width(200)
          .height(48)
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .borderRadius(24)
          .margin({ top: 32 })
          .onClick(() => {
            console.info('Button clicked');
          })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
