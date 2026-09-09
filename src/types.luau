--!strict

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

export type WindowOptions = {
	Name: string?,
	SideTabs: boolean?,
	Theme: (string | Theme)?,
	Size: UDim2?,
	MinSize: Vector2?,
	MaxSize: Vector2?,
	Icon: string?,
	Builder: ((window: Window) -> ())?,
}

-- Control Handles
export type ToggleHandle = {
	Instance: Frame,
	Get: (self: ToggleHandle) -> boolean,
	Set: (self: ToggleHandle, val: boolean) -> (),
}

export type SliderHandle = {
	Instance: Frame,
	Get: (self: SliderHandle) -> number,
	Set: (self: SliderHandle, val: number) -> (),
}

export type DropdownHandle = {
	Instance: Frame,
	Get: (self: DropdownHandle) -> string | { string },
	Set: (self: DropdownHandle, val: string | { string }) -> (),
	Refresh: (self: DropdownHandle, newOptions: { string }) -> (),
}

export type KeybindHandle = {
	Instance: Frame,
	Get: (self: KeybindHandle) -> Enum.KeyCode?,
	Set: (self: KeybindHandle, key: (Enum.KeyCode | string)?) -> (),
}

export type InputHandle = {
	Instance: Frame,
	Get: (self: InputHandle) -> string,
	Set: (self: InputHandle, text: string) -> (),
}

export type ColorHandle = {
	Instance: Frame,
	Get: (self: ColorHandle) -> Color3,
	Set: (self: ColorHandle, color: Color3 | string | { R: number, G: number, B: number }) -> (),
}

export type ButtonHandle = {
	Instance: Frame,
	Fire: (self: ButtonHandle) -> (),
}

export type TextHandle = {
	Instance: Frame,
	Get: (self: TextHandle) -> string,
	Set: (self: TextHandle, content: string) -> (),
	SetTitle: (self: TextHandle, title: string) -> (),
}

export type DividerHandle = {
	Instance: Frame,
}

-- Container Definition (Tabs & Sections)
export type Container = {
	Section: (self: Container, text: string, collapsed: (boolean | (section: Section) -> ())?, builder: ((section: Section) -> ())?) -> Section,
	Divider: (self: Container) -> DividerHandle,
	Text: (self: Container, title: string, content: string, iconName: string?) -> TextHandle,
	Button: (self: Container, text: string, callback: (() -> ())?, iconName: string?) -> ButtonHandle,
	Toggle: (self: Container, text: string, default: boolean?, callback: ((state: boolean) -> ())?, iconName: string?) -> ToggleHandle,
	Slider: (self: Container, text: string, min: number?, max: number?, default: number?, step: (number | (val: number) -> ())?, callback: ((val: number) -> ())?, iconName: string?) -> SliderHandle,
	Dropdown: (self: Container, text: string, options: { string }?, callback: ((selected: any) -> ())?, default: (string | { string })?, iconName: string?) -> DropdownHandle,
	Keybind: (self: Container, text: string, default: Enum.KeyCode?, callback: ((key: Enum.KeyCode?) -> ())?, iconName: string?) -> KeybindHandle,
	Input: (self: Container, text: string, placeholder: (string | (val: string) -> ())?, callback: ((text: string) -> ())?, default: string?, iconName: string?) -> InputHandle,
	Color: (self: Container, text: string, default: (Color3 | (col: Color3) -> ())?, callback: ((color: Color3) -> ())?, iconName: string?) -> ColorHandle,
}

export type Section = Container & {
	Instance: Frame,
	Header: TextButton,
	SetCollapsed: (self: Section, state: boolean) -> (),
}

export type Tab = Container & {
	Instance: ScrollingFrame,
	Button: TextButton,
}

export type Window = {
	Tab: (self: Window, name: string, icon: (string | (tab: Tab) -> ())?, builder: ((tab: Tab) -> ())?) -> Tab,
	Notify: (self: Window, text: string, duration: number?) -> (),
	Destroy: (self: Window) -> (),
}

export type Library = {
	CurrentTheme: Theme,
	Themes: { [string]: Theme },
	Config: {
		Text: { Title: number, Label: number, Body: number, Small: number },
		Fonts: { Bold: Font, Medium: Font, Regular: Font, Icons: Font },
		Motion: { Fast: TweenInfo, Normal: TweenInfo, Panel: TweenInfo },
	},
	SetTheme: (self: Library, theme: string | Theme) -> (),
	SetFont: (self: Library, font: string | Font) -> (),
	CreateWindow: (self: Library, optOrName: WindowOptions | string, sideTabs: (boolean | (window: Window) -> ())?, customTheme: ((string | Theme) | (window: Window) -> ())?, customSize: UDim2?, iconId: (string | (window: Window) -> ())?) -> Window,

	-- Declarative Scope Functions
	Tab: (name: string, icon: (string | (tab: Tab) -> ())?, builder: ((tab: Tab) -> ())?) -> Tab,
	Section: (text: string, collapsed: (boolean | (section: Section) -> ())?, builder: ((section: Section) -> ())?) -> Section,
	Divider: () -> DividerHandle,
	Text: (title: string, content: string, iconName: string?) -> TextHandle,
	Button: (text: string, callback: (() -> ())?, iconName: string?) -> ButtonHandle,
	Toggle: (text: string, default: boolean?, callback: ((state: boolean) -> ())?, iconName: string?) -> ToggleHandle,
	Slider: (text: string, min: number?, max: number?, default: number?, step: (number | (val: number) -> ())?, callback: ((val: number) -> ())?, iconName: string?) -> SliderHandle,
	Dropdown: (text: string, options: { string }?, callback: ((selected: any) -> ())?, default: (string | { string })?, iconName: string?) -> DropdownHandle,
	Keybind: (text: string, default: Enum.KeyCode?, callback: ((key: Enum.KeyCode?) -> ())?, iconName: string?) -> KeybindHandle,
	Input: (text: string, placeholder: (string | (val: string) -> ())?, callback: ((text: string) -> ())?, default: string?, iconName: string?) -> InputHandle,
	Color: (text: string, default: (Color3 | (col: Color3) -> ())?, callback: ((color: Color3) -> ())?, iconName: string?) -> ColorHandle,
}

return {}