import { relationalStore, ValuesBucket } from '@kit.ArkData'

export interface FurtherTimeDBInfo extends ValuesBucket {
  id: number | null
  title: string
  targetTime: number
  createdAt: number
}

class FurtherTimeDB {
  private store: relationalStore.RdbStore | null = null
  private tableName = 'FurtherTime'
  private sqlCreate = `CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        targetTime INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )`

  async getStoreInstance() {
    if (this.store) {
      return this.store
    }
    const store = await relationalStore.getRdbStore(getContext(), {
      name: 'PoChiTa.db',
      securityLevel: relationalStore.SecurityLevel.S1
    })
    this.store = store
    return this.store
  }

  constructor() {
    this.getStoreInstance().then(store => {
      store.executeSql(this.sqlCreate)
    })
  }

  async insert(value: FurtherTimeDBInfo) {
    const store = await this.getStoreInstance()
    return store.insert(this.tableName, value)
  }

  async query(id?: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    if (id != undefined) {
      predicates.equalTo('id', id)
    } else {
      predicates.orderByAsc('targetTime')
      predicates.orderByDesc('createdAt')
    }
    const resultSet = store.querySync(predicates)
    const list: FurtherTimeDBInfo[] = []
    while (resultSet.goToNextRow()) {
      const item = resultSet.getRow() as FurtherTimeDBInfo
      list.push(item)
    }
    resultSet.close()
    return list
  }

  async update(value: FurtherTimeDBInfo) {
    if (value.id == null) {
      return
    }
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', value.id)
    return store.update(value, predicates)
  }

  async delete(id: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', id)
    return store.delete(predicates)
  }
}

export const furtherTimeDB = new FurtherTimeDB()

