import { McPieChart, Options } from '@mcui/mccharts'

/**
 * Author: 波波老师(weixin:javabobo0513)
 * Desc: 饼状图-案例页面
 */
@Entry
@Component
struct PieCharts {
  @State defOptions: Options = new Options({
    //调色盘颜色列表
    color: ['#FAAD14', '#3C73FF', '#52C41A', '#FF4D4F'],
    //设置图例的相关样式与功能
    legend: {
      top: '5%', //图例距离顶部侧位置
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
        center: ['50%', '30%'], // 饼图中心位置
        data: [
          { name: 'Java', value: 201 },
          { name: '鸿蒙', value: 638 },
          { name: 'Python', value: 256 },
          { name: '人工智能', value: 159 },
        ],
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

  build() {
    Column() {
      //饼状图组件
      McPieChart({ options: this.defOptions })
        .height('60%') //设置图表区域的高度
    }
    .height('100%')
    .width('100%')
  }
}