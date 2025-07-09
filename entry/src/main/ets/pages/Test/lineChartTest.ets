import { McLineChart, Options } from '@mcui/mccharts'

@Entry
@Component
struct lineCharts {
  @State defOptions: Options = new Options({
    //设置图例的相关样式与功能
    legend: {
      top: '5%', //图例距离顶部侧位置
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
      data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
    },
    //设置Y轴的相关样式与功能
    yAxis: {
      name: '温度',
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
        name: "周最高气温", //图例文字
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
        data: [11, 5, 9, 13, 12, 12, 5] //数据
      },
      {
        name: "周最低气温", //图例文字
        color: '#52C41A', //图例颜色
        lineStyle: {
          width: 2, //折线宽度
          color: '#52C41A' //折线显色
        },
        itemStyle: {
          //折线拐点配置
          symbol: 'solidCircle', //拐点类型
          symbolSize: 4 //拐点大小
        },
        data: [3, 0, 3, 5, 4, 2, 2] //数据
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

  build() {
    Column() {
      //折线图组件
      McLineChart({ options: this.defOptions })
        .height('60%') //设置图表区域的高度
    }
    .height('100%')
    .width('100%')
  }
}