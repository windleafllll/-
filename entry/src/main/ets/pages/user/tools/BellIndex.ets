import { router } from '@kit.ArkUI'

interface toolsUI {
  icon: ResourceStr | null,
  title: ResourceStr,
  subheading: string,
  introduce: string | null
}


@Entry
@Component
struct BellIndex {
  @Builder
  navigationTitle() {
    Row({ space: 10 }) {
      Image($r('app.media.ic_public_back'))
        .width(30)
        .fillColor(Color.White)
        .onClick(() => {
          router.back()
        })
      Text('专注计时核心设计')
        .fontWeight(FontWeight.Bold)
        .fontSize(18)
        .fontColor(Color.White)
    }
    .width('100%')
    .backgroundColor('#f6726e')
    .padding({ left: 15, right: 15 })
  }

  @State toolUI: toolsUI[] = [
    {
      icon: $r('app.media.ic_user_ringtone'),
      title: '铃声震动设置',
      subheading: '开启或关闭铃声设置',
      introduce: null
    },
    {
      icon: $r('app.media.ic_user_music'),
      title: '默认背景音乐 | 白噪音',
      subheading: '舒缓悠扬的音乐让您更加高效',
      introduce: null
    },
    {
      icon: $r('app.media.ic_user_coffee'),
      title: '默认休息时长',
      subheading: '',
      introduce: '5分钟'
    },
  ]
  @State toolsUI: toolsUI[] = [
    {
      icon: $r('app.media.ic_user_lock'),
      title: '锁屏番茄钟',
      subheading: '番茄钟开启后在锁屏界面展示',
      introduce: null
    },
    {
      icon: $r('app.media.ic_user_stop'),
      title: '自定义暂停上限时间',
      subheading: '',
      introduce: '3分钟'
    },
    {
      icon: $r('app.media.ic_user_leave'),
      title: '每月主动退出严格模式计时上限次数',
      subheading: '',
      introduce: '2次'
    },
    {
      icon: $r('app.media.ic_user_pin'),
      title: '固定排序',
      subheading: '开启后，已完成的待办不会移动到列表最下方',
      introduce: null
    },
    {
      icon: $r('app.media.ic_user_line'),
      title: '不在待办名称上划完成线',
      subheading: '开启后，已完成的待办不会画上黑色的横线',
      introduce: null
    },
    {
      icon: $r('app.media.ic_user_midnight'),
      title: '午夜模式',
      subheading: '开启后，0-4点的新计时会被计入前一天',
      introduce: null
    },
    {
      icon: $r('app.media.ic_user_sun'),
      title: '默认在待办计时中开启屏幕常亮',
      subheading: '',
      introduce: null
    },
    {
      icon: $r('app.media.ic_user_change'),
      title: '默认在待办计时开启后横屏',
      subheading: '开启后，在开启番茄钟计时后会自动横屏',
      introduce: null
    },
    {
      icon: $r('app.media.ic_user_accomplish'),
      title: '默认勾选 完成后第二天不显示',
      subheading: '开启后，每个新建的普通待办都会默认勾选 完成后第二天不显示，习惯 或 目标类待办除外',
      introduce: null
    },
  ]
  @State someToolUI: toolsUI[] = [
    {
      icon: null,
      title: '休息计时结束后弹回软件主界面',
      subheading: '',
      introduce: null
    },
    {
      icon: null,
      title: '晚间专注完成后弹出打卡提示',
      subheading: '舒缓悠扬的音乐让您更加高效',
      introduce: null
    },
    {
      icon: null,
      title: '计时结束后在手环发出通知',
      subheading: '',
      introduce: null
    },
    {
      icon: null,
      title: '开启定时提醒通知栏通知',
      subheading: '',
      introduce: null
    },
    {
      icon: null,
      title: '降低计时稳定性选项',
      subheading: '',
      introduce: null
    },
  ]

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 30 }) {
          Text('基础设置')
            .fontSize(19)
            .fontColor('#f6726e')
            .fontWeight(FontWeight.Bold)
          ForEach(this.toolUI, (v: toolsUI) => {
            Row({ space: 10 }) {
              Image(v.icon)
                .width(30)
              Column({ space: 5 }) {
                Text(v.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                Text(v.subheading)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(HorizontalAlign.Start)

              Blank()
              if (v.introduce != null) {
                Text(v.introduce)
                  .fontColor('#f6726e')
                  .fontWeight(FontWeight.Bold)
              }
            }
            .width('100%')
          })
          Text('高级设置 — 番茄钟')
            .fontSize(19)
            .fontColor('#f6726e')
            .fontWeight(FontWeight.Bold)
          ForEach(this.toolsUI, (v: toolsUI) => {
            Row({ space: 10 }) {
              Image(v.icon)
                .width(30)
              Column({ space: 5 }) {
                Text(v.title)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                Text(v.subheading)
                  .fontSize(11)
                  .fontWeight(FontWeight.Medium)
              }
              .width('70%')
              .alignItems(HorizontalAlign.Start)

              Blank()
              if (v.introduce != null) {
                Text(v.introduce)
                  .fontColor('#f6726e')
                  .fontWeight(FontWeight.Bold)
              } else {
                Toggle({ type: ToggleType.Switch })
              }
            }
            .width('100%')
          })
          ForEach(this.someToolUI, (v: toolsUI) => {
            Row() {
              Text(v.title)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
              Blank()
              Toggle({ type: ToggleType.Switch })
            }
            .padding({ left: 40 })
            .width('100%')
          })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .padding(15)
      .backgroundColor('#fff1f1f1')
    }
    .title(this.navigationTitle())
    .titleMode(NavigationTitleMode.Mini)
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .linearGradient({
      direction: GradientDirection.Bottom, // 渐变方向
      repeating: false, // 渐变颜色是否重复
      colors: [['#f6726e', 0.5], ['#fff1f1f1', 0.9]] // 数组末尾元素占比小于1时满足重复着色效果
    })
  }
}