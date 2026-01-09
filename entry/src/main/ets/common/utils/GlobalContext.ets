// GlobalContext.ets
export class GlobalContext {
  private static instance: GlobalContext;
  private _objects = new Map<string, Object>();

  private constructor() {
  }

  public static getInstance(): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  setObject(key: string, obj: Object): void {
    this._objects.set(key, obj);
  }

  getObject(key: string): Object | undefined {
    return this._objects.get(key);
  }

  setUIContext(obj: Object) {
    this.setObject("UIContext", obj);
  }

  getUIContext(): UIContext {
    return this.getObject("UIContext") as UIContext;
  }
}