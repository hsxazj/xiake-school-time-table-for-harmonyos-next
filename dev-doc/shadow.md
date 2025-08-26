在 ArkTS（ArkUI）中，**shadow** 是通用属性，可用于绝大多数 **基础组件** 和 **容器组件**，用来给组件绘制 **投影（阴影）**。  
可一次性设置所有字段，也可用链式写法单独指定某一项。

---

### 📌 1. 语法总览

```ts
.shadow({
  radius: 长度,           // 模糊半径
  color?: 颜色,          // 阴影颜色
  offsetX?: 长度,        // 水平偏移
  offsetY?: 长度,        // 垂直偏移
  fill?: boolean,        // 是否填充（仅特定组件）
  path?: string          // 自定义轮廓路径（高级）
})
```

---

### 🎯 2. 最常用 4 个字段

| 字段 | 类型 | 说明 |
|---|---|---|
| **radius** | `number \| Length` | **必传**，模糊半径，越大越虚 |
| **color** | `Color` | 默认 20% 黑 |
| **offsetX** | `number \| Length` | 水平偏移，正右负左 |
| **offsetY** | `number \| Length` | 垂直偏移，正下负上 |

---

### 🧩 3. 快速示例

```ts
Column() {
  Text('Hello Shadow')
    .fontSize(24)
    .backgroundColor(Color.White)
    .padding(20)
    .borderRadius(12)
    .shadow({
      radius: 10,
      color: '#80000000',   // 半透明黑
      offsetX: 0,
      offsetY: 4
    })
}
```

---

### 🧠 4. 链式简写（仅调半径）

```ts
.shadow(8)          // 等价于 {radius: 8}
```

---

### ⚠️ 5. 注意点

1. **性能**  
   阴影会增加 GPU 负载，列表中大量卡片慎用高斯半径。
2. **裁剪**  
   如果父容器设置了 `clip(true)`，阴影超出部分会被裁剪。
3. **Z 轴**  
   `shadow` 仅做 **2D 投影**，不会参与 `zIndex` 的 3D 层级遮挡。
4. **fill / path**  
   仅在 `Path` 等自定义形状里生效，普通矩形可忽略。

---

### ✅ 一句话总结

> **shadow** = `{radius, color, offsetX, offsetY}`  
> 一行代码即可让任何组件拥有 **高斯阴影**，半径越大越柔和。