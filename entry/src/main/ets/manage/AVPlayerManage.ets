import { media } from '@kit.MediaKit';

class AVPlayerManager {
  private avPlayer: media.AVPlayer | null = null
  private loop: boolean = false
  private isResetting: boolean = false

  async getAVPlayerInstance() {
    // 如果已存在，直接返回
    if (this.avPlayer !== null) {
      return this.avPlayer
    }
    // 初始化播放器
    const player = await media.createAVPlayer()
    player.on('stateChange', (state) => {
      console.info(`AVPlayer stateChange: ${state}`)
      switch (state) {
        case 'initialized':
          player.prepare()
          break;
        case 'prepared':
          player.play()
          break;
        case 'playing':
          player.play()
          break;
        case 'paused':
          player.pause()
          break;
        case 'completed':
          if (this.loop) {
            player.play() // 播放结束继续播放：循环播放
          } else {
            player.stop() // 播放结束
          }
          break;
        case 'stopped':
          // 正常 stop 时释放资源；如果是 playByRawSrc 内部 reset 过程，则避免触发二次 reset
          if (this.loop) {
            player.play()
          } else if (!this.isResetting) {
            player.reset()
          }
          break;
        default:
          break;
      }
    })
    this.avPlayer = player
    return this.avPlayer
  }

  // 加载 src/main/resources/rawfile 的文件
  async playByRawSrc(rawFdPath?: string) {
    if (rawFdPath) {
      const player = await this.getAVPlayerInstance()
      // 先释放原来的资源
      this.isResetting = true
      await player.reset()
      this.isResetting = false
      // 获取文件信息
      const context = getContext()
      // 加载 src/main/resources/rawfile 文件夹中的文件
      const fileDescriptor = await context.resourceManager.getRawFd(rawFdPath)
      // 设置播放路径
      player.fdSrc = fileDescriptor
      // 播放
      player.play()
    }else {
      const player = await this.getAVPlayerInstance()
      player.play()
    }
  }

  // 暂停播放
  async pause() {
    const player = await this.getAVPlayerInstance()
    player.pause()
  }

  // 停止播放
  async stop() {
    const player = await this.getAVPlayerInstance()
    this.loop = false
    player.stop()
  }

  async setLoop(isLoop: boolean) {
    this.loop = isLoop
  }
}


export const avPlayerManager = new AVPlayerManager()