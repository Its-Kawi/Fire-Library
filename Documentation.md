# Fire Library — Complete Usage Documentation

**Fire Library** is a Roblox/Luau UI library that builds windows, tabs, groupboxes, controls, notifications, theme tools, and localization into a single interface. This guide is based on the repository README and the current `Files/Library.lua` source available in the project's `main` branch.

- Repository: <https://github.com/Its-Kawi/Fire-Library>
- README: <https://github.com/Its-Kawi/Fire-Library/blob/main/README.md>
- Main source: <https://github.com/Its-Kawi/Fire-Library/blob/main/Files/Library.lua>

> **Version note:** the repository is a moving target. When an API detail is important to a release, check the source file you actually ship, not only this guide. The source contains compatibility helpers and some options that are environment-dependent.

## Contents

1. [What the library provides](#what-the-library-provides)
2. [Installation and loading](#installation-and-loading)
3. [The object model](#the-object-model)
4. [Your first window](#your-first-window)
5. [Windows](#windows)
6. [Tabs, headers, and groupboxes](#tabs-headers-and-groupboxes)
7. [Controls](#controls)
   - [Buttons](#buttons)
   - [Toggles and checkboxes](#toggles-and-checkboxes)
   - [Sliders](#sliders)
   - [Dropdowns](#dropdowns)
   - [Text boxes](#text-boxes)
   - [Keybind inputs](#keybind-inputs)
   - [Labels and separators](#labels-and-separators)
   - [Color pickers](#color-pickers)
8. [Notifications and confirmation prompts](#notifications-and-confirmation-prompts)
9. [Themes and visual customization](#themes-and-visual-customization)
10. [Localization](#localization)
11. [Configs and share strings](#configs-and-share-strings)
12. [Floating labels](#floating-labels)
13. [Dynamic controls and object properties](#dynamic-controls-and-object-properties)
14. [Advanced tips and practical patterns](#advanced-tips-and-practical-patterns)
15. [Troubleshooting](#troubleshooting)
16. [Quick API reference](#quick-api-reference)

---

## What the library provides

The README advertises a UI system with:

- Windows and tabs, with left/right groupboxes for organising controls.
- Buttons, toggles, checkboxes, sliders, dropdowns, text boxes, keybind setters, labels, separators, and color pickers.
- Notifications, confirmation-style in-window prompts, tooltips, and floating labels.
- Theme editing, visual effects, configurable animation speed, and language translations.
- Desktop/mobile-aware layout behavior.
- Config/theme persistence and share-string functions where the active runtime supports the required capabilities.

Not every capability is guaranteed in every runtime. File persistence, clipboard operations, remote fetching, and some effects depend on the functions provided by the environment. For a normal Roblox experience, prefer a ModuleScript setup and test the UI in Studio and on the devices you support.

## Installation and loading

### Option A — Use the library from a Roblox experience

1. Open the repository and locate `Files/Library.lua`.
2. Follow the packaging instructions in the repository README to put the library into a `ModuleScript` in your own experience. The README's instructions include the module-return line needed by its generated source.
3. Place the ModuleScript somewhere the client script can access, commonly `ReplicatedStorage` for a client-side UI module.
4. Require that module from a `LocalScript` and create a window.

Example assuming the packaged module is named `FireLibrary` and is a child of `ReplicatedStorage`:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fire = require(ReplicatedStorage:WaitForChild("FireLibrary"))

local window = Fire:Window({
    Text = "My Interface",
})

local tab = window:AddTab({ Text = "Home", Icon = "Home" })
tab:AddLabel({ Text = "Fire Library is ready." })
```

If `require()` does not return the library table, review the module packaging step and the final return statement in the exact `Library.lua` file you copied.

### Option B — Use the repository loader

The README also documents this loader pattern:

```lua
local Fire = loadstring(game:HttpGet("https://raw.githubusercontent.com/Its-Kawi/Fire-Library/refs/heads/main/Loader.lua"))()
local window = Fire:Window({ Text = "My Interface" })
```

The repository's `Loader.lua` comments explicitly describe it as intended for exploit-style runtimes, not as a regular Roblox Studio script. Such runtimes may supply nonstandard functions, and remote code can change when the branch changes. Only run code you trust, review the version you intend to use, and do not place passwords, tokens, or other secrets in UI scripts.

---

## The object model

A typical UI has this hierarchy:

```text
Fire (library table)
└── Window
    ├── Tab
    │   ├── Left Groupbox
    │   │   ├── Label
    │   │   ├── Button
    │   │   └── Toggle
    │   └── Right Groupbox
    │       ├── Slider
    │       └── Dropdown
    └── Another Tab
```

The important rule is: **save the return value from each creation method**. It is the handle you can use later to update that control or build child controls.

```lua
local tab = window:AddTab({ Text = "Main" })
local group = tab:AddLeftGroupbox({ Text = "Settings" })
local enabledToggle = group:AddToggle({ Text = "Enabled" })
```

Most controls accept an options table. The usual properties are:

| Property | Meaning |
|---|---|
| `Text` | Text shown beside or inside the control. |
| `Tooltip` | Help text shown on hover where supported. |
| `Visible` | Whether the object should be shown. Defaults are usually `true`. |
| `Disabled` | Whether user interaction is disabled where supported. |
| `Order` | Optional ordering value for arranging controls. |
| `Translations` | Per-language text overrides. |
| `Callback` | Function called when the control's value/action changes. |
| `NoConfigs` | Excludes supported controls from config serialization when set to `true`. |

A control may have additional options specific to its type. Use the sections below for those.

### Named controls and flags

Many creation methods accept either an options table or a stable name followed by an options table. Both forms appear in the repository source:

```lua
local toggle = group:AddToggle("EnableFeature", {
    Text = "Enable feature",
    Value = false,
})
```

Use meaningful, stable names for controls whose state you want to save and restore in configs. Treat names/flags as identifiers: changing them can stop existing saved config entries from matching the intended control. For simple one-off controls, the options-table-only form is enough.

## Your first window

This example creates two tabs and several common controls. It deliberately keeps UI creation separate from the functions that do the actual work.

```lua
local Fire = require(game:GetService("ReplicatedStorage"):WaitForChild("FireLibrary"))

local window = Fire:Window({
    Text = "Demo Panel",
    Footer = "Built with Fire Library",
    Keybind = Enum.KeyCode.RightShift,
    Language = "EN",
    UserProfile = false,
})

local mainTab = window:AddTab({ Text = "Main", Icon = "Home" })
local settingsTab = window:AddTab({ Text = "Settings", Icon = "Settings" })

local mainBox = mainTab:AddLeftGroupbox({ Text = "Controls" })

local enabled = mainBox:AddToggle("Enabled", {
    Text = "Enable feature",
    Value = false,
    Tooltip = "Turns the feature on or off.",
    Callback = function(value)
        print("Enabled:", value)
    end,
})

mainBox:AddButton({
    Text = "Run action",
    Icon = "Cursor",
    Callback = function()
        print("Button activated")
    end,
})

mainBox:AddSlider("Volume", {
    Text = "Volume",
    Min = 0,
    Max = 100,
    Step = 5,
    Value = 50,
    Callback = function(value)
        print("Volume:", value)
    end,
})

local modes = { "Quiet", "Balanced", "Fast" }
mainBox:AddDropdown("Mode", {
    Text = "Mode",
    Options = modes,
    Value = 2,
    Callback = function(value)
        print("Selected mode:", value)
    end,
})

local settingsBox = settingsTab:AddRightGroupbox({ Text = "Profile" })
settingsBox:AddTextBox("PlayerName", {
    Text = "Display name",
    PlaceholderText = "Enter a name",
    Value = "Guest",
    Callback = function(text)
        print("Name committed:", text)
    end,
})

settingsBox:AddLabel({ Text = "Changes apply when their callbacks run." })

window:Notification({
    Title = "Ready",
    Text = "The interface was created successfully.",
    Duration = 4,
})
```

The exact icon set depends on the icons bundled with the library. If an icon string does not resolve, try one already used by the repository's own UI or omit `Icon`.

---

## Windows

Create a window with `Fire:Window(options)`.

### Common window options

| Option | Use |
|---|---|
| `Text` | Main window title. The source also has a fallback path for `Title`; prefer `Text` for consistency. |
| `Title` | Compatibility/fallback title field. |
| `Footer` | Optional footer text. |
| `Icon` | Optional icon identifier. |
| `Keybind` | Key used for the window's main toggle behavior. Source default is `Enum.KeyCode.LeftAlt`. |
| `Visible` | Initial visibility. |
| `Language` | Active language code; the implementation normalizes to the first two letters in uppercase (for example, `EN` or `RU`). |
| `Translations` | Window-level translations and translation mappings for child objects. |
| `UserProfile` | Enables/disables the profile display area. |
| `AnimationSpeed` | Controls animation speed. Larger values generally mean faster transitions in this library. |
| `NotificationSide` | Default notification side, usually `"Left"` or `"Right"`. |
| `BlurBackground` | Enables supported background blur effects. Availability can vary. |
| `Image`, `ImageEnabled`, `ImageColor`, `ImageTransparency` | Background image settings. |
| `Theme` | Theme color table. The standard keys used by the source are `Main`, `Back`, `Stroke`, and `Text`. |
| `NoStrokes`, `RoundEverything` | Visual styling switches. |
| `MobileButtonVisible`, `MobileButtonAlwaysVisible` | Options related to the floating/mobile UI toggle button. |
| `OnClose` | Function intended to run as part of close handling. |

Minimal setup:

```lua
local window = Fire:Window({
    Text = "Tools",
    Keybind = Enum.KeyCode.RightShift,
    Visible = true,
})
```

### Window methods

| Method | Purpose |
|---|---|
| `window:AddTab(options)` | Creates a normal tab. |
| `window:AddCustomTab(options)` | Creates a custom tab object for app-defined state. See the custom-tab note below. |
| `window:AddHeader(options)` | Adds a header/separator-style heading in the tab navigation area. |
| `window:Toggle()` | Switches window visibility. |
| `window:Show()` | Shows the window. |
| `window:Hide()` | Hides the window. |
| `window:TryClose()` | Shows a confirmation prompt before closing. |
| `window:Close()` | Closes the window. |
| `window:Refresh()` | Refreshes theme/layout-derived appearance. |
| `window:RefreshAll()` | Rebuilds/refreshes all relevant UI objects. Use sparingly rather than after every value update. |
| `window:Notification(options)` | Shows a toast notification. `Notify` is also available as an alias. |
| `window:WindowNotification(options)` | Shows an in-window notification/prompt. `InWindowNotification` is an alias. |
| `window:SetTheme(themeData)` / `window:GetTheme()` | Applies/reads the library's serialized theme representation. |
| `window:SetConfig(configData)` / `window:GetConfig()` | Applies/reads serializable control state. |
| `window:SetThemeString(text)` / `window:GetThemeString()` | Applies/exports a theme share string. |
| `window:SetConfigString(text)` / `window:GetConfigString()` | Applies/exports a config share string. |

**Custom tabs:** `AddCustomTab` is intended for tab-like state not limited to ordinary controls. Its object has a value and a `ConfigSet` event. For normal controls and layouts, use `AddTab`.

---

## Tabs, headers, and groupboxes

### Tabs

```lua
local tab = window:AddTab({
    Text = "Movement",
    Icon = "Home",
    Tooltip = "Movement settings",
    Visible = true,
    Order = 1,
    Translations = {
        EN = "Movement",
        RU = "Движение",
    },
})
```

A tab can have groupboxes and regular controls directly. For a clean layout, groupboxes are usually easier to scan once a tab has several controls.

`tab:SwitchTo()` switches to that tab. Tab options include `Text`, `Icon`, `Image`, `Tooltip`, `DisabledTooltip`, `Visible`, `Order`, `RecolorIcon`, and `Translations`.

### Groupboxes

Three commonly used methods create a groupbox:

```lua
local anySide = tab:AddGroupbox({ Text = "General", Side = "Left" --[[or "Right"]] })
local left = tab:AddLeftGroupbox({ Text = "General" })
local right = tab:AddRightGroupbox({ Text = "Advanced" })
```

Use left and right groupboxes to create two columns on wider layouts. On compact devices, test the final UI because the layout adapts to the detected device. Groupbox options include `Text`, `Side`, `Visible`, `Order`, and `Translations`.

### Headers and separators

```lua
window:AddHeader({ Text = "General settings" })
left:AddSeparator()
left:AddSeparator({ Invisible = true })
```

`Invisible = true` keeps a spacing separator while hiding its visible line. For longer tabs, headers and separators help create visual sections without adding extra windows.

---

## Controls

Controls are created on a tab or groupbox using `Add...` methods. Most return an object with a `Set()` method, an `Options` table, and commonly a `Value` property. Callback behavior is control-specific, so consult the details below.

### Buttons

```lua
local button = group:AddButton({
    Text = "Refresh data",
    Icon = "Refresh",
    Tooltip = "Fetches the latest local data.",
    Disabled = false,
    Visible = true,
    Callback = function()
        print("Refresh requested")
    end,
})
```

Options worth knowing:

- `Text`, `Icon`, `Callback`, `Visible`, `Disabled`, `Tooltip`, `DisabledTooltip`, `Order`, `Translations`.
- `Holdable = true` enables the button's hold-style behavior where supported.
- `RecolorIcon` controls whether the icon follows the library's accent styling.

A button callback is an action: it is not a state value. Keep the callback short; defer expensive calculations or data processing so the UI remains responsive.

### Toggles and checkboxes

Toggles represent an on/off value. Use `Value` for the initial state and `Callback` to react to changes.

```lua
local toggle = group:AddToggle("AutoRefresh", {
    Text = "Auto refresh",
    Value = false,
    Callback = function(enabled)
        print("Auto refresh:", enabled)
    end,
})

toggle:Set(true)  -- set programmatically
print(toggle.Value) -- inspect the current value
```

The checkbox form is also available:

```lua
local checkbox = group:AddCheckBox("ShowHints", {
    Text = "Show hints",
    Value = true,
    Callback = function(checked)
        print("Show hints:", checked)
    end,
})
```

The source uses `AddCheckBox`/`AddCheckbox`-style aliases through its shared methods; `AddCheckBox` is the spelling shown in the implementation. Toggles support `Text`, `Value`, `Callback`, `Visible`, `Disabled`, `Tooltip`, `DisabledTooltip`, `NoConfigs`, `Order`, and `Translations`. The toggle also supports `CheckBox` as a display-style option in the implementation.

**Lifehack:** store the toggle object rather than copying its value into a second variable. The control is the UI state source; use its callback to synchronize the rest of your script.

### Sliders

Sliders let the user choose a numeric value over a range.

```lua
local slider = group:AddSlider("Opacity", {
    Text = "Opacity",
    Min = 0,
    Max = 100,
    Step = 5,
    Value = 50,
    Format = "+",
    Callback = function(value)
        print("Opacity:", value)
    end,
})

slider:Set(75)
```

| Option | Meaning |
|---|---|
| `Min` / `Max` | The numeric lower/upper bounds. |
| `Value` | Starting value. Alisas for that is `Default` |
| `Step` | Increment used for selecting values. Use `1` for integer steps or a decimal such as `0.1` for finer steps. Some built-in controls use `0` for continuous/proportional behavior. |
| `Format` | Built-in display format or a custom formatter function, depending on the source version. Common source examples include `"/"`, `"+"`, `"%"`, and `".%"`. |
| `Compact`, `Styled`, `ShowCompactValue` | Presentation behavior in supported layouts. |
| `Visible`, `Disabled`, `Tooltip`, `Order`, `NoConfigs` | Common control options. |
| `AllowSetValue` | Allows user to set the slider's value by right or double clicking/tapping. |
| `BypassSetValue` | If `AllowSetValue` is true, this options allows to set any value, bypassing incrementation and min-max limits |

If your code needs an integer, round/clamp the value in the callback rather than assuming a displayed value is already an integer. Keep `Min` and `Max` different and check the range before applying it to your own code.

### Dropdowns

```lua
local dropdown = group:AddDropdown("Quality", {
    Text = "Quality",
    Options = { "Low", "Medium", "High" },
    Value = 2,
    Callback = function(value, rawValue, control)
        print("Selected:", value)
    end,
})
```

The repository's own example uses `Options` as the list field; the internal default option is named `Values`. If adapting a snippet from a different revision, verify the accepted list field in that version.

Common options:

- `Options` or `Values`: available entries.
- `Value`: initial selection.
- `Multi = true`: allow more than one selected entry.
- `AllowUnselect = true`: allow a single selection to be cleared.
- `Convert`: controls how the selection is converted between the visible option and its internal representation. It defaults to `true` in the inspected source.
- `AutoHide`: controls closing behavior for a single-selection dropdown.
- `Callback`: receives the selected result; callback signatures can include additional arguments such as the raw representation and the control object.

**Important:** the internal representation of a dropdown value can be a number/index or a list, depending on `Multi` and `Convert`. When you need the chosen label, rely on the callback's converted value and test the behavior against your source version. For a multi-select dropdown, write your callback to handle a table rather than a single string.

### Text boxes

`AddTextBox` is the text-entry control. It is distinct from `AddInput`, which is the keybind selector described below.

```lua
local textBox = group:AddTextBox("SearchText", {
    Text = "Search",
    PlaceholderText = "Type here...",
    Value = "",
    Instant = false,
    Callback = function(text)
        print("Committed text:", text)
    end,
})

textBox.Value = "Updated value"
```

Useful options:

- `Text`: label for the box.
- `PlaceholderText`: hint displayed while the box is empty.
- `Value`: initial text.
- `Instant = true`: invokes the callback as the text changes, rather than waiting for the normal commit action.
- `Callback`: receives the text string.
- `Visible`, `Disabled`, `Tooltip`, `Order`, `NoConfigs`, `Translations`.

Use `Instant = true` for live search/filtering. For validation or actions that should run only after the user finishes typing, leave it disabled and respond to the committed value.

### Keybind inputs

`AddInput` creates the keybind setter. The library also maps `AddKeybind` to this same control type.

```lua
local keyInput = group:AddInput("OpenMenuKey", {
    Text = "Open menu key",
    Value = Enum.KeyCode.K,
    KeySet = function(keyCode)
        print("New key:", keyCode)
    end,
})
```

The displayed key is represented internally as an `Enum.KeyCode` value or its numeric value. `KeySet` is the specific callback used by the source when a key changes. Setting the value to `nil`/an unsupported value can result in a `None` display, depending on the path used to set it.

Options include `Text`, `Value`, `KeySet`, `Callback`, `Visible`, `Disabled`, `Tooltip`, `DisabledTooltip`, `NoConfigs`, `Order`, and `Translations`.

### Labels and separators

Labels display text without requiring a callback.

```lua
local label = group:AddLabel({
    Text = "Status: idle",
    Visible = true,
    Translations = { RU = "Статус: ожидание" },
})

-- Update the displayed text when needed.
label.Text = "Status: ready"
```

A `Text` value is the key property for labels. The library supports richer text formatting in parts of the UI (especially help/tooltip text), but rendered rich text varies by control. If formatting tags show literally, remove the tags or use a field that the source explicitly configures for rich text.

Separators:

```lua
group:AddSeparator()
group:AddSeparator({ Invisible = true })
```

`Invisible = true` makes the separator line invisible while retaining its layout space.

### Color pickers

Color pickers may be attached to supported controls such as buttons, labels, inputs, and toggles. They return an object that can be kept and updated.

```lua
local accentPicker = toggle:AddColorPicker({
    Text = "Accent color",
    Value = Color3.fromRGB(255, 80, 120),
    Callback = function(color)
        print("New color:", color)
    end,
})

accentPicker:Set(Color3.fromRGB(90, 160, 255))
```

The default color picker value in the source is white. Use a `Color3` value for `Value`, and expect the callback to receive a `Color3`. `Text`, `Value`, and `Callback` are the core options.

**Lifehack:** attach a color picker to a related toggle/button instead of building a separate row for every color option. This keeps related controls together and can reduce clutter.

---

## Notifications and confirmation prompts

### Toast notifications

```lua
window:Notification({
    Title = "Saved",
    Text = "Your settings have been saved.",
    Duration = 4,
    Side = "Right",
    Icon = "Save",
})
```

Default toast options in the source include:

| Option | Meaning |
|---|---|
| `Title` | Notification heading. |
| `Text` | Notification body. |
| `Duration` | Time before dismissal, in seconds. The normal toast path clamps duration to a supported range. |
| `Side` | `"Left"` or `"Right"`; default can be inherited from the window setting. |
| `Icon` | Optional icon identifier. |
| `HasButtons` | Enables a buttons/confirmation-style interaction. |
| `HasButton` | Enables only a single confirmation button unlike the `HasButtons` |
| `Callback` | Called with the user's choice when buttons are enabled. |
| `UseOgScaling` | Optional legacy sizing behavior. |

`window:Notify(options)` is an alias for `window:Notification(options)`.

### In-window confirmation prompt

```lua
local confirmed = window:WindowNotification({
    Title = "Confirm change",
    Text = "Apply this setting?",
    HasButtons = true,
})

if confirmed then
    print("Confirmed")
else
    print("Cancelled")
end
```

`HasButtons = true` makes the call wait for the user's choice and return a boolean-like result. Use `WindowNotification` for confirmation flows; use `Notification` for non-blocking status updates. `InWindowNotification` is an alias.

Avoid making a confirmation prompt from inside a callback that must continue immediately. Treat it as a user interaction that may take an indefinite amount of time.

---

## Themes and visual customization

The standard theme color keys are:

- `Main`: primary/accent color.
- `Back`: background color.
- `Stroke`: outline/stroke color.
- `Text`: text color.

The simplest direct runtime adjustment is to edit the live options table and refresh the window:

```lua
window.Options.Theme.Main = Color3.fromRGB(255, 90, 90)
window.Options.Theme.Back = Color3.fromRGB(20, 22, 28)
window.Options.Theme.Stroke = Color3.fromRGB(65, 70, 82)
window.Options.Theme.Text = Color3.fromRGB(245, 245, 250)
window:Refresh()
```

Theme-related visual options in the current source include:

- `AnimationSpeed`
- `BackgroundTransparency`
- `ShadowSize` and `ShadowTransparency`
- `Image`, `ImageEnabled`, `ImageColor`, and `ImageTransparency`
- `NeonThickness` and `NeonType` (`"Stroke"`, `"Top"`, or `"None"` are used in the source)
- `CornerRadius`, `RoundEverything`, and `NoStrokes`
- `BlurBackground`, `EnableUIBlur`, and `FullBlurSize`
- `Volume`, `ClickSound`, `HoverSound`, and `NotificationSound`
- `NotificationSide`, `NotificationOgScaling`, and mobile-button options

Some effects are limited by runtime/device capabilities. A blur setting may have no visible result on a device or quality level where that effect is unavailable.

### Theme share strings

`GetThemeString()` returns a compact share string for the current theme, and `SetThemeString(text)` attempts to apply one. The setter returns success information; check the result if the string comes from an untrusted or external source.

```lua
local themeString = window:GetThemeString()
print(themeString)

local ok, applied = window:SetThemeString(themeString)
print("Decode succeeded:", ok, "Theme applied:", applied)
```

The lower-level `SetTheme` expects the library's serialized theme table format, not simply the four color keys described above. Prefer the share-string methods or the built-in theme UI if you don't need to construct that serialized format yourself.

---

## Localization

Localization is provided with a `Translations` table. Language names are reduced to a two-character uppercase code by the implementation, so use consistent codes such as `EN`, `RU`, or `ES`.

```lua
local window = Fire:Window({
    Text = "Settings",
    Language = "EN",
})

local tab = window:AddTab({
    Text = "Main",
    Translations = {
        EN = "Main",
        RU = "Главная",
    },
})

tab:AddButton({
    Text = "Save",
    Translations = {
        EN = "Save",
        RU = "Сохранить",
    },
    Callback = function()
        print("Save clicked")
    end,
})
```

For most components, the translation map associates language codes with translated strings for their display text. Some objects support translation tables for multiple fields, such as `Title` and `Text`, rather than a single string. Check the object-specific source/defaults when translating notification prompts or other multi-field objects.

**Tip:** translate the visible text rather than using a translated string as an identifier. Keep stable control flags/names unchanged when switching languages, otherwise saved state can become harder to match.

---

## Configs and share strings

The window exposes config serialization helpers:

```lua
local configTable = window:GetConfig()
local success = window:SetConfig(configTable)

local configString = window:GetConfigString()
local parsed, applied = window:SetConfigString(configString)
```

- `GetConfig()` reads supported control state into a table.
- `SetConfig(table)` applies a compatible config table.
- `GetConfigString()` encodes the current config into a shareable string.
- `SetConfigString(string)` decodes and tries to apply a share string.
- `NoConfigs = true` excludes supported objects from config state.

Config/theme state is keyed by object identifiers/flags. Give persistent controls stable names and do not casually rename them after distributing configs.

### File-backed config manager

The library source contains a config/theme manager in its built-in settings UI. Actual disk save/load behavior depends on whether the runtime provides the required file APIs. In a standard Roblox experience, do not assume executor-style file functions exist; use Roblox-supported persistence (for example, server-side data handling) for real player data instead.

**Safety note:** share strings are data, not executable instructions, but malformed/untrusted strings should still be handled as user input. Never treat a config as trusted authorization or security policy. Validate settings before applying them to consequential game logic.

---

## Floating labels

A floating label is a movable on-screen text element, useful for a status readout or a small heads-up display.

```lua
local status = window:FloatingLabel({
    Title = "Status",
    Text = "Ready",
    Icon = "Home",
    Visible = true,
})

status.Text = "Working..."
```

The floating-label options in the source include `Text`, `Title`, `Position`, `AnchorPoint`, `Visible`, and `Icon`. It also exposes `Destroy()` to remove the label and disconnect its internal connections. Because resizing is handled internally, prefer using the object's supported options/properties and verify the refresh behavior against the source version you ship.

---

## Dynamic controls and object properties

Controls are not just visual objects: they expose state and methods so you can update them after creation.

### Set a value

Prefer the explicit setter when you want to update a control programmatically:

```lua
toggle:Set(true)
slider:Set(30)
textBox.Value = "New text"
dropdown:Set(1)
```

For controls that expose a `Value` property, you can also inspect it:

```lua
print(toggle.Value)
print(slider.Value)
print(textBox.Value)
```

The proxy/object layer forwards many option properties, which is why source examples can assign values such as `object.Disabled = true`. The exact set of writable properties depends on the object class. When in doubt, change the corresponding entry in `object.Options`, call `Set()` only for classes that expose it, and use `Refresh()`/`window:Refresh()` only when a visual refresh is required.

### Show, hide, and disable conditionally

```lua
local advanced = group:AddToggle({
    Text = "Advanced mode",
    Value = false,
})

local advancedSlider = group:AddSlider({
    Text = "Advanced amount",
    Min = 0,
    Max = 10,
    Value = 5,
    Disabled = true,
})

advanced.Callback = function(value)
    advancedSlider.Disabled = not value
    advancedSlider.Visible = value
end
```

A safer pattern is to provide the callback at creation time and then use the same returned object references:

```lua
local advancedSlider

local advancedToggle = group:AddToggle({
    Text = "Advanced mode",
    Value = false,
    Callback = function(value)
        if advancedSlider then
            advancedSlider.Disabled = not value
            advancedSlider.Visible = value
        end
    end,
})

advancedSlider = group:AddSlider({
    Text = "Advanced amount",
    Min = 0,
    Max = 10,
    Value = 5,
    Disabled = true,
    Visible = false,
})
```

The second pattern also avoids a brief visible/enabled state on initial render. Where ordering matters, use stable `Order` values instead of relying on creation timing.

### Component lifecycle

- Keep references to controls you plan to update.
- Use `Visible = false` at creation time for controls that should only appear after a condition is met.
- Use `Disabled = true` when a control should remain visible but not interactive.
- Use `NoConfigs = true` for temporary/UI-only state that should not be stored in the config file.
- When removing custom objects, call the object's documented cleanup method when available. Floating labels expose `Destroy()`.
- Do not call `RefreshAll()` after every input change; it is intended for broader refreshes, not ordinary value updates.

---

## Advanced tips and practical patterns

### 1. Keep the UI separate from your logic

A callback should translate a user's action into a state change or a function call. It should not contain a whole application. Keep core logic in separate functions so the same behavior can be triggered by a button, a keyboard event, or a test.

```lua
local function applyMode(mode)
    print("Applying mode:", mode)
end

group:AddButton({
    Text = "Apply balanced mode",
    Callback = function()
        applyMode("Balanced")
    end,
})
```

### 2. Use stable names for saved controls

```lua
local volume = group:AddSlider("AudioVolume", {
    Text = "Audio volume",
    Min = 0,
    Max = 100,
    Value = 80,
})
```

A meaningful ID is much easier to maintain than a generated or ambiguous name. Treat it like a schema field if configs are user-facing.

### 3. Use `NoConfigs` intentionally

Controls that represent permanent user preferences can participate in saved configuration. Temporary filters, transient status, or controls whose state must not be restored can use `NoConfigs = true`.

### 4. Prefer callbacks over polling

If a toggle already gives you a boolean callback, update the affected application state there instead of repeatedly checking the control every frame. Polling wastes work and can drift out of sync with the UI.

### 5. Use `Instant` selectively

An instant text box is useful for search-as-you-type. It is not ideal for operations that are costly or irreversible. Use normal commit behavior for explicit submission and validate the text before using it.

### 6. Use tooltips as documentation in the UI

```lua
group:AddToggle({
    Text = "Enable compression",
    Tooltip = "Reduces stored size. It may take longer to process larger inputs.",
})
```

A concise tooltip can remove the need for extra labels. Avoid putting important instructions only in a tooltip, since touch interfaces do not always have hover interactions.

### 7. Use translations for all user-facing strings

Translate window/tab/control text and notification prompts consistently. Keep identifiers, config flags, and internal values language-neutral.

### 8. Reuse UI objects instead of recreating them

For repeated status updates, update a label or reuse a notification pattern rather than adding a new control each time. Recreating controls repeatedly can create unnecessary connections and visual clutter.

### 9. Keep config/share-string work separate from authorization

A saved config should never determine whether a user is permitted to do something. Configs are preferences; authorization and important state should be validated by the relevant game/service logic.

### 10. Remote loader cache behavior

The loader source uses a global cache and may store a local copy when its runtime provides file APIs. That can make repeat loads faster, but it also means local caching and updates can vary by environment. If reproducible behavior matters, review and ship a known source revision rather than relying on a moving branch URL.

---

## Troubleshooting

### The window does not appear

- Make sure the module returns the Fire Library table.
- Confirm the creation code runs in a client context appropriate for a GUI.
- Check for an error earlier in the output/console; UI construction can stop if an option has an invalid type.
- If using the loader, remember it is designed for a specialized runtime and may not work in ordinary Studio scripts.

### A callback does not run

- Confirm the function is assigned to the correct property (`Callback` for most controls; `KeySet` for keybind changes).
- Check whether the control is disabled or hidden by a condition.
- For text boxes, confirm whether `Instant` is enabled or whether the callback waits for the normal commit action.
- For dropdowns, handle the correct value shape for single-select versus multi-select.

### A value looks wrong

- Sliders require sensible `Min`, `Max`, and `Step` settings.
- Dropdowns may expose an index/raw value depending on `Convert` and multi-select settings.
- Keybind controls use `Enum.KeyCode`-based values.
- Color pickers expect Roblox `Color3` values.

### Configs or themes do not save

- File-backed storage depends on runtime APIs and permissions.
- A control marked `NoConfigs = true` is deliberately excluded from supported config serialization.
- Renaming a flag can prevent an old config entry from matching the control.
- Check the success values returned by `SetConfigString` or `SetThemeString` before reporting that an import succeeded.

### A theme change does not redraw everything

Update `window.Options.Theme` using valid `Color3` values and call `window:Refresh()`. A broader structural/style change may require `window:RefreshAll()`, but do not use the broad refresh on every normal value change.

### Tooltip or icon does not show as expected

Icon strings must match identifiers available to the library. Some text formatting is field-specific. Try a known bundled icon and plain text first, then add formatting back incrementally.

---

## Quick API reference

### Library and window

| Call | Purpose |
|---|---|
| `Fire:Window(options)` | Create a window. |
| `window:AddTab(options)` | Create a tab. |
| `window:AddCustomTab(options)` | Create a custom tab. |
| `window:AddHeader(options)` | Add a tab/navigation header. |
| `window:FloatingLabel(options)` | Create a floating label. |
| `window:Toggle()` | Toggle visibility. |
| `window:Show()` / `window:Hide()` | Show or hide the UI. |
| `window:TryClose()` / `window:Close()` | Confirm-close / close. |
| `window:Notification(options)` | Show a toast. |
| `window:WindowNotification(options)` | Show an in-window prompt. |
| `window:GetConfig()` / `window:SetConfig(data)` | Read/apply config state. |
| `window:GetTheme()` / `window:SetTheme(data)` | Read/apply serialized theme data. |
| `window:GetConfigString()` / `window:SetConfigString(text)` | Export/import config share strings. |
| `window:GetThemeString()` / `window:SetThemeString(text)` | Export/import theme share strings. |
| `window:Refresh()` / `window:RefreshAll()` | Refresh current styling / refresh all UI. |

### Tab and groupbox controls

| Call | Purpose |
|---|---|
| `tab:AddGroupbox(options)` | Create a groupbox. |
| `tab:AddLeftGroupbox(options)` | Create a left-side groupbox. |
| `tab:AddRightGroupbox(options)` | Create a right-side groupbox. |
| `tab:AddButton(options)` | Action button. |
| `tab:AddToggle(options)` | Boolean toggle. |
| `tab:AddCheckBox(options)` | Checkbox-style toggle. |
| `tab:AddSlider(options)` | Numeric slider. |
| `tab:AddDropdown(options)` | Selection dropdown. |
| `tab:AddTextBox(options)` | Text entry. |
| `tab:AddInput(options)` / `tab:AddKeybind(options)` | Keybind selector. |
| `tab:AddLabel(options)` | Text label. |
| `tab:AddSeparator(options)` | Horizontal separator/spacing. |

The same control-creation methods are available on groupboxes for ordinary UI elements. The library has additional aliases for some methods; the `Add...` forms are the clearest choice for new code.

---

## Source and license

Fire Library's README identifies the project as MIT-licensed. Check the repository's `LICENSE` file for the exact license terms and include the required copyright/license notice when redistributing the library or modified copies.

- Project README: <https://github.com/Its-Kawi/Fire-Library/blob/main/README.md>
- Main source: <https://github.com/Its-Kawi/Fire-Library/blob/main/Files/Library.lua>
- License: <https://github.com/Its-Kawi/Fire-Library/blob/main/LICENSE>
