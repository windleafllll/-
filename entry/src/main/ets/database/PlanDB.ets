import { relationalStore } from "@kit.ArkData";

/** getRow() 的 ValuesBucket 含 Asset 等 ValueType，需宽于本表实际列类型 */
type PlanDbRow = Record<string, string | number | boolean | bigint | null | Uint8Array | undefined | object>

/** 仅含本表可写入字段，与 RdbStore.insert/update 兼容 */
type PlanDbInsertBucket = Record<string, string | number | boolean | null>

/** 业务字段；插入/更新时转为 Record，避免 todo_plan_id 与 ValuesBucket 索引签名冲突 */
export interface PlanDBInfo {
  id: number | null
  title: string
  times: number
  is_accomplish: boolean
  date_added: number
  /** 对应 ToDoPlan.id；旧数据为 null，仅按标题关联 */
  todo_plan_id?: number | null
}

class PlanDB {
  private planInfoToBucket(p: PlanDBInfo): PlanDbInsertBucket {
    const todo: number | null = p.todo_plan_id === undefined ? null : p.todo_plan_id
    const out: PlanDbInsertBucket = {}
    out['id'] = p.id
    out['title'] = p.title
    out['times'] = p.times
    out['is_accomplish'] = p.is_accomplish
    out['date_added'] = p.date_added
    out['todo_plan_id'] = todo
    return out
  }

  private bucketToPlanInfo(row: PlanDbRow): PlanDBInfo {
    const idRaw = row['id']
    const id: number | null =
      idRaw === null || idRaw === undefined ? null : (typeof idRaw === 'number' ? idRaw : null)

    const titleRaw = row['title']
    const title: string = typeof titleRaw === 'string' ? titleRaw : ''

    const timesRaw = row['times']
    const times: number = typeof timesRaw === 'number' ? timesRaw : 0

    const accRaw = row['is_accomplish']
    const is_accomplish: boolean = accRaw === true || accRaw === 1

    const dateRaw = row['date_added']
    const date_added: number = typeof dateRaw === 'number' ? dateRaw : 0

    const todoRaw = row['todo_plan_id']
    let todo_plan_id: number | null | undefined
    if (todoRaw === undefined || todoRaw === null) {
      todo_plan_id = null
    } else if (typeof todoRaw === 'number') {
      todo_plan_id = todoRaw
    } else {
      todo_plan_id = null
    }

    const result: PlanDBInfo = {
      id: id,
      title: title,
      times: times,
      is_accomplish: is_accomplish,
      date_added: date_added,
      todo_plan_id: todo_plan_id
    }
    return result
  }

  private store: relationalStore.RdbStore | null = null
  private tableName = 'Plan'
  private sqlCreate = `CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        times INTEGER NOT NULL,
        is_accomplish BOOLEADN NOT NULL,
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
        store.executeSql(`ALTER TABLE ${this.tableName} ADD COLUMN todo_plan_id INTEGER`)
          .catch(() => {
          })
      })
  }

  //新增
  async insert(value: PlanDBInfo) {
    const store = await this.getStoreInstance()
    return store.insert(this.tableName, this.planInfoToBucket(value))
  }

  //查询
  async query(id?: number, is_accomplish?: boolean) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    if (id) {
      predicates.equalTo('id', id)
    } else if (is_accomplish) {
      predicates.equalTo('is_accomplish', is_accomplish)
    } else {
      predicates.orderByDesc('date_added')
    }
    const resultSet = store.querySync(predicates)
    const list: PlanDBInfo[] = []
    while (resultSet.goToNextRow()) {
      list.push(this.bucketToPlanInfo(resultSet.getRow()))
    }
    resultSet.close()
    return list
  }

  /**
   * 按「计划模板 id」取执行记录，避免同名计划统计混在一起。
   * allowLegacyTitleMatch：为 true 时额外并入 todo_plan_id 为空且 title 相同的旧数据（仅当业务侧确认同名养习惯/定目标不超过 1 个时使用）。
   */
  async queryRecordsForPlan(
    todoPlanId: number,
    title: string,
    allowLegacyTitleMatch: boolean,
    startTime: number,
    endTime: number
  ): Promise<PlanDBInfo[]> {
    const store = await this.getStoreInstance()
    const byId: PlanDBInfo[] = []
    const pId = new relationalStore.RdbPredicates(this.tableName)
    pId.equalTo('todo_plan_id', todoPlanId)
    pId.greaterThanOrEqualTo('date_added', startTime)
    pId.lessThanOrEqualTo('date_added', endTime)
    pId.orderByAsc('date_added')
    const rsId = store.querySync(pId)
    while (rsId.goToNextRow()) {
      byId.push(this.bucketToPlanInfo(rsId.getRow()))
    }
    rsId.close()
    if (!allowLegacyTitleMatch) {
      return byId
    }
    const legacy: PlanDBInfo[] = []
    const pTitle = new relationalStore.RdbPredicates(this.tableName)
    pTitle.equalTo('title', title)
    pTitle.greaterThanOrEqualTo('date_added', startTime)
    pTitle.lessThanOrEqualTo('date_added', endTime)
    pTitle.orderByAsc('date_added')
    const rsTitle = store.querySync(pTitle)
    while (rsTitle.goToNextRow()) {
      const row = this.bucketToPlanInfo(rsTitle.getRow())
      if (row.todo_plan_id == null) {
        legacy.push(row)
      }
    }
    rsTitle.close()
    const merged: PlanDBInfo[] = []
    for (let i = 0; i < byId.length; i++) {
      merged.push(byId[i])
    }
    for (let i = 0; i < legacy.length; i++) {
      merged.push(legacy[i])
    }
    merged.sort((x, y) => x.date_added - y.date_added)
    return merged
  }

  //修改
  async update(value: PlanDBInfo) {
    if (value.id) {
      const store = await this.getStoreInstance()
      const predicates = new relationalStore.RdbPredicates(this.tableName)
      predicates.equalTo('id', value.id)
      return store.update(this.planInfoToBucket(value), predicates)
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
}

// 通过小写 p 开头的类实例操作数据库，创建数据库，建表，增、删、查、改
export const planDB = new PlanDB()