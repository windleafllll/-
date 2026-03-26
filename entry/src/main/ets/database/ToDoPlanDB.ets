import { relationalStore, ValuesBucket } from "@kit.ArkData";

export interface ToDoPlanDBInfo extends ValuesBucket {
  id: number | null
  title: string
  event: string
  time: string | null
  timess: number | null
  timesss: string | null
  type: string
  times: number | null
  date_added: number
  // 计划展示顺序（越小越靠前）
  sort_order: number | null
}

class ToDoPlanDB {
  private store: relationalStore.RdbStore | null = null
  private tableName = 'ToDoPlan'
  private sqlCreate = `CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        event TEXT NOT NULL,
        time TEXT,
        timess INTEGER,
        timesss TEXT,
        type TEXT NOT NULL,
        times INTEGER,
        date_added INTEGER NOT NULL,
        sort_order INTEGER
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
        // 兼容旧版本：补齐排序字段
        store.executeSql(`ALTER TABLE ${this.tableName} ADD COLUMN sort_order INTEGER`)
          .catch(() => {
          })
      })
  }

  //新增
  async insert(value: ToDoPlanDBInfo) {
    const store = await this.getStoreInstance()
    if (value.sort_order == null) {
      value.sort_order = Date.now()
    }
    return store.insert(this.tableName, value)
  }

  //查询
  async query(id?: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    if (id != undefined) {
      predicates.equalTo('id', id)
    } else {
      // 默认按用户自定义顺序展示，未设置时再按创建时间兜底
      predicates.orderByAsc('sort_order')
      predicates.orderByDesc('date_added')
    }
    const resultSet = store.querySync(predicates)
    const list: ToDoPlanDBInfo[] = []
    while (resultSet.goToNextRow()) {
      const item = resultSet.getRow() as ToDoPlanDBInfo
      list.push(item)
    }
    resultSet.close()
    return list
  }

  //修改
  async update(value: ToDoPlanDBInfo) {
    if (value.id) {
      const store = await this.getStoreInstance()
      const predicates = new relationalStore.RdbPredicates(this.tableName)
      predicates.equalTo('id', value.id)
      // 编辑计划时，若未显式传入排序值，不覆盖原有 sort_order
      const vb: ValuesBucket = {
        id: value.id,
        title: value.title,
        event: value.event,
        time: value.time,
        timess: value.timess,
        timesss: value.timesss,
        type: value.type,
        times: value.times,
        date_added: value.date_added
      }
      if (value.sort_order != null) {
        vb.sort_order = value.sort_order
      }
      return store.update(vb, predicates)
    }
    return
  }

  //删除
  async delete(id: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', id)
    return store.delete(predicates)
  }

  async updateSortOrder(id: number, sortOrder: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', id)
    const vb: ValuesBucket = { sort_order: sortOrder }
    return store.update(vb, predicates)
  }

  async updateSortOrders(orderedIds: number[]) {
    for (let i = 0; i < orderedIds.length; i++) {
      await this.updateSortOrder(orderedIds[i], i)
    }
  }
}

// 通过小写 p 开头的类实例操作数据库，创建数据库，建表，增、删、查、改
export const toDoPlanDB = new ToDoPlanDB()