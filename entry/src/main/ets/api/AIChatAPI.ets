import { http } from "@kit.NetworkKit";
import { util } from "@kit.ArkTS";

export async function i(userChat: string, callback: (chunk: string) => void,
  callback1: (isOver: boolean) => void,
  callback2: () => void) {
  let httpRequest = http.createHttp();

  httpRequest.on('headersReceive', (header) => {
    console.info('header: ' + JSON.stringify(header));
  });

  httpRequest.on('dataReceive', (data: ArrayBuffer) => {
    let decoder = util.TextDecoder.create('utf-8');
    let stringData = decoder.decodeToString(new Uint8Array(data));
    let a: string = JSON.stringify(stringData) as string
    // let a_json: object = JSON.parse(a)
    // let d: JSON = a_json?.['data']
    console.log('想询问状态' + a)
    let b: string[] = a.split(',')
    b.forEach((i: string) => {
      if (i.includes('text')) {
        let c: string[] = i.split(':')
        let d: string = c[1].substring(2, c[1].length - 2)
        let e = d.replace(/\\\*\*|\*\*\\|\n/g, '');
        let f = e.replace(/\\\\n\*|\\\\n|\*\*|\\n/g, '');
        callback(f)
      }
    })
  });

  httpRequest.on('dataEnd', () => {
    callback1(true)
    console.info('No more data in response, data receive end 11111111');
  });

  httpRequest.requestInStream("https://agentapi.baidu.com/assistant/conversation?appId=rAzdRJeJ7ea6wq9LLDxVrFRlm2218D2c&secretKey=F6y825oZyzhgpTkEc2EK6zyeSpPZ1oHw",
    {
      method: http.RequestMethod.POST,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: {
        message: {
          content: {
            type: 'text',
            value: {
              showText: userChat
            },
            isFirstConversation: false
          }
        },
        source: 'rAzdRJeJ7ea6wq9LLDxVrFRlm2218D2c',
        from: 'openapi',
        openId: '616161'
      }
    }).then((data) => {
    console.info('服务器返回值：' + data);
    if (data == 499) {
      callback2()
    }
    console.info("requestInStream OK! 11111111");
    httpRequest.off('headersReceive');
    httpRequest.off('dataReceive');
    httpRequest.off('dataEnd');
    httpRequest.destroy();
  })
}


