import { relationalStore, ValuesBucket } from '@kit.ArkData';

export interface WishWallDBInfo extends ValuesBucket {
  id: string;
  userId: number;
  wishName: string;
  createdAt: number;
  effort: string;
}

class WishWallDB {
  private store: relationalStore.RdbStore | null = null
  private tableName = 'WishWall'
  private sqlCreate = `CREATE TABLE IF NOT EXISTS ${this.tableName} (
        id TEXT PRIMARY KEY,
        userId INTEGER NOT NULL,
        wishName TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        effort TEXT NOT NULL
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

  async insert(value: WishWallDBInfo) {
    const store = await this.getStoreInstance()
    return store.insert(this.tableName, value)
  }

  async queryByUserId(userId: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('userId', userId)
    predicates.orderByDesc('createdAt')
    const resultSet = store.querySync(predicates)
    const list: WishWallDBInfo[] = []
    while (resultSet.goToNextRow()) {
      const item = resultSet.getRow() as WishWallDBInfo
      list.push(item)
    }
    resultSet.close()
    return list
  }

  async update(value: WishWallDBInfo) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', value.id)
    predicates.equalTo('userId', value.userId)
    return store.update(value, predicates)
  }

  async delete(id: string, userId: number) {
    const store = await this.getStoreInstance()
    const predicates = new relationalStore.RdbPredicates(this.tableName)
    predicates.equalTo('id', id)
    predicates.equalTo('userId', userId)
    return store.delete(predicates)
  }
}

export const wishWallDB = new WishWallDB()

