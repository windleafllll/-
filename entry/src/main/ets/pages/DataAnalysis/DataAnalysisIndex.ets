import dayjs from 'dayjs'
import { planDB, PlanDBInfo } from '../../database/PlanDB'
import relativeTime from 'dayjs/plugin/relativeTime'
import { McBarChart, McLineChart, McPieChart, Options } from '@mcui/mccharts'

dayjs.extend(relativeTime)

interface pieChart {
  name: string,
  value: number
}

@Entry
@Component
struct DataAnalysisIndex {
  @State plan: PlanDBInfo[] = []
  @State timeStatistics: number = 0
  @State averageDailyDuration: number = 0
  @State i: string = ''
  @State totalTime: number = 0
  @State giveUp: number = 0
  @State todayPlan: number = 0
  @State todayTime: number = 0
  @State pieChartPlans: string[] = []
  @State pieChartPlan: string[] = []
  @State pieChart: pieChart[] = []
  @State barChart: number[] = [0, 0, 0, 0, 0, 0, 0]
  @State MonthlyLineChart: number[] = [0, 0, 0, 0, 0, 0]
  @State AnnualLineChart: number[] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

  async aboutToAppear() {
    this.plan = await planDB.query()
    this.doTimeStatistics()
    this.computeAverageDailyDuration()
    this.todayDoPlan()
    this.statisticalPlanning()
    this.defOptions1 = new Options({
      //调色盘颜色列表
      color: ['#FAAD14', '#3C73FF', '#52C41A', '#FF4D4F'],
      //设置图例的相关样式与功能
      legend: {
        top: '10%', //图例距离顶部侧位置
        itemWidth: 10, //图形的宽度
        itemHeight: 10, //图形的高度
        textStyle: {
          //文本样式配置
          color: '#ff00b4ff', //字体颜色
          fontSize: 30, //字体大小
          fontWeight: '800' //字体粗细
        }
      },
      series: [
        {
          // radius: ['45%', '30%'], // 饼图外半径、内半径
          center: ['50%', '50%'], // 饼图中心位置
          data: this.pieChart,
          labelLine: {
            //文本连接线样式配置
            length: 10, //连接线1的长度
            length2: 30, //连接线2的长度
            lineStyle: {
              //提示线样式
              width: 1, //线宽度
              color: '#ffff0000' //线颜色
            }
          },
          label: {
            //系列文本标签样式配置
            show: true, //是否显示文本标签
            fontWeight: '800', //字体粗细
            fontFamily: 'sans-serif',
            color: '#ffffffff', //字体颜色
            position: 'outside', //文本显示位置
            fontSize: 30, //字体大小
            distanceToLabelLine: 6 //字体与饼状间距
          },
        }
      ],
      tooltip: {
        //设置提示层的相关样式与功能
        axisPointer: {
          //指示器配置项
          type: 'line', //指示器类型
          lineStyle: {
            //提示线样式
            color: '#D9D9D9', //线颜色
            width: 2, //线宽度
            type: 'solid' //线类型
          }
        },
        backgroundColor: '#FFFFFF', //提示框背景颜色
        borderColor: '#C4C4C4', //提示框边框颜色
        borderWidth: 1, //提示框边框宽度
        padding: 6, //提示框内边距
        textStyle: {
          //文本样式配置
          color: '#666666', //字体颜色
          fontSize: 14 //字体大小
        }
      },
    })
    this.MonthlyTime()
    this.defOptions2 = new Options({
      legend: {
        //设置图例的相关样式与功能
        top: '5%', //图例距离顶部侧位置
        itemWidth: 10, //图形的宽度
        itemHeight: 10, //图形的高度
        textStyle: {
          //文本样式配置
          color: '#3C73FF', //字体颜色
          fontSize: 30, //字体大小
          fontWeight: '800' //字体粗细
        }
      },
      yAxis: {
        //设置y轴的相关样式与功能
        name: '时间（分钟）',
        axisTick: {
          //刻度线配置
          length: 6, //刻度的长度
          lineStyle: {
            //刻度线样式
            color: '#FFFFFF', //线颜色
            width: 1 //线宽度
          }
        },
        axisLine: {
          //y轴线配置
          show: true //隐藏y轴线
        },
        splitLine: {
          // Y轴分割线配置。
          show: true, //显示分割线
          lineStyle: {
            //轴线样式
            color: '#D9D9D9', //线颜色
            width: 1 //线宽度
          }
        },
        axisLabel: {
          //y轴文本标签样式配置
          color: '#999999', //字体颜色
          fontSize: 28, //字体大小
          fontWeight: '600' //字体粗细
        },
      },
      xAxis: {
        axisLabel: {
          //X轴文本标签样式配置
          color: '#999999', //字体颜色
          fontSize: 28, //字体大小
          fontWeight: '600' //字体粗线
        },
        axisTick: {
          //刻度线配置
          show: true, //控制刻度线显示与隐藏
          length: 6, // 刻度线的长度
          interval: 4, //刻度线与文本的间隔
          lineStyle: {
            //刻度线样式
            color: '#FFFFFF', //线颜色
            width: 1 //线宽度
          }
        },
        axisLine: {
          //x轴线配置
          show: true, //控制轴线显示与隐藏 可选值-true显示 false-隐藏
          lineStyle: {
            //轴线样式
            color: '#D9D9D9', //线颜色
            width: 1, //线宽度
            type: 'solid' //线类型
          }
        },
        //设置x轴的相关样式与功能
        data: ['凌晨', '早上', '上午', '中午', '下午', '傍晚', '晚上']
      },
      series: [//设置柱状区的相关样式与功能
        {
          label: {
            //系列文本标签样式配置
            show: true, //显示文本标签样
            color: '#FFFFFF', //字体颜色
            fontWeight: '600', //字体粗细
            fontFamily: 'sans-serif', //字体样式
            position: 'center', //文本显示位置
            fontSize: 22, //字体大小
            distanceToLabelLine: 5 //字体与柱状间距
          },
          name: "专注时间", //图例文字
          color: '#3C73FF', //图例颜色
          stack: '', //是否显示堆叠柱子
          barStyle: {
            //柱状样式配置
            width: 20, //柱子宽度
            color: '#3C73FF', //柱子颜色
            barGap: 1 //同系列之间的柱子间隙
          },
          data: this.barChart //数据
        },
      ],
      tooltip: {
        //设置提示层的相关样式与功能
        axisPointer: {
          //指示器配置项
          type: 'line', //指示器类型
          lineStyle: {
            //提示线样式
            color: '#D9D9D9', //线颜色
            width: 2, //线宽度
            type: 'solid' //线类型
          }
        },
        backgroundColor: '#FFFFFF', //提示框背景颜色
        borderColor: '#C4C4C4', //提示框边框颜色
        borderWidth: 1, //提示框边框宽度
        padding: 6, //提示框内边距
        textStyle: {
          //文本样式配置
          color: '#666666', //字体颜色
          fontSize: 14 //字体大小
        }
      },
    })
    this.MonthlyData()
    this.defOptions3 = new Options({
      //设置图例的相关样式与功能
      legend: {
        top: '10%', //图例距离顶部侧位置
        itemWidth: 10, //图形的宽度
        itemHeight: 10, //图形的高度
        textStyle: {
          //文本样式配置
          color: '#ff000000', //字体颜色
          fontSize: 40, //字体大小
          fontWeight: '500' //字体粗细
        }
      },
      //设置X轴的相关样式与功能
      xAxis: {
        axisLabel: {
          color: '#ff838383', //X轴字体颜色
          fontSize: 28, //X轴字体大小
          fontWeight: '600' //X轴字体粗线
        },
        axisTick: {
          //刻度线配置
          show: true, //控制刻度线显示与隐藏
          length: 6, // 刻度线的长度
          interval: 4, //刻度线与文本的间隔
          lineStyle: {
            color: '#ff838383', //X轴刻度线颜色
            width: 1 //X轴线刻度线宽度
          }
        },
        axisLine: {
          //x轴线配置
          show: true, //控制轴线显示与隐藏 可选值-true显示 false-隐藏
          lineStyle: {
            color: '#ff838383', //X轴线条颜色
            width: 1, //X轴线宽度
            type: 'solid' //X轴线类型
          }
        },
        data: ['1~5号', '6~10号', '11~15号', '16~20号', '21~25号', '26~31号']
      },
      //设置Y轴的相关样式与功能
      yAxis: {
        name: '时间（分钟）',
        axisTick: {
          //刻度线配置
          length: 6, //刻度的长度
          lineStyle: {
            //刻度线样式
            color: '#ff838383', //线颜色
            width: 1 //线宽度
          }
        },
        axisLine: {
          //y轴线配置
          show: true //隐藏y轴线
        },
        splitLine: {
          // Y轴分割线配置。
          show: true, //显示分割线
          lineStyle: {
            //轴线样式
            color: '#ffe5e5e5', //线颜色
            width: 1 //线宽度
          }
        },
        axisLabel: {
          //y轴文本标签样式配置
          color: '#ff838383', //字体颜色
          fontSize: 35, //字体大小
          fontWeight: '500' //字体粗细
        },
      },
      //设置折线区的相关样式与功能
      series: [
        {
          name: "专注时间", //图例文字
          color: '#ffff0002', //图例颜色
          lineStyle: {
            //折线样式配置
            width: 2, //折线宽度
            color: '#ffff0002' //折线显色
          },
          itemStyle: {
            //折线拐点配置
            symbol: 'solidCircle', //拐点类型
            symbolSize: 4 //拐点大小
          },
          data: this.MonthlyLineChart //数据
        }
      ],
      tooltip: {
        //设置提示层的相关样式与功能
        axisPointer: {
          //指示器配置项
          type: 'line', //指示器类型
          lineStyle: {
            //提示线样式
            color: '#D9D9D9', //线颜色
            width: 2, //线宽度
            type: 'solid' //线类型
          }
        },
        backgroundColor: '#FFFFFF', //提示框背景颜色
        borderColor: '#C4C4C4', //提示框边框颜色
        borderWidth: 1, //提示框边框宽度
        padding: 6, //提示框内边距
        textStyle: {
          //文本样式配置
          color: '#666666', //字体颜色
          fontSize: 14 //字体大小
        }
      },
    })
    this.AnnualData()
    this.defOptions4 = new Options({
      //设置图例的相关样式与功能
      legend: {
        top: '10%', //图例距离顶部侧位置
        itemWidth: 10, //图形的宽度
        itemHeight: 10, //图形的高度
        textStyle: {
          //文本样式配置
          color: '#ff000000', //字体颜色
          fontSize: 40, //字体大小
          fontWeight: '500' //字体粗细
        }
      },
      //设置X轴的相关样式与功能
      xAxis: {
        axisLabel: {
          color: '#ff838383', //X轴字体颜色
          fontSize: 28, //X轴字体大小
          fontWeight: '600' //X轴字体粗线
        },
        axisTick: {
          //刻度线配置
          show: true, //控制刻度线显示与隐藏
          length: 6, // 刻度线的长度
          interval: 4, //刻度线与文本的间隔
          lineStyle: {
            color: '#ff838383', //X轴刻度线颜色
            width: 1 //X轴线刻度线宽度
          }
        },
        axisLine: {
          //x轴线配置
          show: true, //控制轴线显示与隐藏 可选值-true显示 false-隐藏
          lineStyle: {
            color: '#ff838383', //X轴线条颜色
            width: 1, //X轴线宽度
            type: 'solid' //X轴线类型
          }
        },
        data: ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']
      },
      //设置Y轴的相关样式与功能
      yAxis: {
        name: '时间（分钟）',
        axisTick: {
          //刻度线配置
          length: 6, //刻度的长度
          lineStyle: {
            //刻度线样式
            color: '#ff838383', //线颜色
            width: 1 //线宽度
          }
        },
        axisLine: {
          //y轴线配置
          show: true //隐藏y轴线
        },
        splitLine: {
          // Y轴分割线配置。
          show: true, //显示分割线
          lineStyle: {
            //轴线样式
            color: '#ffe5e5e5', //线颜色
            width: 1 //线宽度
          }
        },
        axisLabel: {
          //y轴文本标签样式配置
          color: '#ff838383', //字体颜色
          fontSize: 35, //字体大小
          fontWeight: '500' //字体粗细
        },
      },
      //设置折线区的相关样式与功能
      series: [
        {
          name: "专注时间", //图例文字
          color: '#ffff0002', //图例颜色
          lineStyle: {
            //折线样式配置
            width: 2, //折线宽度
            color: '#ffff0002' //折线显色
          },
          itemStyle: {
            //折线拐点配置
            symbol: 'solidCircle', //拐点类型
            symbolSize: 4 //拐点大小
          },
          data: this.AnnualLineChart //数据
        }
      ],
      tooltip: {
        //设置提示层的相关样式与功能
        axisPointer: {
          //指示器配置项
          type: 'line', //指示器类型
          lineStyle: {
            //提示线样式
            color: '#D9D9D9', //线颜色
            width: 2, //线宽度
            type: 'solid' //线类型
          }
        },
        backgroundColor: '#FFFFFF', //提示框背景颜色
        borderColor: '#C4C4C4', //提示框边框颜色
        borderWidth: 1, //提示框边框宽度
        padding: 6, //提示框内边距
        textStyle: {
          //文本样式配置
          color: '#666666', //字体颜色
          fontSize: 14 //字体大小
        }
      },
    })
  }

  doTimeStatistics() {
    this.plan.forEach((v: PlanDBInfo) => {
      this.timeStatistics = Number((this.timeStatistics + Number(((v.times) / 60).toFixed(2))).toFixed(2))
    })
  }

  computeAverageDailyDuration() {
    this.i = dayjs(this.plan[0].date_added).fromNow(true)
    const c = this.i.slice(undefined, -1)
    if (this.i.includes('天')) {
      this.totalTime = Number(c)
    } else if (this.i.includes('月')) {
      this.totalTime = Number(c) * 31
    } else if (this.i.includes('年')) {
      this.totalTime = Number(c) * 365
    } else {
      this.totalTime = 1
    }
    this.averageDailyDuration = Number((this.timeStatistics / this.totalTime).toFixed(2))
  }

  todayDoPlan() {
    const today = dayjs(Date.now()).format('YYYY-MM-DD')
    this.plan.forEach((v: PlanDBInfo) => {
      const eachDay = dayjs(v.date_added).format('YYYY-MM-DD')
      if (eachDay == today) {
        this.todayPlan = this.todayPlan + 1
        this.todayTime = Number((this.todayTime + Number(((v.times) / 60).toFixed(2))).toFixed(2))
        if (v.is_accomplish != true) {
          this.giveUp = this.giveUp + 1
        }
      }
    })
  }

  statisticalPlanning() {
    this.plan.forEach((v: PlanDBInfo) => {
      this.pieChartPlans.push(v.title)
      if (!this.pieChartPlan.includes(v.title)) {
        this.pieChartPlan.push(v.title)
      }
    })
    for (let i = this.pieChartPlan.length - 1; i >= 0; i--) {
      const a = this.pieChartPlans.filter(v => v == this.pieChartPlan[i])
      this.pieChart.push({ name: this.pieChartPlan[i], value: a.length })
    }
  }

  MonthlyTime() {
    const a = dayjs(Date.now()).format('MM')
    this.plan.forEach((v: PlanDBInfo) => {
      if (dayjs(v.date_added).format('YYYY') == dayjs(Date.now()).format('YYYY')) {
        if (dayjs(v.date_added).format('MM') == a) {
          const b = Number(dayjs(v.date_added).format('HH'))
          if (b >= 0 && b < 5) {
            this.barChart[0] = this.barChart[0] + 1
          } else if (b >= 5 && b < 8) {
            this.barChart[1] = this.barChart[1] + 1
          } else if (b >= 8 && b < 11) {
            this.barChart[2] = this.barChart[2] + 1
          } else if (b >= 11 && b < 13) {
            this.barChart[3] = this.barChart[3] + 1
          } else if (b >= 13 && b < 17) {
            this.barChart[4] = this.barChart[4] + 1
          } else if (b >= 17 && b < 19) {
            this.barChart[5] = this.barChart[5] + 1
          } else if (b >= 19 && b <= 23) {
            this.barChart[6] = this.barChart[6] + 1
          }
        }
      }
    })
  }

  MonthlyData() {
    this.plan.forEach((v: PlanDBInfo) => {
      if (dayjs(v.date_added).format('YYYY') == dayjs(Date.now()).format('YYYY')) {
        if (dayjs(v.date_added).format('MM') == dayjs(Date.now()).format('MM')) {
          const a = Number(dayjs(v.date_added).format('DD'))
          if (a >= 1 && a < 6) {
            this.MonthlyLineChart[0] = this.MonthlyLineChart[0] + 1
          } else if (a >= 6 && a < 10) {
            this.MonthlyLineChart[1] = this.MonthlyLineChart[1] + 1
          } else if (a >= 10 && a < 16) {
            this.MonthlyLineChart[2] = this.MonthlyLineChart[2] + 1
          } else if (a >= 16 && a < 21) {
            this.MonthlyLineChart[3] = this.MonthlyLineChart[3] + 1
          } else if (a >= 21 && a < 26) {
            this.MonthlyLineChart[4] = this.MonthlyLineChart[4] + 1
          } else if (a >= 26 && a <= 31) {
            this.MonthlyLineChart[5] = this.MonthlyLineChart[5] + 1
          }
        }
      }
    })
  }

  AnnualData() {
    this.plan.forEach((v: PlanDBInfo) => {
      if (dayjs(v.date_added).format('YYYY') == dayjs(Date.now()).format('YYYY')) {
        const a = dayjs(v.date_added).format('MM')
        switch (a) {
          case '01':
            this.AnnualLineChart[0] = this.AnnualLineChart[0] + 1
            break;
          case '02':
            this.AnnualLineChart[1] = this.AnnualLineChart[1] + 1
            break;
          case '03':
            this.AnnualLineChart[2] = this.AnnualLineChart[2] + 1
            break;
          case '04':
            this.AnnualLineChart[3] = this.AnnualLineChart[3] + 1
            break;
          case '05':
            this.AnnualLineChart[4] = this.AnnualLineChart[4] + 1
            break;
          case '06':
            this.AnnualLineChart[5] = this.AnnualLineChart[5] + 1
            break;
          case '07':
            this.AnnualLineChart[6] = this.AnnualLineChart[6] + 1
            break;
          case '08':
            this.AnnualLineChart[7] = this.AnnualLineChart[7] + 1
            break;
          case '09':
            this.AnnualLineChart[8] = this.AnnualLineChart[8] + 1
            break;
          case '10':
            this.AnnualLineChart[9] = this.AnnualLineChart[9] + 1
            break;
          case '11':
            this.AnnualLineChart[10] = this.AnnualLineChart[10] + 1
            break;
          case '12':
            this.AnnualLineChart[11] = this.AnnualLineChart[11] + 1
            break;
        }
      }
    })
  }

  @State defOptions1: Options | null = null
  @State defOptions2: Options | null = null
  @State defOptions3: Options | null = null
  @State defOptions4: Options | null = null

  build() {
    Scroll() {
      Column({ space: 20 }) {
        Column({ space: 10 }) {
          Text('累计专注')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
          Row() {
            Column({ space: 10 }) {
              Text('次数')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
              Text(this.plan.length.toString())
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
            }

            Column({ space: 10 }) {
              Text('时长')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
              Row() {
                Text(this.timeStatistics.toString())
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                Text('分钟')
                  .fontSize(7)
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(VerticalAlign.Bottom)
            }

            Column({ space: 10 }) {
              Text('日均时长')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
              Row() {
                Text(this.averageDailyDuration.toString())
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                Text('分钟')
                  .fontSize(7)
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(VerticalAlign.Bottom)
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
        }
        .padding(10)
        .borderRadius(10)
        .backgroundColor(Color.White)
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 10 }) {
          Text('今日专注')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
          Row() {
            Column({ space: 10 }) {
              Text('次数')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
              Text(this.todayPlan.toString())
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
            }

            Column({ space: 10 }) {
              Text('时长')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
              Row() {
                Text(this.todayTime.toString())
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                Text('分钟')
                  .fontSize(7)
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(VerticalAlign.Bottom)
            }

            Column({ space: 10 }) {
              Text('放弃次数')
                .fontSize(11)
                .fontWeight(FontWeight.Bold)
              Row() {
                Text(this.giveUp.toString())
                  .fontSize(11)
                  .fontWeight(FontWeight.Bold)
                Text('次')
                  .fontSize(7)
                  .fontWeight(FontWeight.Medium)
              }
              .alignItems(VerticalAlign.Bottom)
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
        }
        .padding(10)
        .borderRadius(10)
        .backgroundColor(Color.White)
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        Column({ space: 10 }) {
          Row() {
            Text('专注次数分布：')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
          }
          .justifyContent(FlexAlign.Start)
          .width('100%')

          if (this.defOptions1 != null) {
            McPieChart({ options: this.defOptions1 })
              .height('25%') //设置图表区域的高度
          }
        }
        .padding(10)
        .borderRadius(10)
        .backgroundColor(Color.White)
        .width('100%')

        Column({ space: 10 }) {
          Row() {
            Text('本月专注时段分布：')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
          }
          .justifyContent(FlexAlign.Start)
          .width('100%')

          if (this.defOptions2 != null) {
            McBarChart({ options: this.defOptions2 })
              .height('30%') //设置图表区域的高度
          }
        }
        .padding(10)
        .borderRadius(10)
        .backgroundColor(Color.White)
        .width('100%')

        Column({ space: 10 }) {
          Row() {
            Text('月度数据：')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
            Text(dayjs(Date.now()).format('YYYY年MM月'))
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
          }
          .justifyContent(FlexAlign.Start)
          .width('100%')

          if (this.defOptions3 != null) {
            McLineChart({ options: this.defOptions3 })
              .height('30%') //设置图表区域的高度
          }
        }
        .padding(10)
        .borderRadius(10)
        .backgroundColor(Color.White)
        .width('100%')

        Column({ space: 10 }) {
          Row() {
            Text('年度数据：')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
            Text(dayjs(Date.now()).format('YYYY年'))
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
          }
          .justifyContent(FlexAlign.Start)
          .width('100%')

          if (this.defOptions4 != null) {
            McLineChart({ options: this.defOptions4 })
              .height('30%') //设置图表区域的高度
          }
        }
        .padding(10)
        .borderRadius(10)
        .backgroundColor(Color.White)
        .width('100%')
      }
      .padding(15)
    }
    .backgroundColor('#fff1f1f1')
  }
}