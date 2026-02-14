# Serendipity - 项目规格文档

> **错过了么** - 记录生活中那些擦肩而过的瞬间

## 📋 项目概述

### 项目信息
- **项目名称（中文）**：错过了么
- **项目名称（英文）**：Serendipity
- **项目类型**：移动应用（Android + iOS）
- **技术栈**：Flutter + Dart
- **目标用户**：18-35岁的都市青年
- **核心定位**：情感记录类应用，专注于记录日常生活中错过的人

### 项目愿景
在快节奏的都市生活中，我们每天都会与无数陌生人擦肩而过。有些人只是一瞥，却在心中留下涟漪。

也许是通勤路上地铁里读书的 TA，也许是咖啡馆里安静工作的 TA，也许是公园长椅上发呆的 TA，也许是健身房里挥汗如雨的 TA...

Serendipity 让用户记录这些转瞬即逝的瞬间，保存那些未曾开口的遗憾，也许某天，命运会给你第二次机会。

---

## 🎯 核心功能

### 1. 记录系统

#### 1.1 快速记录
用户可以快速记录一次"错过"，包含以下元素：

**必填项**：
- ⏰ **时间**：自动获取当前时间（可手动调整）
- 📍 **地点**：自动获取GPS定位（可手动输入）
- 💫 **状态**：选择当前状态（允许从任意状态开始）
  - 🌫️ 错过（第一次看到，但没说话）
  - 🌟 再遇（又看到了，但还是没说话）
  - 💫 邂逅（终于说话了）
  - 💝 重逢（说过话后，又见面了）
  - 🥀 别离（主动结束了）
  - 🍂 失联（被动消失，再也没见过）

**💡 重要提示**（首次创建记录时显示）：
```
┌─────────────────────────┐
│ 💡 如何记录？            │
├─────────────────────────┤
│ 每次见面 = 一条新记录    │
│                         │
│ 例如：                   │
│ • 今天在地铁看到 TA      │
│   → 创建记录，选择"错过" │
│                         │
│ • 明天又看到 TA          │
│   → 创建新记录，选择"再遇"│
│                         │
│ • 后天终于说话了         │
│   → 创建新记录，选择"邂逅"│
│                         │
│ 然后通过"故事线"功能     │
│ 把这些记录关联起来       │
│                         │
│ [我知道了]              │
└─────────────────────────┘
```

**可选项**：
- 📍 **场所类型**：选择遇见的场所类型（可选）
  - 交通：🚇 地铁、🚌 公交、🚄 火车站、✈️ 机场
  - 餐饮：☕ 咖啡馆、🍽️ 餐厅、🍺 酒吧、🍵 茶馆、🍰 甜品店
  - 购物：🛍️ 商场、🛒 超市、📚 书店
  - 休闲：🌳 公园、🎬 电影院、🏛️ 博物馆、🎨 美术馆、🐠 水族馆、🦁 动物园、🎡 游乐园
  - 运动：💪 健身房、🏊 游泳馆、🏟️ 体育馆
  - 学习：📖 图书馆、🎓 学校、🏢 办公楼
  - 医疗：🏥 医院、⚕️ 诊所
  - 其他：🏨 酒店、🏖️ 海滩、⛰️ 山/景区、🛣️ 街道、📍 其他
  - 用途：帮助追踪成就（如"咖啡馆邂逅"、"地铁常客"）
- 📝 **描述**：文字描述（可选，500字以内）
  - 记录当时的感受、想法、细节
  - 例如："她在读《百年孤独》，阳光透过车窗洒在她的侧脸上..."
- 🏷️ **特征标签**：预设标签 + 自定义标签 + 备注
  - 外观：[长发] [短发] [戴眼镜] [戴耳机] [背包客]
  - 服饰：[白色大衣] [运动装] [西装] [连衣裙]
  - 行为：[看书] [听音乐] [玩手机] [发呆]
  - 氛围：[文艺] [阳光] [神秘] [温柔]
  - 备注：每个标签可添加备注（可选，最多50字）
    - 例如："光线不好，可能是深棕色"
    - 例如："圆框眼镜，很文艺"
    - 例如："或者是米白色？不太确定"
- 💬 **对话契机**：仅"邂逅"状态显示（可选，最多500字）
  - 记录是什么让你们开始交流的
  - 例如："她掉了一本书，我帮她捡起来"
  - 例如："我们在等地铁时聊起了天气"
  - 例如："他问我这班车去哪里"
- 💭 **情绪强度**：这个人在你心里停留了多久
  - 「几乎没感觉」
  - 「有点在意」
  - 「回家后还在想」
  - 「想了一整晚」
  - 「至今难忘」
- 🎵 **背景音乐**：记录当时在听的歌（可选）
- 🌤️ **天气**：手动选择天气（可选）
  - 预设选项：晴天、多云、阴天、毛毛雨、小雨、中雨、大雨、暴雨、冻雨、小雪、中雪、大雪、暴雪、雨夹雪、冰雹、轻雾、雾、霾、沙尘、沙尘暴、微风、大风、台风、飓风、龙卷风

**其他设置**：
- 📢 **发布到树洞**：是否同步发布到社区（可选，默认关闭）
- 📖 **关联到故事线**：选择关联的故事线（可选）
  - 可以创建新故事线
  - 可以选择已有故事线
  - 可以跳过（不关联）

**设计说明**：
- **允许从任意状态开始记录**：用户可能在开始使用 app 之前就已经经历了多个阶段
  - 例如：用户今天和某人分手了，想记录"别离"状态，之前的"错过"、"再遇"、"邂逅"、"重逢"都没记录
  - 例如：用户今天又在地铁上看到昨天那个人，选择"再遇"状态，昨天的"错过"没记录
- **每次状态变化 = 创建新记录**：如果又见面了，创建一个新记录，选择新状态
- **状态可以修改**：防止用户手滑点错状态，可以在记录详情中修改

**💡 界面提示**（创建记录时，状态选择下方显示）：
```
提示：每次见面创建一条新记录，然后通过"故事线"关联
```

#### 1.2 视觉设计原则
**❌ 不使用照片功能**，原因：
- 避免给用户心理压力（匆忙中拍照）
- 避免偷拍的道德和法律风险
- 保持"错过"的朦胧美感
- 保护隐私

**✅ 替代方案**：
- 使用渐变色卡片代表不同情感
- 用抽象图形/纹理增加美感
- 根据标签和描述生成意境插画（可选）

#### 1.3 标签备注功能

**功能说明**：
- 每个标签可以添加备注（可选）
- 备注用于补充说明、表达不确定性
- 字数限制：0-50字

**使用场景**：
```
标签：[长发]
备注："光线不好，可能是深棕色"

标签：[戴眼镜]
备注："圆框眼镜，很文艺"

标签：[白色大衣]
备注："或者是米白色？不太确定"
```

**UI 设计**：
```
┌─────────────────────────┐
│ 🏷️ 添加特征标签         │
├─────────────────────────┤
│ 选择标签：               │
│ [长发] [短发] [戴眼镜]   │
│                         │
│ 已选择：                 │
│ • 长发                   │
│   备注：[点击添加备注]   │
│                         │
│ • 戴眼镜                 │
│   备注：圆框，很文艺     │
│                         │
│ • 白色大衣               │
│   备注：或者是米白色？   │
│                         │
│ [完成]                  │
└─────────────────────────┘
```

**备注的作用**：
1. **提高验证准确性**：补充细节，帮助对方确认
2. **增加真实感**：表达不确定性，骗子难以伪造
3. **降低误判**：提供更多信息，减少误判
4. **帮助回忆**：帮助自己回忆当时的细节

**字数限制**：最多50字（可选，可以不填）

#### 1.4 地点输入详细设计

**功能说明**：
- 地点信息包含三个部分：GPS 坐标、地址、地点名称、场所类型
- GPS 坐标和地址自动获取，地点名称和场所类型由用户手动输入（可选）

**三个字段的区别**：

| 字段 | 来源 | 格式 | 示例 | 用途 |
|------|------|------|------|------|
| `latitude` + `longitude` | GPS 自动获取 | 经纬度坐标 | `39.9087, 116.3975` | 精确定位、匹配验证 |
| `address` | GPS 逆地理编码 | 标准地址 | `北京市朝阳区建国门外大街1号` | 地图显示、统计分析 |
| `placeName` | 用户手动输入 | 自由文本 | `常去的那家咖啡馆` | 个性化标记、易于回忆 |
| `placeType` | 用户选择 | 枚举值 | `subway`（地铁） | 成就追踪、场所分类 |

**UI 流程设计**：

```
┌─────────────────────────┐
│ 📍 地点                  │
├─────────────────────────┤
│ 正在获取位置...          │
│ [GPS 定位中 ⏳]         │
└─────────────────────────┘

↓ GPS 定位成功

┌─────────────────────────┐
│ 📍 地点                  │
├─────────────────────────┤
│ ✅ 已定位                │
│ 北京市朝阳区建国门外大街1号│
│                         │
│ 给这个地点起个名字？     │
│ （可选，方便回忆）       │
│ [常去的那家咖啡馆____]  │
│                         │
│ 这是什么场所？（可选）   │
│ [🚇 地铁] [☕ 咖啡馆]    │
│ [🛍️ 商场] [🌳 公园]...  │
│                         │
│ [下一步]                │
└─────────────────────────┘

↓ GPS 定位失败

┌─────────────────────────┐
│ 📍 地点                  │
├─────────────────────────┤
│ ⚠️ 无法获取GPS定位       │
│                         │
│ 请手动输入地点：         │
│ [常去的那家咖啡馆____]  │
│                         │
│ 这是什么场所？（可选）   │
│ [🚇 地铁] [☕ 咖啡馆]    │
│ [🛍️ 商场] [🌳 公园]...  │
│                         │
│ [下一步]                │
└─────────────────────────┘
```

**场所类型选择 UI**：

```
┌─────────────────────────┐
│ 🏷️ 选择场所类型          │
├─────────────────────────┤
│ 交通                     │
│ [🚇 地铁] [🚌 公交]      │
│ [🚄 火车站] [✈️ 机场]    │
│                         │
│ 餐饮                     │
│ [☕ 咖啡馆] [🍽️ 餐厅]    │
│ [🍺 酒吧] [🍵 茶馆]      │
│ [🍰 甜品店]              │
│                         │
│ 购物                     │
│ [🛍️ 商场] [🛒 超市]      │
│ [📚 书店]                │
│                         │
│ 休闲娱乐                 │
│ [🌳 公园] [🎬 电影院]    │
│ [🏛️ 博物馆] [🎨 美术馆]  │
│ [🐠 水族馆] [🦁 动物园]  │
│ [🎡 游乐园]              │
│                         │
│ 运动健身                 │
│ [💪 健身房] [🏊 游泳馆]  │
│ [🏟️ 体育馆]              │
│                         │
│ 学习工作                 │
│ [📖 图书馆] [🎓 学校]    │
│ [🏢 办公楼]              │
│                         │
│ 医疗健康                 │
│ [🏥 医院] [⚕️ 诊所]      │
│                         │
│ 其他                     │
│ [🏨 酒店] [🏖️ 海滩]      │
│ [⛰️ 山/景区] [🛣️ 街道]   │
│ [📍 其他]                │
│                         │
│ [跳过]  [确认]          │
└─────────────────────────┘
```

**显示优先级规则**：

```dart
/// 获取地点的显示文本
String getDisplayLocation(Location location) {
  // 优先级 1：用户输入的地点名称（最有温度）
  if (location.placeName != null && location.placeName!.isNotEmpty) {
    // 如果有场所类型，显示图标
    if (location.placeType != null) {
      return '${location.placeType!.icon} ${location.placeName}';
    }
    return location.placeName!;
  }
  
  // 优先级 2：GPS 获取的地址（标准但冷冰冰）
  if (location.address != null && location.address!.isNotEmpty) {
    // 如果地址太长，截断显示
    if (location.address!.length > 20) {
      return '${location.address!.substring(0, 20)}...';
    }
    return location.address!;
  }
  
  // 优先级 3：场所类型（至少有个分类）
  if (location.placeType != null) {
    return '${location.placeType!.icon} ${location.placeType!.label}';
  }
  
  // 优先级 4：实在没有，显示默认文本
  return '未知地点';
}
```

**记录卡片显示效果**：

```
┌─────────────────────────┐
│ 2026.02.08  错过 🌫️    │
├─────────────────────────┤
│ 📍 🚇 常去的那家咖啡馆   │ ← placeName + placeType 图标
│                         │
│ "她在读《百年孤独》..."  │
│                         │
│ [长发] [戴眼镜] [看书]   │
└─────────────────────────┘

如果用户没输入 placeName：
┌─────────────────────────┐
│ 2026.02.08  错过 🌫️    │
├─────────────────────────┤
│ 📍 北京市朝阳区建国门... │ ← address（截断）
│                         │
│ "她在读《百年孤独》..."  │
└─────────────────────────┘

如果只选了 placeType：
┌─────────────────────────┐
│ 2026.02.08  错过 🌫️    │
├─────────────────────────┤
│ 📍 🚇 地铁               │ ← placeType 图标 + 标签
│                         │
│ "她在读《百年孤独》..."  │
└─────────────────────────┘
```

**GPS 定位失败处理**：

```
场景1：用户拒绝 GPS 权限
┌─────────────────────────┐
│ ⚠️ 需要位置权限          │
├─────────────────────────┤
│ 为了更好的体验，         │
│ 建议开启位置权限。       │
│                         │
│ 开启后可以：             │
│ • 自动记录地点           │
│ • 启用匹配功能           │
│ • 查看地图热力图         │
│                         │
│ [去设置]  [稍后]        │
└─────────────────────────┘

场景2：GPS 信号弱
┌─────────────────────────┐
│ ⚠️ GPS 信号弱            │
├─────────────────────────┤
│ 正在尝试定位...          │
│                         │
│ 你也可以：               │
│ [手动输入地点]          │
│ [跳过]                  │
└─────────────────────────┘

场景3：完全无法定位
┌─────────────────────────┐
│ ⚠️ 无法获取位置          │
├─────────────────────────┤
│ 请手动输入地点：         │
│ [常去的那家咖啡馆____]  │
│                         │
│ 场所类型（可选）：       │
│ [🚇 地铁] [☕ 咖啡馆]... │
│                         │
│ [确认]  [跳过]          │
└─────────────────────────┘
```

**设计说明**：

1. **GPS 优先，但不强制**
   - 首次使用时友好引导开启 GPS
   - 拒绝 GPS 也能正常使用，只是部分功能受限
   - 无 GPS 则无法参与匹配功能（匹配需要 GPS 验证）

2. **地点名称完全可选**
   - 用户可以不输入，直接使用 GPS 地址
   - 但鼓励输入，因为更有温度、更易回忆

3. **场所类型用于成就追踪**
   - 选择"地铁"可以追踪"地铁常客"成就
   - 选择"咖啡馆"可以追踪"咖啡馆邂逅"成就
   - 完全可选，不影响核心功能

4. **显示优先级清晰**
   - 优先显示用户输入的名称（有温度）
   - 其次显示 GPS 地址（标准）
   - 最后显示场所类型（至少有个分类）

5. **数据完整性**
   - GPS 坐标用于匹配验证（精确）
   - 地址用于地图显示（标准）
   - 地点名称用于用户回忆（个性化）
   - 场所类型用于成就追踪（分类）

---

### 2. 状态流转系统

#### 2.1 六种状态

| 状态 | 英文 | 图标 | 含义 | 触发方式 |
|------|------|------|------|---------|
| **错过** | Missed | 🌫️ | 初次看到但未交流 | 创建记录 |
| **再遇** | Re-encounter | 🌟 | 再次看到同一个人 | 手动标记 |
| **邂逅** | Met | 💫 | 终于有了交流 | 手动标记 |
| **重逢** | Reunion | 💝 | 分开后再次相遇（需先别离） | 手动标记 |
| **别离** | Farewell | 🥀 | 主动结束关系（需先邂逅） | 手动标记 |
| **失联** | Lost | 🍂 | 被动消失，再也没见过 | 手动标记 |

#### 2.2 状态流转规则

```
[错过] → [再遇] → [再遇] → ... → [邂逅] → [别离] ⇄ [重逢]
  ↓        ↓        ↓               ↓         ↓         ↓
[失联]   [失联]   [失联]          [失联]    [失联]    [失联]
```

**规则说明**：
- **错过 → 再遇 → 再遇 → ...**：可以多次"再遇"（一直看到但没说话）
  - 例如：每天地铁上看到同一个人，看了10次、20次
  - 每次"再遇"都可以记录新的细节和心情
  - 直到某天终于"邂逅"（说话了）
- **邂逅 → 别离 ⇄ 重逢**：可以循环（分分合合的人生）
  - 邂逅 → 别离 ✅（交流后分开）
  - 别离 → 重逢 ✅（分开后再次相遇）
  - 重逢 → 别离 ✅（又分开了）
  - 别离 → 重逢 → 别离 → ...（可以无限循环）
- **重逢的前置条件**：必须先经历"别离"或"失联"后又找到
  - ⚠️ 邂逅后如果继续在一起，不需要记录（因为已经不是"错过"）
  - ⚠️ 只有分开后再次相遇，才是真正的"重逢"
- **失联**：唯一的终点，任何状态都可以标记为"失联"
- 每次状态变更都会记录时间和备注

**别离 vs 失联**：
- **别离**：主动的结束（分手、好聚好散、发现不合适）
- **失联**：被动的消失（再也没见过、联系不上了）

**为什么允许循环？**
- 因为现实人生就是循环的
- 在一起 → 分手 → 复合 → 再分手...
- 这才是真实的人生

**邂逅之后为什么不记录了？**
- 因为项目叫"错过了么"，不是"邂逅了么"
- 核心是记录错过、遗憾、擦肩而过
- 邂逅后如果继续交往，就不再是"错过"，而是"拥有"
- 只有分开了（别离/失联），才又回到"错过"的状态
- 这时如果再次相遇，就是"重逢"

#### 2.3 更改状态

**功能说明**：
- 用户可能手滑点错状态
- 通过编辑记录功能修改状态

**操作方式**：
- 记录详情页 → 点击编辑按钮 → 修改状态 → 保存

**重要说明**：
- ⚠️ 更改状态只是修正错误，不是记录状态变化
- ⚠️ 如果又见面了，应该创建新记录，而不是修改旧记录
- ⚠️ 例如：今天"错过"，明天"再遇" → 创建2条记录，而不是修改第1条

---

### 3. 故事线功能

#### 3.1 记录关联

**核心概念**：
- 用户可以将多条记录组合成一个"故事线"
- 一个故事线 = 同一个人的多次记录
- 形成完整的时间线故事

**重要说明**：
- 💡 **只有加入故事线的记录才会参与匹配功能**
- **原因**：程序需要知道哪些记录是同一个人，才能准确匹配
- **技术限制**：程序无法自动判断，需要用户通过故事线告诉程序

**关联方式：手动关联**

操作流程：
```
用户在时间轴看到一条记录
  ↓
点击记录 → 操作菜单
  ↓
选择"关联到故事线"
  ↓
弹出选择框：
  - 创建新故事线
  - 添加到现有故事线
  ↓
选择后，记录被添加到故事线
```

UI 设计：
```
┌─────────────────────────┐
│ 关联到故事线             │
├─────────────────────────┤
│ 💡 重要提示：            │
│ 只有加入故事线的记录     │
│ 才会参与匹配功能。       │
│                         │
│ 原因：程序需要知道       │
│ 哪些记录是同一个人，     │
│ 才能准确匹配。           │
│                         │
│ ━━━━━━━━━━━━━━━━━━━━━  │
│                         │
│ ○ 创建新故事线           │
│   [输入故事线名称...]    │
│                         │
│ 已有的故事线：           │
│ ○ 📖 地铁上的她（3条）  │
│ ○ 📖 咖啡馆的他（2条）  │
│ ○ 📖 图书馆的女孩（1条）│
│                         │
│ [确认]  [取消]          │
└─────────────────────────┘
```

#### 3.2 故事线展示

```
┌─────────────────────────┐
│ 📖 TA 的故事             │
├─────────────────────────┤
│ 2026.02.08  错过 🌫️    │
│ 地铁10号线               │
│ "她在读《百年孤独》..."  │
│         ↓               │
│ 2026.02.15  再遇 🌟     │
│ 地铁10号线               │
│ "又是同一班地铁！"       │
│         ↓               │
│ 2026.02.20  邂逅 💫     │
│ 星巴克                   │
│ 💬 她掉了一本书，我帮她  │
│    捡起来...             │
│ "终于鼓起勇气搭话了！"   │
│         ↓               │
│ 2026.03.01  重逢 💝     │
│ 同一家星巴克             │
│ "今天一起喝了咖啡"       │
└─────────────────────────┘

[+ 添加新的进展]
```

#### 3.3 "如果再遇"备忘
- 用户可以为"错过"状态的记录设置备忘
- 内容："如果再遇到，我想说..."
- 当标记为"再遇"时，app 提醒用户之前写的话

#### 3.4 标签词云图（💎 会员功能）

**功能说明**：
- 自动统计故事线中所有标签的出现频率
- 生成视觉化的词云图
- 高频标签字体更大，帮助用户快速识别 TA 的核心特征

**局部词云（单个故事线）**：
```
┌─────────────────────────┐
│ 📖 TA 的故事             │
├─────────────────────────┤
│ 2026.02.08  错过 🌫️    │
│ 标签：[长发] [戴眼镜] [看书]
│         ↓               │
│ 2026.02.15  再遇 🌟     │
│ 标签：[长发] [白色大衣] [听音乐]
│         ↓               │
│ 2026.02.20  邂逅 💫     │
│ 标签：[长发] [笑容温暖] [文艺]
│                         │
│ ━━━━━━━━━━━━━━━━━━━━━  │
│                         │
│ 🏷️ TA 的印象词云 💎     │
│                         │
│   [长发] ← 出现3次      │
│   [戴眼镜] [看书]       │
│   [白色大衣] [听音乐]   │
│   [笑容温暖] [文艺]     │
│                         │
└─────────────────────────┘
```

**全局词云（所有记录）**：
```
┌─────────────────────────┐
│ 📊 我的错过统计          │
├─────────────────────────┤
│ 总共错过：23 人          │
│ 再遇：5 人               │
│ 邂逅：2 人               │
│ 重逢：1 人 ❤️           │
│                         │
│ 🏷️ 我最常错过的类型 💎  │
│                         │
│   [长发]  [戴眼镜]      │
│     [看书]  [文艺]      │
│   [白色大衣]            │
│                         │
│ 你似乎对文艺青年情有独钟 │
└─────────────────────────┘
```

**免费用户展示**：
- 显示模糊的词云预览
- 提示"升级会员解锁完整词云图"
- 作为付费转化的触发点

**会员专属功能**：
- ✅ 查看完整词云图

---

### 4. 浏览与查看

#### 4.1 时间轴视图（默认）
- 按时间倒序排列所有记录
- 卡片式设计，不同状态不同颜色
- 支持下拉刷新

#### 4.2 地图视图
- 在地图上标记所有"错过"的地点
- 点击标记查看详情
- 热力图显示高频地点

#### 4.3 筛选与搜索
- 按状态筛选
- 按地点筛选
- 按时间范围筛选
- 按标签搜索
- 按情绪强度筛选

#### 4.4 统计面板

**基础统计（免费）**：
```
┌─────────────────────────┐
│ 📊 我的错过统计          │
├─────────────────────────┤
│ 总共错过：23 人          │
│ 再遇：5 人               │
│ 邂逅：2 人               │
│ 重逢：1 人 ❤️           │
│ 失联：15 人              │
│                         │
│ 成功率：4.3%            │
│ 最常错过的地点：地铁10号线│
│ 最常错过的时间：18:00-19:00│
└─────────────────────────┘
```

**高级统计（💎 会员）**：
```
┌─────────────────────────┐
│ 📊 我的错过统计          │
├─────────────────────────┤
│ 总共错过：23 人          │
│ 再遇：5 人               │
│ 邂逅：2 人               │
│ 重逢：1 人 ❤️           │
│ 失联：15 人              │
│                         │
│ 成功率：4.3%            │
│ 最常错过的地点：地铁10号线│
│ 最常错过的时间：18:00-19:00│
│                         │
│ 🏷️ 我最常错过的类型 💎  │
│                         │
│   [长发]  [戴眼镜]      │
│     [看书]  [文艺]      │
│   [白色大衣]            │
│                         │
│ 📈 趋势分析 💎          │
│ [查看地图热力图]         │
│ [查看时间分布图]         │
│ [生成年度报告]          │
└─────────────────────────┘
```

---

### 5. 成就系统

#### 5.1 成就列表

**新手成就**：
- 🌫️ **第一次错过** - 创建第一条记录
- 📝 **记录10次错过** - 累计创建10条记录
- 🗓️ **连续7天记录** - 连续7天使用app

**进阶成就**：
- 🌟 **第一次再遇** - 第一次标记"再遇"状态
- 💫 **第一次邂逅** - 第一次标记"邂逅"状态
- 💝 **第一次重逢** - 第一次标记"重逢"状态
- 🎯 **在同一地点错过5次** - 在同一地点（GPS < 100米）创建5条记录
- 🌧️ **雨天的错过** - 在雨天创建记录
- 🌙 **深夜的错过（22:00后）** - 在22:00后创建记录
- 🌅 **清晨的错过（7:00前）** - 在7:00前创建记录

**稀有成就**：
- 🎊 **错过50个人** - 累计创建50条记录
- 💯 **错过100个人** - 累计创建100条记录
- 🏆 **成功率达到10%** - 邂逅/重逢的记录占比达到10%
- 🔥 **连续30天记录** - 连续30天使用app

**故事线成就**：
- 📖 **第一条故事线** - 创建第一条故事线
- 📚 **故事收集者** - 创建3条故事线（免费版上限）
- 📕 **故事大师** - 创建10条故事线（会员专属）
- 💝 **真爱无价** - 同一个人的故事线达到10条记录

**社交成就**：
- 🌍 **第一次发布到社区** - 第一次匿名发布
- 🎭 **树洞常客** - 发布10条到社区
- 💫 **奇迹发生** - 匹配成功一次
- 💬 **第一次对话** - 第一次使用私信功能

**情感成就**：
- 💔 **第一次失联** - 第一次标记"失联"状态
- 🥀 **第一次别离** - 第一次标记"别离"状态
- 🌈 **重新开始** - 从"别离"状态再次标记"邂逅"

**特殊场景成就**：
- 🚇 **地铁常客** - 在地铁创建10条记录
- ☕ **咖啡馆邂逅** - 在咖啡馆创建5条邂逅状态的记录
- 🌃 **城市漫游者** - 在5个不同城市创建记录
- 🎄 **节日的错过** - 在节日（春节、情人节、圣诞节等）创建记录

#### 5.2 成就系统的价值

**为什么要做成就系统？**

1. **正反馈机制**
   - 解锁成就时的通知给用户即时满足感
   - 完成度百分比激励用户继续使用

2. **引导用户探索**
   - 通过成就引导用户尝试不同功能
   - 例如："第一次发布到社区"引导用户使用社区功能

3. **增加粘性**
   - 用户会为了解锁成就而持续使用
   - "连续7天记录"鼓励用户养成习惯

4. **情感共鸣**
   - 成就名称和描述本身就有情感价值
   - 例如："奇迹见证者"让用户感受到特殊

**成就本身就是奖励**：
- ✅ 解锁通知的满足感
- ✅ 完成度的成就感
- ✅ 稀有成就的炫耀感
- ❌ 不需要额外的物质奖励

#### 5.3 成就通知设计

**解锁通知样式**：
```
┌─────────────────────────┐
│ 🎉 成就解锁！            │
├─────────────────────────┤
│                         │
│        🌫️               │
│                         │
│    第一次错过            │
│                         │
│ 你记录了第一次错过       │
│ 这是一个新的开始         │
│                         │
│ [查看成就]  [继续]      │
└─────────────────────────┘
```

**成就解锁动画**：
- 从屏幕顶部滑入
- 带有粒子效果
- 播放轻快的音效
- 3秒后自动消失（或用户点击关闭）

#### 5.4 成就页面设计

**成就列表页面**：
```
┌─────────────────────────┐
│ 🏆 我的成就              │
├─────────────────────────┤
│ 已解锁：8/25            │
│ 完成度：32%             │
│                         │
│ 新手成就 (3/3) ✅       │
│ ✅ 🌫️ 第一次错过        │
│    2026.02.08 解锁      │
│ ✅ 📝 记录10次错过       │
│    2026.02.15 解锁      │
│ ✅ 🗓️ 连续7天记录        │
│    2026.02.14 解锁      │
│                         │
│ 进阶成就 (3/7)          │
│ ✅ 🌟 第一次再遇         │
│    2026.02.10 解锁      │
│ ✅ 💫 第一次邂逅         │
│    2026.02.20 解锁      │
│ ⬜ 💝 第一次重逢         │
│    未解锁               │
│ ⬜ 🎯 在同一地点错过5次  │
│    进度：3/5            │
│                         │
│ 稀有成就 (0/4)          │
│ ⬜ 🎊 错过50个人         │
│    进度：23/50          │
│                         │
│ [查看全部]              │
└─────────────────────────┘
```

**成就详情页面**：
```
┌─────────────────────────┐
│ 🌫️ 第一次错过           │
├─────────────────────────┤
│ 新手成就                 │
│                         │
│ 你记录了第一次错过       │
│ 这是一个新的开始         │
│                         │
│ 解锁时间：               │
│ 2026.02.08 18:30        │
│                         │
│ [返回]                  │
└─────────────────────────┘
```

#### 5.5 成就触发逻辑

**触发时机**：
- 用户完成特定操作后立即检测
- 后台定时任务检测（如连续天数）
- 不打断用户当前操作

**检测规则**：
```dart
// 示例：检测"第一次错过"成就
void checkFirstMissedAchievement(User user) {
  if (user.recordCount == 1 && !user.hasAchievement('first_missed')) {
    unlockAchievement(user, 'first_missed');
  }
}

// 示例：检测"连续7天记录"成就
void checkConsecutiveDaysAchievement(User user) {
  int consecutiveDays = calculateConsecutiveDays(user);
  if (consecutiveDays >= 7 && !user.hasAchievement('7_days_streak')) {
    unlockAchievement(user, '7_days_streak');
  }
}
```

**解锁流程**：
```
用户完成操作
  ↓
触发成就检测
  ↓
判断是否满足条件
  ↓
满足 → 解锁成就
  ↓
保存到数据库
  ↓
显示解锁通知
```

#### 5.6 成就统计

**统计维度**：
- 总成就数量
- 已解锁数量
- 完成度百分比
- 各类别完成情况
- 稀有成就解锁率

**排行榜（可选）**：
- 成就数量排行
- 完成度排行
- 仅显示前100名
- 匿名显示（不显示用户名）

---


### 7. 关于页面

关于页面的完整内容请查看：**[About_Page_Content.md](./About_Page_Content.md)**

#### 7.1 页面结构

关于页面包含以下章节：

1. **关于 Serendipity**
   - 产品定位和理念
   - "不是为了重逢，而是为了记住那些转瞬即逝的瞬间"

2. **四重防御机制**
   - 解释匹配功能的安全性
   - 为什么遇到骗子的可能性极低

3. **状态说明**
   - 六种状态的含义和区别
   - 核心区别：有没有交流过

4. **如何记录多次见面**
   - 每次见面 = 一条新记录
   - 通过"故事线"关联

5. **设计理念**
   - 不告诉你"正在匹配中"（避免焦虑）
   - 不告诉你"匹配失败"（避免失望）
   - 只在奇迹发生时轻轻告诉你

6. **为什么树洞不能互动？**
   - 防骗机制
   - "错过"的本质
   - 产品定位

7. **为什么不能修改发布到社区的记录？**
   - 保持真实性
   - 防止滥用
   - 社区发布是快照
   - 解决方案：删除+重新发布

8. **为什么不提供举报功能？**
   - 一人开发的现实
   - 举报功能的问题
   - 诚实的选择

9. **技术选择**
   - Flutter + Dart
   - Firebase 云同步
   - GPS 定位验证

10. **开发者信息**
   - 版本号
   - 更新日期

#### 7.2 用户协议与隐私政策

**用户协议要点**：
- 禁止发布不当内容
- 禁止留下联系方式
- 禁止骚扰他人
- 依赖用户自律

**隐私政策要点**：
- GPS 坐标加密存储
- 不会公开精确坐标
- 匿名发布不显示身份
- 用户可随时删除数据

**内容管理说明**：
- 本应用不提供举报功能
- 不做自动内容检测
- 发布到社区时会提醒用户不要包含隐私信息
- 依赖用户自律和社区氛围
- 如遇严重问题可通过邮件联系开发者

#### 7.3 实现建议

**UI 布局**：
- 使用 `SingleChildScrollView` 包裹整个内容
- 每个章节之间用分隔线区分
- 使用合适的字体大小和行距
- 考虑添加渐变背景或纹理增加氛围感

**文案展示**：
- 可以使用 `Card` 或 `Container` 模拟手机界面的边框效果
- 文字居中对齐
- 使用温暖的配色（灰蓝色调）
- 适当的内边距

**交互设计**：
- 页面顶部添加返回按钮
- 底部可以添加"联系开发者"按钮
- 考虑添加"分享"功能

---

### 8. 个性化设置

#### 8.1 主题设置

**主题选择**：
- **浅色**（默认）- 明亮清爽的浅色界面
- **深色** - 适合夜间使用的深色界面
- **跟随系统** - 自动跟随系统明暗模式
- **朦胧** 💎 会员专属 - 灰蓝色调，朦胧梦幻
- **深夜** 💎 会员专属 - 深蓝黑色调，沉静神秘
- **温暖** 💎 会员专属 - 米黄色调，温馨柔和
- **秋日** 💎 会员专属 - 橙棕色调，怀旧复古

**强调色**（会员专属）：
- 自定义按钮、链接、重要元素的颜色
- 预设颜色：蓝色、粉色、绿色、橙色、紫色
- 自定义颜色：色轮选择器

**说明**：
- 免费用户可使用：浅色、深色、跟随系统
- 会员用户额外解锁：朦胧、深夜、温暖、秋日 + 自定义强调色

#### 8.2 隐私设置
- 云同步（所有用户数据存 Firestore）
  - 免费版：单设备登录（换设备会踢下线旧设备）
  - 会员版：多设备同步（无限设备）
- 密码锁 / 生物识别锁
- 隐藏敏感记录

#### 8.3 通知设置
- 纪念日提醒（会员功能）
- 地点提醒（会员功能）
- 成就解锁通知

#### 8.4 导出功能
- 导出单条记录为图片（免费）
- 导出故事线为图文卡片（💎 会员功能）

---

### 9. 会员系统

#### 9.1 商业模式：自愿付费（Pay What You Want）

**核心理念**：
- 为爱发电
- 用户自愿付费
- 简单纯粹

**付费机制**：
```
用户注册 → 免费使用基础功能
想要会员功能 → 点击"升级会员"
选择金额 → 滑块 ¥0 - ¥648/月（默认 ¥1）
确认支付 → 解锁会员功能
```

**关键设计**：
- ✅ 用户可以选择 ¥0
- ✅ 但必须点击"支付"按钮（主动选择）
- ✅ 默认值是 ¥1 而非 ¥0（心理学暗示）
- ✅ 金额 = ¥0 时不调用支付 SDK，直接解锁
- ✅ 金额 > ¥0 时调用支付 SDK

#### 9.2 会员功能

**免费版**：
- ✅ 无限记录错过
- ✅ 状态流转（错过→再遇→邂逅→重逢）
- ✅ 时间轴视图
- ✅ 基础统计（数字统计）
- ✅ 地图视图（基础）
- ✅ 云同步（单设备登录，换设备会踢下线）
- ✅ 浏览社区（树洞）
- ✅ 发布到社区
- ✅ 基础主题（3个）
- ✅ 导出单条记录为图片
- ⚠️ 故事线限制：最多 3条（最多追踪 3个人）

**会员版（💎 ¥0-648/月）**：
- 💎 多设备同步（无限设备）
- 💎 无限故事线（追踪无限个人）
- 💎 标签词云图（局部 + 全局）
- 💎 高级主题（全部解锁）
- 💎 地图热力图
- 💎 地点提醒
- 💎 纪念日提醒
- 💎 导出故事线为图文卡片

#### 9.3 支付流程

```
用户点击"升级会员"
  ↓
显示滑块：¥0 - ¥648/月（默认 ¥1）
  ↓
用户调整金额
  ↓
点击"支付"按钮
  ↓
判断金额：
  ├─ = ¥0 → 直接解锁会员（不调用 SDK）
  └─ > ¥0 → 调用支付 SDK
  ↓
解锁会员功能
  ↓
显示感谢动画
```

**支付方式**：
- iOS：Apple In-App Purchase
- Android：Google Play Billing / 支付宝 / 微信支付

#### 9.4 会员展示

**升级会员页面**：
```
┌─────────────────────────┐
│ 💎 升级会员              │
├─────────────────────────┤
│ 解锁以下功能：           │
│                         │
│ 📱 多设备同步            │
│ 📖 无限故事线            │
│ 🏷️  标签词云图           │
│ 🎨 高级主题              │
│ 🗺️  地图热力图           │
│ 🔔 智能提醒              │
│                         │
│ ━━━━━━━━━━━━━━━━━━━━━  │
│                         │
│ 自定义金额               │
│                         │
│ ¥ [========●====] /月   │
│      0 ← 1 → 648        │
│                         │
│ 当前金额：¥1/月         │
│                         │
│ [确认]                  │
└─────────────────────────┘
```

**感谢页面**（支付成功后）：
```
┌─────────────────────────┐
│ 🎉                      │
├─────────────────────────┤
│ 感谢你的支持！           │
│                         │
│ 你的支持让这个项目       │
│ 能够持续运营下去         │
│                         │
│ 会员功能已解锁           │
│                         │
│ [开始使用]              │
└─────────────────────────┘
```

---

## 🎨 UI/UX 设计原则

### 设计理念
**避免通用 AI 美学，打造独特的情感化设计**

### 视觉风格
- **色彩**：温暖、柔和、有情感张力
  - 避免：Inter、Roboto、Arial 等通用字体
  - 避免：紫色渐变等俗套配色
- **字体**：选择独特且优雅的字体
  - 英文：Playfair Display、Crimson Text、Libre Baskerville
  - 中文：思源宋体、霞鹜文楷、站酷高端黑
- **动画**：流畅、有意义的过渡动画
  - 状态升级动画
  - 页面切换动画
  - 微交互动画

### 情感化设计

**色彩应用规则**：
- **整体界面**：使用用户选择的主题（浅色/深色/跟随系统/朦胧/深夜/温暖/秋日）
- **状态卡片**：根据记录状态动态应用情感色调（叠加在主题之上）
- **强调色**：用于按钮、链接、重要提示（会员可自定义）

**不同状态的视觉语言**：
- **错过** 🌫️：朦胧、柔和、灰蓝色调
- **再遇** 🌟：明亮、惊喜、金色点缀
- **邂逅** 💫：温暖、激动、粉橙色调
- **重逢** 💝：圆满、幸福、玫瑰金色调
- **别离** 🥀：淡然、接受、玫瑰灰色调
- **失联** 🍂：平静、释怀、秋叶色调

**说明**：
- 状态色调是**情感氛围**，不是整体主题
- 例如：用户选择"深色"主题 + 记录状态是"错过" = 深色界面 + 灰蓝色调的卡片
- 例如：用户选择"温暖"主题 + 记录状态是"邂逅" = 米黄色界面 + 粉橙色调的卡片

### 交互原则
- **快速记录**：4步内完成记录（时间 → 地点 → 状态 → 保存）
- **无压力**：除了时间、地点、状态，其他字段全部可选
- **有温度**：文案温暖、鼓励、不说教
- **有仪式感**：重要时刻配合动画和音效

---

## 🏗️ 技术架构

### 前端技术栈
- **框架**：Flutter 3.x
- **语言**：Dart 3.x
- **状态管理**：Riverpod 2.x
- **路由**：go_router
- **本地存储**：Hive / SQLite
- **地图**：高德地图 API
- **动画**：Flutter 内置动画 + Rive

### 后端方案
**Firebase（已确定）**
- Firebase Authentication（用户登录）
- Firestore（数据存储）
- Cloud Functions（业务逻辑）
- Cloud Messaging（推送通知）
- 支持跨设备同步

### 第三方服务
- **地图服务**：高德地图
- **词云生成**：暂不使用第三方插件，先用简单的标签频率列表展示（后期可优化为真正的词云可视化）

---

## 📊 数据模型

### EncounterRecord（记录）
```dart
class EncounterRecord {
  String id;                    // 唯一标识
  DateTime timestamp;           // 时间戳
  Location location;            // 地点
  String? description;          // 描述（可选，最多500字）
  List<TagWithNote> tags;       // 标签 + 备注
  EmotionIntensity? emotion;    // 情绪强度（可选）
  EncounterStatus status;       // 当前状态（可修改）
  String? storyLineId;          // 所属故事线ID（可选）
  String? ifReencounter;        // "如果再遇"备忘
  String? conversationStarter;  // 对话契机（仅邂逅状态，可选，最多500字）
  String? backgroundMusic;      // 背景音乐
  WeatherInfo? weather;         // 天气信息
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}
```

**说明**：
- 每次见面 = 一个新记录
- 每个记录有自己的时间、地点、描述、状态
- 通过 `storyLineId` 把同一个人的多条记录关联起来
- `status` 可以修改（防止用户手滑点错）
- `description` 可选（有些错过无法用语言描述，最多500字）
- `emotion` 可选（情绪强度）
- `conversationStarter` 仅在状态为"邂逅"时使用，记录对话的契机（可选，最多500字）

### StoryLine（故事线）
```dart
class StoryLine {
  String id;                    // 故事线ID
  String name;                  // 故事线名称（用户自定义）
  List<String> recordIds;       // 包含的记录ID列表（按时间排序）
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}
```

**说明**：
- 一个记录只能属于一个故事线（`storyLineId` 是单值）
- 一个故事线可以包含多条记录（`recordIds` 是列表）
- 记录可以不属于任何故事线（`storyLineId` 为 `null`）

### TagWithNote（标签 + 备注）
```dart
class TagWithNote {
  String tag;                   // 标签名称，如 "长发"
  String? note;                 // 备注（可选，最多50字），如 "光线不好，可能有误"
}
```

### Location（地点）
```dart
class Location {
  double? latitude;             // 纬度
  double? longitude;            // 经度
  String? address;              // 地址（文字，GPS 逆地理编码获取）
  String? placeName;            // 地点名称（用户手动输入，可选）
  PlaceType? placeType;         // 场所类型（用户选择，可选）
}
```

### PlaceType（场所类型枚举）
```dart
enum PlaceType {
  // 交通场所
  subway('subway', '地铁', '🚇'),
  bus('bus', '公交', '🚌'),
  train('train', '火车站', '🚄'),
  airport('airport', '机场', '✈️'),
  
  // 餐饮场所
  coffeeShop('coffee_shop', '咖啡馆', '☕'),
  restaurant('restaurant', '餐厅', '🍽️'),
  bar('bar', '酒吧', '🍺'),
  teaHouse('tea_house', '茶馆', '🍵'),
  dessertShop('dessert_shop', '甜品店', '🍰'),
  
  // 购物场所
  mall('mall', '商场', '🛍️'),
  supermarket('supermarket', '超市', '🛒'),
  bookstore('bookstore', '书店', '📚'),
  
  // 休闲娱乐
  park('park', '公园', '🌳'),
  cinema('cinema', '电影院', '🎬'),
  museum('museum', '博物馆', '🏛️'),
  artGallery('art_gallery', '美术馆', '🎨'),
  aquarium('aquarium', '水族馆', '🐠'),
  zoo('zoo', '动物园', '🦁'),
  amusementPark('amusement_park', '游乐园', '🎡'),
  
  // 运动健身
  gym('gym', '健身房', '💪'),
  swimmingPool('swimming_pool', '游泳馆', '🏊'),
  stadium('stadium', '体育馆', '🏟️'),
  
  // 学习工作
  library('library', '图书馆', '📖'),
  school('school', '学校', '🎓'),
  office('office', '办公楼', '🏢'),
  
  // 医疗健康
  hospital('hospital', '医院', '🏥'),
  clinic('clinic', '诊所', '⚕️'),
  
  // 其他
  hotel('hotel', '酒店', '🏨'),
  beach('beach', '海滩', '🏖️'),
  mountain('mountain', '山/景区', '⛰️'),
  street('street', '街道', '🛣️'),
  other('other', '其他', '📍');

  final String value;
  final String label;
  final String icon;
  const PlaceType(this.value, this.label, this.icon);
}
```

### WeatherInfo（天气信息）
```dart
class WeatherInfo {
  WeatherType type;             // 天气类型
  DateTime recordedAt;          // 记录时间
}
```

### WeatherType（天气类型枚举）
```dart
enum WeatherType {
  // 天空状况
  sunny(1, '晴天', '☀️'),
  cloudy(2, '多云', '⛅'),
  overcast(3, '阴天', '☁️'),
  
  // 降水类 - 雨（按强度从小到大）
  drizzle(4, '毛毛雨', '🌦️'),
  lightRain(5, '小雨', '🌦️'),
  moderateRain(6, '中雨', '🌧️'),
  heavyRain(7, '大雨', '🌧️'),
  rainstorm(8, '暴雨', '⛈️'),
  freezingRain(9, '冻雨', '🧊'),
  
  // 降水类 - 雪（按强度从小到大）
  lightSnow(10, '小雪', '🌨️'),
  moderateSnow(11, '中雪', '❄️'),
  heavySnow(12, '大雪', '❄️'),
  snowstorm(13, '暴雪', '❄️'),
  
  // 降水类 - 其他
  sleet(14, '雨夹雪', '🌨️'),
  hail(15, '冰雹', '🧊'),
  
  // 能见度
  mist(16, '轻雾', '🌫️'),
  fog(17, '雾', '🌫️'),
  haze(18, '霾', '😷'),
  dust(19, '沙尘', '💨'),
  sandstorm(20, '沙尘暴', '💨'),
  
  // 风力（按强度从小到大）
  breeze(21, '微风', '🍃'),
  windy(22, '大风', '💨'),
  
  // 极端天气
  typhoon(23, '台风', '🌀'),
  hurricane(24, '飓风', '🌀'),
  tornado(25, '龙卷风', '🌪️');

  final int value;
  final String label;
  final String icon;
  const WeatherType(this.value, this.label, this.icon);
}
```

### EncounterStatus（状态枚举）
```dart
enum EncounterStatus {
  missed(1, '错过'),
  reencounter(2, '再遇'),
  met(3, '邂逅'),
  reunion(4, '重逢'),
  farewell(5, '别离'),
  lost(6, '失联');

  final int value;
  final String label;
  const EncounterStatus(this.value, this.label);
}
```

### EmotionIntensity（情绪强度枚举）
```dart
enum EmotionIntensity {
  barelyFelt(1, '几乎没感觉'),
  slightlyCared(2, '有点在意'),
  thoughtOnWayHome(3, '回家后还在想'),
  allNight(4, '想了一整晚'),
  untilNow(5, '至今难忘');

  final int value;
  final String label;
  const EmotionIntensity(this.value, this.label);
}
```

### Achievement（成就）
```dart
class Achievement {
  String id;                    // 成就ID
  String name;                  // 成就名称
  String description;           // 成就描述
  String icon;                  // 图标
  bool unlocked;                // 是否解锁
  DateTime? unlockedAt;         // 解锁时间
}
```

### Match（匹配记录）
```dart
class Match {
  String id;                    // 匹配ID
  String userAId;               // 用户A的ID
  String recordAId;             // 用户A的记录ID
  
  // 候选记录列表（可能来自不同用户）
  List<CandidateRecord> candidateRecords;
  
  // 用户A的验证
  String? userASelectedRecordId;     // 用户A选择的记录ID
  VerificationChoice? userAChoice;   // 用户A的选择
  
  // 对方用户的验证（动态确定是谁）
  String? otherUserId;               // 对方用户ID（用户A选择后确定）
  String? otherUserSelectedRecordId; // 对方用户选择的记录ID
  VerificationChoice? otherUserChoice; // 对方用户的选择
  
  MatchStatus status;           // 匹配状态
  MatchConfidence confidence;   // 匹配置信度（high/medium/low）
  double matchScore;            // 匹配评分（0-100，最高分记录的评分）
  DateTime matchedAt;           // 匹配时间
  DateTime? notifiedAt;         // 通知时间（6小时冷静期后）
  bool isPermanentlyKeptInMemory;  // 是否永久留在记忆里（不再匹配）
  DateTime? verifiedAt;         // 验证完成时间
  DateTime? expiredAt;          // 过期时间（验证通过后7天）
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}

class CandidateRecord {
  String recordId;    // 记录ID
  String userId;      // 该记录属于哪个用户
  double score;       // 评分
}
```

**说明**：
- `candidateRecords`：所有候选记录（可能来自不同用户）
- `otherUserId`：在用户A选择某条记录后，动态确定对方是谁
- 支持所有情况：单用户单记录、单用户多记录、多用户、混合

**匹配后的再次匹配规则**：
- **"不是，认错人了"**：未来可以再次匹配（这次是误判）
- **"是的，这是我，但我选择让它留在记忆里，不联系"**：永久不再匹配（明确拒绝）
- 通过 `isPermanentlyKeptInMemory` 字段标记是否永久屏蔽
- 永久屏蔽的双方会被加入"留在记忆里"列表

### MatchConfidence（匹配置信度枚举）
```dart
enum MatchConfidence {
  high(1, '高置信度'),           // GPS < 50米 && 时间差 < 5分钟
  medium(2, '中置信度'),         // GPS < 200米 && 时间差 < 15分钟
  low(3, '低置信度');            // 仅地点名称匹配

  final int value;
  final String label;
  const MatchConfidence(this.value, this.label);
}
```

### MatchCandidate（匹配候选人）
```dart
class MatchCandidate {
  String userId;                // 候选用户ID
  List<String> candidateRecordIds;  // 所有候选记录ID（按评分排序）
  String matchType;             // 匹配类型（high/medium/low_confidence）
  double score;                 // 综合评分（0-100，最高分记录的评分）
}
```

**说明**：
- `candidateRecordIds`：该用户所有匹配的记录ID，按评分从高到低排序
- 验证页面会展示所有这些记录，让用户选择哪个是TA
```dart
enum MatchStatus {
  pending(1, '等待冷静期'),        // 刚匹配，等待6小时
  notified(2, '已通知'),          // 已推送通知给双方
  verifying(3, '验证中'),         // 至少一方已开始验证
  verified(4, '验证成功'),        // 双方都确认，解锁私信
  rejected(5, '验证失败'),        // 任何一方拒绝
  expired(6, '已过期');           // 7天对话期结束

  final int value;
  final String label;
  const MatchStatus(this.value, this.label);
}
```

### VerificationChoice（验证选择枚举）
```dart
enum VerificationChoice {
  wantContact(1, '想要联系'),           // 想要联系对方
  keepInMemory(2, '留在记忆里'),        // 不想联系，留在记忆里
  notMe(3, '不是我，认错人了');         // 认错人了

  final int value;
  final String label;
  const VerificationChoice(this.value, this.label);
}
```

**验证成功条件**：
1. 用户A选择了某条记录（`userASelectedRecordId` 不为空）
2. 对方用户完成了验证（`otherUserChoice` 不为空）
3. 对方用户确认了用户A的记录（`otherUserSelectedRecordId == recordAId`）
4. 双方都选择了"想要联系"（`userAChoice == wantContact && otherUserChoice == wantContact`）
```

### Conversation（对话）
```dart
class Conversation {
  String id;                    // 对话ID
  String matchId;               // 关联的匹配ID
  String userAId;               // 用户A的ID
  String userBId;               // 用户B的ID
  DateTime startedAt;           // 对话开始时间
  DateTime expiresAt;           // 对话过期时间（7天后）
  bool isActive;                // 是否活跃（任何一方可以结束对话）
  DateTime? endedAt;            // 对话结束时间
  String? endedBy;              // 结束对话的用户ID
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}
```

### Message（私信消息）
```dart
class Message {
  String id;                    // 消息ID
  String conversationId;        // 所属对话ID
  String senderId;              // 发送者ID
  String receiverId;            // 接收者ID
  String content;               // 消息内容（纯文字）
  bool isRead;                  // 是否已读
  DateTime? readAt;             // 阅读时间
  DateTime sentAt;              // 发送时间
  DateTime createdAt;           // 创建时间
}
```

### CommunityPost（社区帖子/树洞）
```dart
class CommunityPost {
  String id;                    // 帖子ID
  String userId;                // 发布者ID（后台记录，前台不显示）
  String recordId;              // 关联的记录ID
  DateTime timestamp;           // 错过的时间
  String? address;              // 地址（GPS 逆地理编码，标准地址）
  String? placeName;            // 地点名称（用户手动输入，无 GPS 时显示）
  PlaceType? placeType;         // 场所类型（可选）
  String? cityName;             // 城市名称（可选）
  String description;           // 描述
  List<TagWithNote> tags;       // 标签 + 备注（让被错过的人能认出自己）
  EncounterStatus status;       // 状态
  bool isAnonymous;             // 是否匿名（始终为 true）
  DateTime publishedAt;         // 发布时间
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}
```

**说明**：
- `CommunityPost` 是 `EncounterRecord` 的公开版本
- **不包含**：
  - 用户身份（完全匿名）
  - 精确 GPS 坐标（保护隐私）
- **包含**：
  - `address`：标准地址（GPS 获取），所有人都能理解
  - `placeName`：用户手动输入的地点名称（无 GPS 时显示）
  - `placeType`：场所类型（如"地铁"、"咖啡馆"），提供额外信息
  - 时间、描述、标签名称 + 备注（让被错过的人能认出自己）、状态
- `userId` 和 `recordId` 后台记录，用于管理

**为什么社区要显示标签备注？**
- 让信息足够详细，被错过的人才能认出"这是在说我"
- 如果只显示标签名称（如"长发""戴眼镜"），太泛了，很多人都符合
- 但如果显示备注（如"圆框眼镜，很文艺"），就能精确识别
- 四重防御机制（GPS + 时间 + 标签验证）已经足够防止骗子

**地点显示优先级**：
1. 优先显示：`placeType` + `address`（最标准）
2. 其次显示：`address`（标准地址）
3. 再次显示：`placeName`（用户输入，无 GPS 时）
4. 最后显示：`cityName` 或 "未知地点"

**地点显示优先级**（社区页面）：
```dart
/// 获取社区帖子的地点显示文本
String getCommunityPostLocation(CommunityPost post) {
  String result = '';
  
  // 第一部分：场所类型（如果有）
  if (post.placeType != null) {
    result = post.placeType!.label;  // 显示文字，如"地铁"、"咖啡馆"
  }
  
  // 第二部分：标准地址（如果有）
  if (post.address != null && post.address!.isNotEmpty) {
    if (result.isNotEmpty) {
      result += ' · ${post.address}';  // 场所类型 · 地址
    } else {
      result = post.address!;  // 只有地址
    }
  }
  
  // 第三部分：如果没有 GPS，尝试 placeName
  if (result.isEmpty && post.placeName != null && post.placeName!.isNotEmpty) {
    result = post.placeName!;  // 显示用户输入的地点名称
  }
  
  // 第四部分：如果都没有，尝试城市名称
  if (result.isEmpty && post.cityName != null && post.cityName!.isNotEmpty) {
    result = post.cityName!;
  }
  
  // 实在没有，显示默认文本
  if (result.isEmpty) {
    result = '未知地点';
  }
  
  return result;
}
```

**显示效果示例**：
- 有场所类型 + 地址：`地铁 · 北京市朝阳区建国门外大街1号`
- 有场所类型 + 地址：`咖啡馆 · 北京市朝阳区三里屯路19号`
- 只有地址：`北京市朝阳区建国门外大街1号`
- 只有场所类型：`地铁`
- 只有 placeName（无 GPS）：`常去的那家咖啡馆`
- 都没有：`未知地点`

### KeepInMemoryList（留在记忆里列表）
```dart
class KeepInMemoryList {
  String id;                    // 记录ID
  String userId;                // 用户ID
  String keptInMemoryUserId;    // 留在记忆里的用户ID
  String matchId;               // 关联的匹配ID（通过 Match 记录可以查到原因）
  DateTime createdAt;           // 创建时间
}
```

**说明**：
- 当用户选择"是的，这是我，但我选择让它留在记忆里，不联系"时，双方会被加入此列表
- 列表中的用户对永久不再匹配
- 用户无法手动解除（尊重拒绝方的意愿）
- 如果真的想联系，可以通过其他方式（线下、社交媒体等）
- 原因可以通过 `matchId` 查询 `Match` 记录获得（验证状态已说明原因）

### UserCreditScore（用户信用分）
```dart
class UserCreditScore {
  String id;                    // 记录ID
  String userId;                // 用户ID
  int score;                    // 当前信用分（初始100分）
  List<CreditChange> history;   // 信用分变更历史
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}
```

### CreditChange（信用分变更记录）
```dart
class CreditChange {
  CreditChangeReason reason;    // 变更原因
  int delta;                    // 变更值（正数=加分，负数=扣分）
  int scoreBefore;              // 变更前分数
  int scoreAfter;               // 变更后分数
  String? relatedId;            // 关联ID（如匹配ID、举报ID）
  DateTime changedAt;           // 变更时间
}
```

### CreditChangeReason（信用分变更原因枚举）
```dart
enum CreditChangeReason {
  gpsAnomalyDetected(1, 'GPS异常', -30),
  behaviorAnomalyDetected(2, '异常行为模式', -10),
  goodBehavior(3, '良好行为', 5),
  verificationSuccess(4, '验证成功', 10);

  final int value;
  final String label;
  final int defaultDelta;
  const CreditChangeReason(this.value, this.label, this.defaultDelta);
}
```

**信用分规则**：
- 初始分数：100分
- 信用分 < 0：禁止匹配功能
- 信用分 < 50：匹配频率限制更严格（每月1次）
- 信用分 ≥ 100：正常使用

### Membership（会员状态）
```dart
class Membership {
  String id;                    // 会员记录ID
  String userId;                // 用户ID
  MembershipTier tier;          // 会员等级
  MembershipStatus status;      // 会员状态
  DateTime? startedAt;          // 开通时间
  DateTime? expiresAt;          // 到期时间
  bool autoRenew;               // 是否自动续费
  double? monthlyAmount;        // 月付金额（用户自定义）
  List<PaymentRecord> paymentHistory;  // 支付历史
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}
```

### MembershipTier（会员等级枚举）
```dart
enum MembershipTier {
  free(1, '免费版'),
  premium(2, '会员版');

  final int value;
  final String label;
  const MembershipTier(this.value, this.label);
}
```

### MembershipStatus（会员状态枚举）
```dart
enum MembershipStatus {
  inactive(1, '未激活'),         // 从未开通过会员
  active(2, '活跃'),             // 会员有效期内
  expired(3, '已过期'),          // 会员已过期
  cancelled(4, '已取消');        // 用户主动取消

  final int value;
  final String label;
  const MembershipStatus(this.value, this.label);
}
```

### PaymentRecord（支付记录）
```dart
class PaymentRecord {
  String id;                    // 支付记录ID
  String userId;                // 用户ID
  String membershipId;          // 会员记录ID
  double amount;                // 支付金额（¥0-648）
  PaymentMethod method;         // 支付方式
  PaymentStatus status;         // 支付状态
  String? transactionId;        // 第三方支付平台的交易ID
  String? receiptData;          // 支付凭证数据（iOS IAP）
  DateTime? paidAt;             // 支付完成时间
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}
```

### PaymentMethod（支付方式枚举）
```dart
enum PaymentMethod {
  free(1, '免费解锁'),           // 用户选择¥0
  applePay(2, 'Apple Pay'),
  googlePay(3, 'Google Pay'),
  alipay(4, '支付宝'),
  wechatPay(5, '微信支付');

  final int value;
  final String label;
  const PaymentMethod(this.value, this.label);
}
```

### PaymentStatus（支付状态枚举）
```dart
enum PaymentStatus {
  pending(1, '待支付'),
  processing(2, '处理中'),
  success(3, '支付成功'),
  failed(4, '支付失败'),
  refunded(5, '已退款');

  final int value;
  final String label;
  const PaymentStatus(this.value, this.label);
}
```

### UserSettings（用户设置）
```dart
class UserSettings {
  String id;                    // 设置ID
  String userId;                // 用户ID
  
  // 主题设置
  AppTheme theme;               // 主题选择：light / dark / system / misty / midnight / warm / autumn
  String? accentColor;          // 强调色（会员专属）
  PageTransitionType pageTransition; // 页面切换动画类型
  
  // 隐私设置
  bool cloudSyncEnabled;        // 是否启用云同步（会员功能）
  bool biometricLockEnabled;    // 是否启用生物识别锁
  bool passwordLockEnabled;     // 是否启用密码锁
  String? passwordHash;         // 密码哈希（如果启用密码锁）
  List<String> hiddenRecordIds; // 隐藏的记录ID列表
  
  // 通知设置
  bool achievementNotification; // 成就解锁通知
  bool anniversaryReminder;     // 纪念日提醒（会员功能）
  bool locationReminder;        // 地点提醒（会员功能）
  bool matchNotification;       // 匹配通知
  bool messageNotification;     // 私信通知
  
  // 匹配设置
  bool matchingEnabled;         // 是否参与匹配（默认 true）
  bool gpsVerificationEnabled;  // 是否启用GPS验证（默认 true）
  
  // 社区设置
  bool autoPublishToCommunity;  // 是否自动发布到社区（默认 false）
  
  DateTime createdAt;           // 创建时间
  DateTime updatedAt;           // 更新时间
}
```

### AppTheme（应用主题枚举）
```dart
enum AppTheme {
  light(1, '浅色', false),           // 浅色模式（免费）
  dark(2, '深色', false),            // 深色模式（免费）
  system(3, '跟随系统', false),      // 跟随系统（免费）
  misty(4, '朦胧', true),            // 灰蓝色调（会员专属）
  midnight(5, '深夜', true),         // 深蓝黑色调（会员专属）
  warm(6, '温暖', true),             // 米黄色调（会员专属）
  autumn(7, '秋日', true);           // 橙棕色调（会员专属）

  final int value;
  final String label;
  final bool isPremium;              // 是否为会员专属
  const AppTheme(this.value, this.label, this.isPremium);
}
```

### PageTransitionType（页面切换动画类型枚举）
```dart
enum PageTransitionType {
  slideFromRight(1, '从右滑入', '类似 iOS'),
  slideFromBottom(2, '从底部滑入', '类似 Android'),
  slideFromLeft(3, '从左滑入', ''),
  slideFromTop(4, '从顶部滑入', ''),
  fade(5, '淡入淡出', ''),
  scale(6, '缩放', ''),
  rotation(7, '旋转', '');

  final int value;
  final String label;
  final String description;
  const PageTransitionType(this.value, this.label, this.description);
}
```

### User（用户）
```dart
class User {
  String id;                    // 用户ID
  String? email;                // 邮箱（可选）
  String? phoneNumber;          // 手机号（可选）
  String? displayName;          // 显示名称（可选）
  String? avatarUrl;            // 头像URL（可选）
  AuthProvider authProvider;    // 登录方式
  bool isEmailVerified;         // 邮箱是否验证
  bool isPhoneVerified;         // 手机号是否验证
  DateTime? lastLoginAt;        // 最后登录时间
  DateTime createdAt;           // 注册时间
  DateTime updatedAt;           // 更新时间
}
```

### AuthProvider（登录方式枚举）
```dart
enum AuthProvider {
  email(1, '邮箱'),
  phone(2, '手机号'),
  apple(3, 'Apple ID'),
  google(4, 'Google'),
  wechat(5, '微信');

  final int value;
  final String label;
  const AuthProvider(this.value, this.label);
}
```

---

## 📝 已确定的设计决策

### 1. 社交功能：树洞 + 隐藏匹配 ✅

**决策**：树洞模式 + 后台静默匹配

**树洞功能**：
- 用户可以匿名发布记录到社区
- 其他用户可以浏览，但无法互动
- 没有评论、点赞功能

**匹配功能**：
- 用户知道有匹配功能（产品营销卖点）
- 但后台静默运行，用户不知道"正在匹配中"，也不知道"匹配失败"
- 只在成功时推送通知
- 成功率：0.01%
- 五重防御机制：
  1. 对方也使用 Serendipity
  2. 对方也记录了那次错过
  3. 双方都将记录加入了故事线（技术要求）
  4. GPS 距离 < 200米 + 时间差 < 15分钟 + 地点名称模糊匹配
  5. 标签的双向验证（防骗核心）

**匹配流程**：
- 匹配成功 → 等待6小时冷静期 → 推送通知
- 双向验证（通过标签判断身份）
- 双方都确认 → 解锁私信（7天有效期）
- 任何一方拒绝 → 匹配失败

**产品哲学**：
- 相信奇迹，但不强求
- 主要功能：情感记录（99.99%）
- 匹配功能：奇迹匹配（0.01%）
- 用户知道有匹配功能，但不知道"正在匹配中"
- 如果根本没匹配上，不会收到通知；进入验证后失败，会温柔告知

**开发时间**：1.0 版本就做

---

### 2. 商业模式：自愿付费 ✅

**决策**：Pay What You Want（用户自定义金额）

**定价**：
- 月付制（无年付、无终身）
- 金额范围：¥0 - ¥648/月
- 默认值：¥1/月

**核心机制**：
- 用户可以选择 ¥0
- 但必须点击"支付"按钮（主动选择）
- ¥0 不调用支付 SDK，直接解锁
- > ¥0 调用支付 SDK

**理念**：
- 为爱发电
- 用户自愿支持
- 简单纯粹

---

### 3. 会员功能 ✅

**免费版**：
- 核心功能完整（记录、状态流转、时间轴、地图、社区）
- 本地存储
- 单设备
- 故事线限制：最多 3条

**会员版**：
- 云同步
- 多设备支持
- 无限故事线
- 标签词云图
- 高级主题
- 地图热力图
- 智能提醒

**不包含的功能**：
- ❌ 词云图导出与分享（已删除）
- ❌ 年度回顾视频（已删除）
- ❌ 生成纪念册 PDF（已删除）
- ❌ 数据导出 PDF/JSON（已删除）
- ❌ 无广告（本来就没广告）
- ❌ 优先客服（一人开发，无客服）

---

### 4. 用户登录与云同步 ✅

**决策**：从一开始就做登录 + 云同步

**技术方案**：Firebase
- Firebase Authentication（多种登录方式）
- Firestore（数据存储）
- Cloud Functions（业务逻辑）

**登录方式**：
- 邮箱 + 密码
- 手机号 + 验证码
- Apple ID（iOS）
- Google 账号
- 微信登录（国内版）

---

### 5. GPS 定位策略 ✅

**决策**：GPS 定位可选，但强烈建议开启

**原因**：
- GPS 是反欺诈的核心机制
- 但尊重用户隐私选择

**实现**：
- 首次记录时友好引导开启 GPS
- 拒绝 GPS 也能记录，但不参与社区匹配（如果将来做）
- GPS 坐标加密存储，不公开显示

---

### 6. 内容审核 ✅

**决策**：无人工审核，依赖技术过滤

**原因**：
- 一人开发，无审核团队

**实现**：
- 自动过滤敏感词汇
- 自动过滤联系方式
- 不提供举报功能（详见关于页面说明）

---

### 7. 产品定位 ✅

**Slogan**：
- "有些错过，只能被记住"
- "Serendipity - 记录那些错过的瞬间"

**核心价值**：
1. 情感宣泄：记录遗憾
2. 自我认知：了解自己的偏好
3. 情感共鸣：看到别人的错过，感受到"我不孤单"
4. 接受遗憾：学会与错过和解

---

**最后更新**：2026-02-13  
**文档版本**：v1.6  
**更新内容**：
- ✅ 修正"重逢"的定义：分开后再次相遇（需先经历"别离"）
- ✅ 修正状态流转规则：邂逅 → 别离 ⇄ 重逢（可循环）
- ✅ 明确产品定位：记录"错过"，邂逅后继续交往则不再记录
- ✅ 明确 Firebase Storage 暂不使用（后期如需头像上传功能再添加）
- ✅ 明确最低支持版本：Android 5.0+ / iOS 12.0+
- ✅ 明确标签备注字数限制：最多50字（可选）
- ✅ 明确词云图实现方式：先用标签频率列表，后期优化为词云可视化
- ✅ 删除成就解锁率功能
- ✅ 明确私信消息限制：每个对话每天10条
- ✅ 明确成就"咖啡馆邂逅"触发条件：5条邂逅状态记录
- ✅ 明确云同步方案：所有用户数据存 Firestore，免费版单设备登录
- ✅ 明确社区发布无 GPS 时显示 placeName
- ✅ 确认开发优先级：1.0 版本包含完整功能（Phase 1-4）
- ✅ 完善匹配逻辑：只有故事线中的记录参与匹配（五重防御）
- ✅ 完善匹配算法：按用户分组、选择最佳记录、去重检查
- ✅ 修正产品定位：故事线是技术要求（帮助程序识别同一个人），不是表达意愿
- ✅ 优化验证页面：展示所有候选记录，让用户选择"哪个是我"，避免误判
- ✅ 更新 Match 数据模型：使用 candidateRecordBIds 列表存储所有候选记录

