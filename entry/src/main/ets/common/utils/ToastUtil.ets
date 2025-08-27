// ToastUtil.ets
import { UIContext, window } from '@kit.ArkUI';

/**
 * Toast 工具类
 * 支持在组件外、Ability、任意工具类中调用
 */
export class ToastUtil {
  private static uiContext: UIContext | null = null;

  /**
   * 必须在 EntryAbility 的 onWindowStageCreate 中先初始化一次
   * 后续组件内弹窗无需再调用
   */
  public static init(windowStage: window.WindowStage) {
    windowStage.getMainWindow((err, win) => {
      if (!err && win) {
        ToastUtil.uiContext = win.getUIContext();
      }
    });
  }

  /**
   * 任何地方调用 showToast
   * @param msg  文本内容
   * @param duration 毫秒，默认 1500
   */
  public static showToast(msg: string, duration: number = 1500) {
    const ctx = ToastUtil.chooseContext();
    if (!ctx) {
      console.error('[ToastUtil] 无可用 UIContext，请先初始化');
      return;
    }
    ctx.getPromptAction().showToast({ message: msg, duration });
  }

  /* ---------------------------------------- 内部方法 ---------------------------------------- */

  /** 选择最合适的 UIContext：优先当前组件，其次缓存，兜底 undefined */
  private static chooseContext(): UIContext | undefined {
    // 2. 否则使用缓存
    return ToastUtil.uiContext ?? undefined;
  }
}