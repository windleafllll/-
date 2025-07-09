import { McBarChart, McPieChart, Options } from '@mcui/mccharts'

/**
 * Author: 波波老师(weixin:javabobo0513)
 * Desc: 单柱状图-案例页面
 */
@Entry
@Component
struct SingleBarCharts {
  @State defOptions: Options = new Options({
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
      name: '人民币(万元)',
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
      data: ['周一', '周二', '周三', '周四', '周五', '周六', '周日']
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
        name: "每周收入", //图例文字
        color: '#3C73FF', //图例颜色
        stack: '', //是否显示堆叠柱子
        barStyle: {
          //柱状样式配置
          width: 14, //柱子宽度
          color: '#3C73FF', //柱子颜色
          barGap: 1 //同系列之间的柱子间隙
        },
        data: [60, 50, 42, 75, 40, 60, 35] //数据
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

  build() {
    Column() {
      //柱状图组件
      Column() {
        McBarChart({ options: this.defOptions })
          .height('60%') //设置图表区域的高度
      }
    }
    .height('100%')
    .width('100%')
  }
}