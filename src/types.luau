--!strict

export type Connection = {
    Disconnect: (self: Connection) -> (),
}

export type Signal<T...> = {
    Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
    Fire: (self: Signal<T...>, T...) -> (),
}

export type Theme = {
    Background: Color3,
    Secondary: Color3,
    Accent: Color3,
    Stroke: Color3,
    Text: Color3,
    SubText: Color3,
    AccentText: Color3?,
    Icon: Color3?,
    IconMuted: Color3?,
}

export type ElementOptions = {
    Id: string?,
    Locked: boolean?,
}

export type SliderOptions = ElementOptions & {
    Suffix: string?,
}

export type DropdownOptions = ElementOptions & {
    Multi: boolean?,
    Searchable: boolean?,
}

export type InputOptions = ElementOptions & {
    MaxLength: number?,
    DigitsOnly: boolean?,
}

export type TextareaOptions = ElementOptions & {
    MaxLength: number?,
}

export type WindowOptions = {
    Name: string?,
    SideTabs: boolean?,
    Theme: (string | Theme)?,
    Font: (string | Font)?,
    Size: UDim2?,
    MinSize: Vector2?,
    MaxSize: Vector2?,
    Icon: string?,
    Dev: boolean?,
    ShowSearch: boolean?,
    AutoIcons: boolean?,
    Pill: string?,
    PillStyle: string?,
    PillCircle: boolean?,
    PillIcon: string?,
    Globals: boolean?,
    Secure: boolean?,
    Builder: ((window: Window) -> ())?,
}

export type StatusOptions = {
    Title: string?,
    Size: UDim2?,
    Position: UDim2?,
    Transparency: number?,
}

export type StatusHandle = {
    Set: (self: StatusHandle, key: string, value: any) -> (),
    Get: (self: StatusHandle, key: string) -> string?,
    Remove: (self: StatusHandle, key: string) -> (),
    Clear: (self: StatusHandle) -> (),
    Content: (self: StatusHandle, builder: (any) -> ()) -> (),
    Destroy: (self: StatusHandle) -> (),
}

export type BaseHandle = {
    Instance: Frame,
    Label: string,
    Icon: string?,
    Tooltip: string?,
    Locked: boolean,
}

export type ButtonHandle = BaseHandle & {
    Activated: Signal<()>,
    Fire: (self: ButtonHandle) -> (),
}

export type ToggleHandle = BaseHandle & {
    Value: boolean,
    Changed: Signal<boolean, boolean>,
}

export type SliderHandle = BaseHandle & {
    Value: number,
    Min: number,
    Max: number,
    Step: number,
    Dragging: boolean,
    Suffix: string,
    Changed: Signal<number, boolean>,
}

export type DropdownHandle = BaseHandle & {
    Value: any,
    Options: { string },
    Open: boolean,
    Multi: boolean,
    Searchable: boolean,
    Changed: Signal<any, boolean>,
}

export type KeybindHandle = BaseHandle & {
    Value: Enum.KeyCode?,
    Listening: boolean,
    Pressed: Signal<Enum.KeyCode>,
    Changed: Signal<Enum.KeyCode?, boolean>,
}

export type InputHandle = BaseHandle & {
    Value: string,
    Placeholder: string,
    MaxLength: number,
    DigitsOnly: boolean,
    Changed: Signal<string, boolean>,
}

export type ColorHandle = BaseHandle & {
    Value: Color3,
    Hex: string,
    Changed: Signal<Color3, boolean>,
}

export type TextareaHandle = BaseHandle & {
    Value: string,
    Placeholder: string,
    MaxLength: number,
    Changed: Signal<string, boolean>,
}

export type TextHandle = {
    Instance: Frame,
    Value: string,
    Title: string?,
    Icon: string?,
    Tooltip: string?,
}

export type DividerHandle = {
    Instance: Frame,
}

export type Container = {
    Section: (self: Container, title: string, collapsed: (boolean | (section: Section) -> ())?, bld: ((section: Section) -> ())?) -> Section,
    Divider: (self: Container) -> DividerHandle,
    Text: (self: Container, title: string, content: string?, icon: string?, tooltip: string?) -> TextHandle,
    Button: (self: Container, label: string, callback: (() -> ())?, icon: string?, tooltip: string?, opts: ElementOptions?) -> ButtonHandle,
    Toggle: (self: Container, label: string, default: boolean?, callback: ((state: boolean, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: ElementOptions?) -> ToggleHandle,
    Slider: (self: Container, label: string, min: number?, max: number?, default: number?, step: (number | ((val: number, dragging: boolean) -> ()))?, callback: ((val: number, dragging: boolean) -> ())?, icon: string?, tooltip: string?, opts: SliderOptions?) -> SliderHandle,
    Dropdown: (self: Container, label: string, options: { string }?, default: (any | { any })?, callback: ((val: any, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: DropdownOptions?) -> DropdownHandle,
    Keybind: (self: Container, label: string, default: Enum.KeyCode?, callback: ((key: Enum.KeyCode) -> ())?, icon: string?, tooltip: string?, opts: ElementOptions?) -> KeybindHandle,
    Input: (self: Container, label: string, placeholder: string?, default: string?, callback: ((val: string, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: InputOptions?) -> InputHandle,
    Color: (self: Container, label: string, default: any?, callback: ((col: Color3, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: ElementOptions?) -> ColorHandle,
    Textarea: (self: Container, label: string?, placeholder: string?, default: string?, callback: ((val: string, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: TextareaOptions?) -> TextareaHandle,
}

export type Section = Container & {
    Instance: Frame,
    Header: TextButton,
    Open: boolean,
}

export type Tab = Container & {
    Instance: ScrollingFrame,
    TabButton: TextButton,
}

export type Window = {
    Tab: (self: Window, title: string, icon: (string | ((tab: Tab) -> ()))?, tabBuilder: ((tab: Tab) -> ())?) -> Tab,
    Status: (self: Window, statusOpt: StatusOptions?) -> StatusHandle,
    Notify: (self: Window, text: string, duration: number?, icon: string?) -> (),
    Destroy: (self: Window) -> (),
}

export type Library = {
    GetTheme: (self: Library) -> Theme,
    GetThemeNames: (self: Library) -> { string },
    GetThemePreset: (self: Library, name: string) -> Theme?,
    SetTheme: (self: Library, theme: string | Theme) -> (),
    SetFont: (self: Library, font: string | Font) -> (),
    CreateWindow: (self: Library, opt: WindowOptions?) -> Window,

    Tab: (title: string, icon: (string | ((tab: Tab) -> ()))?, tabBuilder: ((tab: Tab) -> ())?) -> Tab,
    Section: (title: string, collapsed: (boolean | (section: Section) -> ())?, bld: ((section: Section) -> ())?) -> Section,
    Divider: () -> DividerHandle,
    Text: (title: string, content: string?, icon: string?, tooltip: string?) -> TextHandle,
    Button: (label: string, callback: (() -> ())?, icon: string?, tooltip: string?, opts: ElementOptions?) -> ButtonHandle,
    Toggle: (label: string, default: boolean?, callback: ((state: boolean, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: ElementOptions?) -> ToggleHandle,
    Slider: (label: string, min: number?, max: number?, default: number?, step: (number | ((val: number, dragging: boolean) -> ()))?, callback: ((val: number, dragging: boolean) -> ())?, icon: string?, tooltip: string?, opts: SliderOptions?) -> SliderHandle,
    Dropdown: (label: string, options: { string }?, default: (any | { any })?, callback: ((val: any, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: DropdownOptions?) -> DropdownHandle,
    Keybind: (label: string, default: Enum.KeyCode?, callback: ((key: Enum.KeyCode) -> ())?, icon: string?, tooltip: string?, opts: ElementOptions?) -> KeybindHandle,
    Input: (label: string, placeholder: string?, default: string?, callback: ((val: string, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: InputOptions?) -> InputHandle,
    Color: (label: string, default: any?, callback: ((col: Color3, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: ElementOptions?) -> ColorHandle,
    Textarea: (label: string?, placeholder: string?, default: string?, callback: ((val: string, fromUser: boolean) -> ())?, icon: string?, tooltip: string?, opts: TextareaOptions?) -> TextareaHandle,
}

return {}