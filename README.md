# Kvant

Reactive UI library for Roblox. Windows, tabs, and a lot of elements with property-based handles and optional persistence.

```lua
local Kvant = loadstring(game:HttpGet("https://raw.githubusercontent.com/napHiwka/Kvant/refs/heads/main/src/init.luau"))()
```

## Small example

```lua
local Kvant = loadstring(game:HttpGet("https://raw.githubusercontent.com/napHiwka/Kvant/refs/heads/main/src/init.luau"))()

local speed = 0
local window = Kvant:CreateWindow({ Name = "Meow" })
window:Tab("Main", function(tab)
    local toggle = tab:Toggle("Toggle", false, function(on)
        -- callback fires on every change
    end)

    tab:Slider("Speed", 0, 500, 16, 1, function(v)
        speed = v
    end)

    toggle.Value = true -- read/write the handle
end)
```

---

## Window options

```lua
Kvant:CreateWindow({
    Name = "Meow",-- title bar text
    SideTabs = false, -- left-sided tab list
    Theme = "Darker",-- built-in name or custom table
    Font = "Roboto", -- "Roboto" | "Ubuntu" | "Inter"
    Icon = "kvant", -- icon name, asset id, or rbxassetid://
    ShowSearch = true, -- show search button
    AutoTabIcons = false, -- auto-guess icons from tab names
    PillCircle = false, -- round minimized pill (only icon)
    Globals = false, -- register constructors as globals
    -- Size, MinSize, MaxSize: UDim2 / Vector2
})
```

---

## Controls

All constructors are methods on a `tab` or `section` container. Each returns a handle.

| Constructor | Signature (positional) | Handle type |
|---|---|---|
| `Toggle` | `label, default, callback?, icon?, tooltip?, opts?` | `ToggleHandle` |
| `Slider` | `label, min, max, default, step, callback?, icon?, tooltip?, opts?` | `SliderHandle` |
| `Button` | `label, callback?, icon?, tooltip?, opts?` | `ButtonHandle` |
| `Dropdown` | `label, options, default, callback?, icon?, tooltip?, opts?` | `DropdownHandle` |
| `Keybind` | `label, default, callback?, icon?, tooltip?, opts?` | `KeybindHandle` |
| `Input` | `label, placeholder?, default?, callback?, icon?, tooltip?, opts?` | `InputHandle` |
| `Color` | `label, default?, callback?, icon?, tooltip?, opts?` | `ColorHandle` |
| `Textarea` | `label?, placeholder?, default?, callback?, icon?, tooltip?, opts?` | `TextareaHandle` |
| `Text` | `title?, content, icon?, tooltip?` | `TextHandle` |
| `Divider` | — | — |
| `Section` | `title, collapsed?, builder?` | `Section` (container) |

### Shared handle properties (all elements)

| Property | Type | R/W | Description |
|---|---|---|---|
| `.Label` | string | R/W | Row label text |
| `.Icon` | string? | R/W | Row icon |
| `.Tooltip` | string? | R/W | Hover tooltip |
| `.Locked` | boolean | R/W | Dims and blocks interaction |
| `.Instance` | Frame | R | Root Roblox instance |

### Element-specific properties

**Toggle** — `.Value: boolean`, `.Changed: Signal<boolean, fromUser: boolean>`

**Slider** — `.Value: number`, `.Min`, `.Max`, `.Step`, `.Suffix: string`, `.Dragging: boolean`, `.Changed: Signal<number, isDragging: boolean>`

**Button** — `.Activated: Signal<>`, `:Fire()` (trigger programmatically)

**Dropdown** — `.Value`, `.Options: {string}`, `.Open: boolean`, `.Multi: boolean`, `.Searchable: boolean`, `.Changed: Signal<value, fromUser>`

**Keybind** — `.Value: Enum.KeyCode?`, `.Listening: boolean`, `.Pressed: Signal<KeyCode>`, `.Changed: Signal<KeyCode?, fromUser>`

**Input** — `.Value: string`, `.Placeholder: string`, `.MaxLength: number`, `.DigitsOnly: boolean`, `.Changed: Signal<string, fromUser>`

**Color** — `.Value: Color3`, `.Hex: string`, `.Changed: Signal<Color3, fromUser>`

**Textarea** — `.Value: string`, `.Placeholder: string`, `.MaxLength: number`, `.Changed: Signal<string, fromUser>`

**Text** — `.Value: string` (body), `.Title: string?` (header, set `""` to hide)

**Section** — `.Open: boolean` (R/W, animates open/closed), `.Instance: Frame`, `.Header: TextButton`

---

## Element options (`opts` table)

| Field | Elements | Type | Default | Effect |
|---|---|---|---|---|
| `Id` | all | string | — | Stable persistence key (overrides label-based key) |
| `Locked` | all | boolean | false | Start in locked state |
| `Suffix` | Slider | string | `""` | Unit label after value |
| `Multi` | Dropdown | boolean | false | Allow multiple selections |
| `Searchable` | Dropdown | boolean | false | Add filter input |
| `MaxLength` | Input, Textarea | number | 0 (off) | Max character count |
| `DigitsOnly` | Input | boolean | false | Strip non-digit characters |

---

## Theming

```lua
Kvant:SetTheme("Dark") -- built-in: "Dark" | "Darker" | "Vesper" | "Light" | "SolarizedLight"
Kvant:SetTheme({ -- custom table
    Background = Color3.fromRGB(24, 24, 27),
    Secondary  = Color3.fromRGB(34, 34, 39),
    Accent     = Color3.fromRGB(34, 197, 94),
    Stroke     = Color3.fromRGB(50, 50, 58),
    Text       = Color3.fromRGB(245, 245, 247),
    SubText    = Color3.fromRGB(160, 160, 170),
    -- AccentText, Icon, IconMuted: auto-derived if omitted
})
Kvant:SetFont("Inter") -- "Roboto" | "Ubuntu" | "Inter" | Font object | asset id
```

Read: `Kvant:GetTheme()`, `Kvant:GetThemeNames()`, `Kvant:GetThemePreset(name)`.
Do not mutate `_theme` directly — changes won't propagate to open windows.

---

## Window API

```lua
window:Tab(title, icon?, builder?)  -- create a tab
window:Notify(text, duration?, icon?) -- toast notification
window:Status(opts?) -- floating key-value status widget frame
window:Destroy() -- destroy the window
```

### Status widget

```lua
local s = window:Status({ Title = "Stats", Position = UDim2.new(0, 20, 0.5, 0) })
s:Set("FPS", 60)
s:Get("FPS") -- "60"
s:Remove("FPS")
s:Clear()
s:Destroy()
```

---

## Icons

`Kvant.Icons` maps lowercase names to asset IDs. Pass any of:
- A name from `Kvant.Icons` (`"toggle"`, `"settings"`, `"color"`, …)
- A numeric asset ID string (`"107150227368485"`)
- A full URI (`"rbxassetid://107150227368485"`)

`AutoTabIcons = true` guesses an icon from the tab name automatically.

# License - MIT