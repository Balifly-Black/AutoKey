# AutoKey 使用说明

[English README](README_EN.md)

AutoKey 是一个 Windows 键盘/鼠标自动化软件。你可以用基础模式快速录入按键序列，也可以用高级模式编写 Lua 脚本，根据按键、截图和取色结果执行自动化操作。

## 快速开始

1. 以管理员权限启动 AutoKey，首次使用虚拟键鼠驱动时尤其需要这样做。
2. 在“控制台”页面新建或选择一个配置。
3. 选择“基础模式”或“高级模式”。
4. 设置触发键、运行模式和循环间隔。
5. 启用配置，然后点击启动引擎。
6. 按下你设置的物理触发键，让脚本开始或停止运行。

基础模式适合简单的循环按键。高级模式适合需要条件判断、计时、图像识别、取色判断或组合键操作的场景。

## 基础模式

基础模式不需要手写脚本。你只需要在界面里选择要点击的键盘按键或鼠标按键，AutoKey 会自动生成脚本。

基础模式生成的脚本大致等价于：

```lua
function main()
    dd_click("a", 1)
    dd_click("left", 1)
end
```

其中 `main()` 会按配置的循环间隔反复执行。基础模式更适合固定顺序的动作，例如持续点击、循环释放技能、按键连发。

## 高级模式脚本规则

高级模式脚本必须定义 `main()` 函数：

```lua
function main()
    dd_click("a", 10)
end
```

引擎启动后，每轮循环都会调用一次 `main()`。循环间隔由配置里的延迟决定。建议让 `main()` 尽快返回，把长时间等待拆成状态判断或短 `sleep()`，这样停止脚本时更灵敏。

脚本可以定义全局变量保存状态：

```lua
count = count or 0

function main()
    count = count + 1
    if count % 10 == 0 then
        print("运行次数", count)
    end
end
```

## 常用键鼠 API

所有驱动 API 都会返回 `true` 或 `false`，表示本次动作是否发送成功。

| 函数 | 说明 |
| --- | --- |
| `dd_click(keyOrButton, intervalMs)` | 自动点击键盘键或鼠标键。可传键名、鼠标键名或 HID 数值。 |
| `dd_key_clk(usage, intervalMs)` | 点击一个键盘 HID Usage ID。 |
| `dd_btn_clk(button, intervalMs)` | 点击一个鼠标按键。 |
| `dd_key(usage, down)` | 键盘按下或松开，`down=1` 按下，`down=0` 松开。 |
| `dd_btn(button, down)` | 鼠标按下或松开，`down=1` 按下，`down=0` 松开。 |
| `dd_mova(x, y)` | 鼠标移动到屏幕绝对坐标。 |
| `dd_movr(dx, dy)` | 鼠标相对当前位置移动。 |
| `dd_whl(delta)` | 滚轮滚动，正数向上，负数向下。 |
| `dd_str(text)` | 输入可见字符文本。 |
| `sleep(ms)` | 暂停指定毫秒数。 |
| `print(...)` | 输出到日志面板。 |

鼠标按键编号：

| 编号 | 按键 |
| --- | --- |
| `1` | 左键 |
| `2` | 右键 |
| `3` | 中键 |
| `4` | XButton1 |
| `5` | XButton2 |

示例：点击和移动

```lua
function main()
    dd_click("a", 10)
    dd_click("left", 10)
    dd_movr(20, 0)
end
```

示例：组合键

```lua
function main()
    dd_key(0xE0, 1)      -- Left Ctrl 按下
    dd_key_clk(0x06, 10) -- C
    dd_key(0xE0, 0)      -- Left Ctrl 松开
end
```

示例：输入文本

```lua
function main()
    dd_str("AutoKey")
    dd_key_clk(0x28, 10) -- Enter
end
```

## 常用键名和 HID 编码

`dd_click()` 可以直接使用常见键名，例如：

```lua
dd_click("a", 10)
dd_click("space", 10)
dd_click("enter", 10)
dd_click("left", 10) -- 鼠标左键
```

`dd_key()` 和 `dd_key_clk()` 使用 USB HID Usage ID。常用编码如下：

| 按键 | HID |
| --- | --- |
| A-Z | `0x04` 到 `0x1D` |
| 1-0 | `0x1E` 到 `0x27` |
| Enter | `0x28` |
| Esc | `0x29` |
| Backspace | `0x2A` |
| Tab | `0x2B` |
| Space | `0x2C` |
| F1-F12 | `0x3A` 到 `0x45` |
| Left Ctrl | `0xE0` |
| Left Shift | `0xE1` |
| Left Alt | `0xE2` |
| Left Win | `0xE3` |
| Right Ctrl | `0xE4` |
| Right Shift | `0xE5` |
| Right Alt | `0xE6` |
| Right Win | `0xE7` |

## keys 表

高级模式可以在脚本里声明 `keys` 表，让界面为这些槽位绑定实际按键。运行时，AutoKey 会把槽位替换成对应的 HID 或鼠标按钮编号。

```lua
keys = {
    attack = 0,
    jump = 0
}

function main()
    dd_click(keys.attack, 10)
    dd_click(keys.jump, 10)
end
```

适合把脚本逻辑和实际键位分开：脚本只写 `attack`、`jump`，实际绑定在界面里改。

## toggles 表

高级模式可以声明 `toggles` 表，让界面为布尔开关绑定物理按键。按下绑定键后，对应值会在 `true` 和 `false` 之间切换。

```lua
toggles = {
    burst = false
}

function main()
    if toggles.burst then
        dd_click("a", 10)
        dd_click("b", 10)
    end
end
```

适合做“脚本运行中临时开关某一段逻辑”的功能，例如爆发模式、暂停某个技能、切换不同动作组。

## 图片识别 image 表

在高级模式脚本中声明 `image` 表后，界面会为每个槽位提供截图绑定。引擎会持续扫描识别区域，并把结果写回对应子表。

```lua
image = {
    ready = {}
}

function main()
    if image.ready["存在"] then
        dd_click("f", 10)
    end
end
```

图片槽位常用字段：

| 字段 | 说明 |
| --- | --- |
| `path` | 绑定截图文件路径，由软件注入。 |
| `存在` | 是否识别到该图片。 |
| `出现时间` | 当前连续识别到的秒数，未出现时通常为 `-1`。 |
| `消失时间` | 最近一次消失后经过的秒数，未消失或正在出现时通常为 `-1`。 |
| `x` / `y` | 识别到图片时的中心点屏幕坐标。 |

示例：图片出现 0.5 秒后点击中心点

```lua
image = {
    button = {}
}

function main()
    local btn = image.button
    if btn["存在"] and btn["出现时间"] > 0.5 and btn.x and btn.y then
        dd_mova(btn.x, btn.y)
        dd_click("left", 10)
    end
end
```

也可以使用兼容函数 `rec_ima(image.button)`，返回值为：

```lua
local found, appearTime, disappearTime, x, y = rec_ima(image.button)
```

## 取色识别 pixel 表

在高级模式脚本中声明 `pixel` 表后，界面会为每个槽位提供取点绑定。引擎会持续比较该点颜色，并把结果写回对应子表。

```lua
pixel = {
    hp_low = {}
}

function main()
    if pixel.hp_low["存在"] then
        dd_click("q", 10)
    end
end
```

取色槽位常用字段：

| 字段 | 说明 |
| --- | --- |
| `x` / `y` | 取色点屏幕坐标，由软件注入。 |
| `color` | 期望颜色，由软件注入。 |
| `存在` | 当前像素是否匹配期望颜色。 |
| `出现时间` | 当前连续匹配的秒数。 |
| `消失时间` | 最近一次不匹配后经过的秒数。 |

也可以使用兼容函数 `rec_pix(pixel.hp_low)`，返回值为：

```lua
local found, appearTime, disappearTime, x, y = rec_pix(pixel.hp_low)
```

## 计时器

AutoKey 提供三个命名计时器函数：

| 函数 | 说明 |
| --- | --- |
| `settimer(name)` | 创建或重置计时器。 |
| `gettimer(name)` | 获取经过秒数。不存在时返回很大的数。 |
| `deltimer(name)` | 删除计时器。 |

示例：每 2 秒执行一次

```lua
function main()
    if gettimer("cast") > 2 then
        dd_click("e", 10)
        settimer("cast")
    end
end
```

## 完整示例

```lua
keys = {
    attack = 0,
    heal = 0
}

toggles = {
    auto_attack = true
}

image = {
    enemy = {}
}

pixel = {
    hp_low = {}
}

function main()
    if pixel.hp_low["存在"] then
        dd_click(keys.heal, 10)
        sleep(100)
        return
    end

    if toggles.auto_attack and image.enemy["存在"] then
        if gettimer("attack") > 0.8 then
            dd_click(keys.attack, 10)
            settimer("attack")
        end
    end
end
```

## 使用建议

- 先用 `print()` 确认脚本逻辑，再加入真实点击。
- 组合键一定要成对按下和松开，避免按键卡住。
- 图片和取色识别依赖屏幕状态，运行前先确认识别区域、截图和颜色槽位。
- 尽量不要在 `main()` 里写很长的死循环；AutoKey 本身已经会循环调用 `main()`。
- 自动化会影响当前前台窗口，请先确认目标窗口和触发键。
