import { http } from "@kit.NetworkKit";
import { util } from "@kit.ArkTS";

interface ContentData {
  antiFlag: number;
  isIntervene: boolean;
  showType: string;
  text: string;
  type: string;
}

interface ContentItem {
  dataType?: string;
  isFinished: boolean;
  data: ContentData | null;
}

interface MessageData {
  content: ContentItem[];
  threadId: string;
  endTurn: boolean;
  msgId: string;
}

interface ResponseData {
  message: MessageData;
  qid: string;
}

interface MessageResponse {
  status: number;
  message: string;
  logid: string;
  data: ResponseData | null;
}

// 解析 SSE `data:` 后面的 JSON（只保留我们实际需要的字段）
interface StreamParsedText {
  text?: string;
}

interface StreamParsedContent {
  data?: StreamParsedText;
}

interface StreamParsedMessage {
  content?: StreamParsedContent[];
}

interface StreamParsedData {
  message?: StreamParsedMessage;
}

interface StreamParsedResp {
  status?: number;
  data?: StreamParsedData | null;
}

export async function i(userChat: string, callback: (chunk: string) => void,
  callback1: (isOver: boolean) => void,
  callback2: () => void) {
  let httpRequest = http.createHttp();
  const decoder = util.TextDecoder.create('utf-8');
  // 用于拼接流式返回的残片，直到出现完整行（尤其是 `data:` 后面的 JSON）。
  let streamBuffer: string = '';

  httpRequest.on('headersReceive', (header) => {
    console.info('header: ' + JSON.stringify(header));
  });

  httpRequest.on('dataReceive', (data: ArrayBuffer) => {
    let stringData = decoder.decodeToString(new Uint8Array(data));
    streamBuffer += stringData;
    // 统一换行，方便按行解析 SSE
    streamBuffer = streamBuffer.replace(/\r/g, '');

    // 按行解析；最后一行可能是残片，保留到下一次 dataReceive
    const lines: string[] = streamBuffer.split('\n');
    streamBuffer = lines.pop() ?? '';

    for (let idx = 0; idx < lines.length; idx++) {
      const line = lines[idx].trim();
      if (!line) {
        continue;
      }
      if (!line.startsWith('data:')) {
        continue; // event:ping / event:message 之类忽略
      }

      const payload = line.substring('data:'.length).trim();
      if (!payload) {
        continue;
      }

      // payload 可能会在分包中不完整；如果不像完整 JSON 就先不解析。
      if (!(payload.endsWith('}') || payload === 'null')) {
        // 把当前残片放回 buffer，等待下一次补全
        streamBuffer = line + '\n' + streamBuffer;
        break;
      }

      try {
        const resp = JSON.parse(payload) as StreamParsedResp;

        if (resp?.status === 499) {
          callback2();
          continue;
        }

        // resp.data.message.content[].data.text 对应你日志里 message.content 的分片文本
        const content = resp?.data?.message?.content;
        if (Array.isArray(content)) {
          content.forEach((it) => {
            const text = it?.data?.text;
            if (typeof text === 'string' && text.length > 0) {
              callback(text);
            }
          });
        }
      } catch (e) {
        // 解析失败一般是分包导致 payload 不完整；保守忽略
        console.error('parse data payload failed');
      }
    }
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
      },
      expectDataType: http.HttpDataType.OBJECT
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


