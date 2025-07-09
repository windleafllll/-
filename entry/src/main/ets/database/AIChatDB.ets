import { relationalStore, ValuesBucket } from "@kit.ArkData";

export interface AIChatDBInfo extends ValuesBucket {
  id: number | null
  spokesperson: string
  content: string
  date_added: number
}

class AIChatDB {
  private store: relationalStore.RdbStore | null = null
  private tableName = 'AIChat'
  private sqlCreate = `CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        spokesperson TEXT NOT NULL,
        content TEXT NOT NULL,
        date_added INTEGER NOT NULL
      )`

  async getStoreInstance() {
    // 如果数据库实例已存在，直接返回，没有才创建实例
    if (this.store) {
      return this.store
    }
    // 获取操作数据库的实例
    const store = await relationalStore.getRdbStore(getContext(), {
      name: 'PoChiTa.db', // 数据库名称
      securityLevel: relationalStore.SecurityLevel.S1 // 安全等级
    })
    // 存储起来方便下次直接获取
    this.store = store
    // 返回 store 实例
    return this.store
  }

  // 类的构造器，new 的时候会自动触发
  constructor() {
    // 创建/打开数据库文件
    this.getStoreInstance()
      .then(store => {
        // 执行创建语句，用于创建数据库的表
        store.executeSql(this.sqlCreate)
      })
  }

  //新增
  async insert(value: AIChatDBInfo) {
    const store = await this.getStoreInstance()
    return store.insert(this.tableName, value)
  }

  //查询
  async query() {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.orderByAsc('date_added')
    const resultSet = store.querySync(predicates)
    const list: AIChatDBInfo[] = []
    while (resultSet.goToNextRow()) {
      const item = resultSet.getRow() as AIChatDBInfo
      list.push(item)
    }
    resultSet.close()
    return list
  }

  //修改
  async update(value: AIChatDBInfo) {
    if (value.id) {
      const store = await this.getStoreInstance()
      const predicates = new relationalStore.RdbPredicates(this.tableName)
      predicates.equalTo('id', value.id)
      return store.update(value, predicates)
    }
    return
  }

  //删除
  async delete(id?: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    if (id) {
      predicates.equalTo('id', id)
    }
    return store.delete(predicates)
  }
}

// 通过小写 p 开头的类实例操作数据库，创建数据库，建表，增、删、查、改
export const aiChatDB = new AIChatDB()