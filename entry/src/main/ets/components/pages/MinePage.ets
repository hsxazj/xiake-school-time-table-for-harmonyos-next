// 用户信息接口
interface UserInfo {
  avatar: string;
  username: string;
  studentId: string;
  college: string;
  major: string;
  className: string;
}

// 菜单项类型接口
interface MenuItemType {
  icon: string;
  title: string;
  desc: string;
}

@Component
export struct MinePage {
  @State private userInfo: UserInfo = {
    avatar: '👤',
    username: '霞客同学',
    studentId: '2024001',
    college: '计算机学院',
    major: '软件工程',
    className: '软工2024-1班'
  };

  build() {
    Column() {
      // 用户信息卡片
      Column() {
        Row() {
          // 头像
          Text(this.userInfo.avatar)
            .fontSize(48)
            .width(80)
            .height(80)
            .backgroundColor('#E3F2FD')
            .borderRadius(40)
            .textAlign(TextAlign.Center)
            .margin({ right: 16 })

          // 用户信息
          Column() {
            Text(this.userInfo.username)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .margin({ bottom: 4 })
            Text(`学号：${this.userInfo.studentId}`)
              .fontSize(14)
              .fontColor('#666666')
              .margin({ bottom: 2 })
            Text(`${this.userInfo.college} · ${this.userInfo.major}`)
              .fontSize(12)
              .fontColor('#999999')
              .margin({ bottom: 2 })
            Text(this.userInfo.className)
              .fontSize(12)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Center)
      }
      .width('90%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({
        radius: 8,
        color: 'rgba(0, 0, 0, 0.1)',
        offsetY: 2
      })
      .margin({ top: 50, bottom: 20 })

      // 功能列表
      Column() {
        this.MenuSection('个人信息', this.getPersonalItems())
        this.MenuSection('学习相关', this.getStudyItems())
        this.MenuSection('系统功能', this.getSystemItems())
      }
      .width('90%')
      .layoutWeight(1)

      Blank()

      // 退出登录按钮
      Button('退出登录')
        .width('60%')
        .height(45)
        .fontSize(16)
        .fontColor('#FF5722')
        .backgroundColor(Color.White)
        .borderRadius(22)
        .border({
          width: 1,
          color: '#FF5722'
        })
        .margin({ bottom: 60 })
        .onClick(() => {
          // 退出登录逻辑
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  MenuSection(title: string, items: MenuItemType[]) {
    Column() {
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#333333')
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        ForEach(items, (item: MenuItemType, index: number) => {
          Row() {
            Text(item.icon)
              .fontSize(24)
              .width(40)
              .textAlign(TextAlign.Center)
              .margin({ right: 12 })

            Column() {
              Text(item.title)
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(FontWeight.Medium)
                .width('100%')
                .margin({ bottom: 2 })
              Text(item.desc)
                .fontSize(12)
                .fontColor('#999999')
                .width('100%')
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Text('>')
              .fontSize(16)
              .fontColor('#CCCCCC')
          }
          .width('100%')
          .height(60)
          .padding({ left: 16, right: 16 })
          .alignItems(VerticalAlign.Center)
          .onClick(() => {
            // 处理点击事件
          })

          if (index < items.length - 1) {
            Divider()
              .color('#F0F0F0')
              .strokeWidth(0.5)
              .margin({ left: 68 })
          }
        })
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(12)
      .margin({ bottom: 20 })
    }
  }

  private getPersonalItems(): MenuItemType[] {
    return [
      { icon: '📝', title: '个人资料', desc: '修改个人信息' },
      { icon: '🔒', title: '账号安全', desc: '密码修改等' }
    ];
  }

  private getStudyItems(): MenuItemType[] {
    return [
      { icon: '⭐', title: '我的评价', desc: '课程和教师评价' },
      { icon: '📊', title: '学习统计', desc: '课程统计信息' },
      { icon: '📅', title: '课表管理', desc: '自定义课表' }
    ];
  }

  private getSystemItems(): MenuItemType[] {
    return [
      { icon: '📢', title: '系统通知', desc: '查看系统消息' },
      { icon: '❓', title: '帮助反馈', desc: '问题反馈和帮助' },
      { icon: 'ℹ️', title: '关于我们', desc: '应用信息' }
    ];
  }
}