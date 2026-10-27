# 🔥 Fire Library
The exclusive UI Library specially built for NullFire
#### 📕 [Documentation is here](#links)  

**The most 🔥 powerful and flexible UI library that works everywhere!**

> Built for developers who demand performance, customization, and seamless integration across all platforms.

---

## 🌟 Why Fire Library?

Fire Library isn't just another UI framework — it's a **complete solution** designed from the ground up to deliver:

### ✨ Seamless Dual Environment Support
Works flawlessly in both **exploit environments** and **standard contexts**, making it perfect for:
- Game development tools
- Administration panels  
- Mod menus
- Cheat panels
- Utility scripts
- And much more!

### ⚡ Blazing Fast Performance
Optimized rendering ensures smooth animations and responsive interactions even under heavy load.

### 🎨 Infinite Customization
Full control over:
- Themes & colors
- Animations speeds  
- Background images
- Neon effects
- Shadow styles
- And dozens of other visual tweaks

### 📱 Universal Device Compatibility  
Supports desktop, mobile, emulators, and touch devices out of the box with automatic platform detection.

### 🔧 Developer-Friendly Features
- Real-time theme switching
- Language localization system  
- Configurable hotkeys
- Rich tooltip support
- Floating labels
- Notification system
- Color pickers
- Configs (coming soon)
- Drag-to-resize windows

---

## 🚀 Getting Started

```lua
local lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Its-Kawi/Fire-Library/refs/heads/main/Loader.lua"))()
local window = lib:Window({
    Title = "My Awesome Script"
})

local tab = window:AddTab("Main")
tab:AddLabel({ Text = "Welcome to Fire Library!" })
```

#### To use FireLibrary in your own game, you need to go to Files folder, copy contents of the Library.lua, move them into a ModuleScript and in the very bottom of the script add this:
```lua
return require(obj:FindFirstChildOfClass("ModuleScript"));
```

> No complicated setup required – drop it in and start building beautiful interfaces immediately!

---

## 💎 Performance

| Feature              | Description |
|---------------------|-------------|
| **Smart Caching**    | Automatically caches assets for faster loading |
| **Dynamic Theming**  | Apply themes on-the-fly with live preview |
| **Multi-Language**   | Built-in translation system supporting multiple languages |
| **Rich Formatting**  | Advanced text formatting in labels and tooltips |
| **Event System**     | Powerful event handling between components |
| **Memory Efficient** | Automatic cleanup prevents memory leaks |

---

## 🛠️ Fully Featured Components

Build complex interfaces using our extensive component library:
- Buttons • Toggles • Checkboxes  
- Sliders • Dropdowns • Text Boxes
- Labels • Separators • Groupboxes
- Keybind setters • Color pickers
- Notifications • Tooltips • Floating labels

Each component supports:
✅ Live updates  
✅ Dynamic visibility  
✅ Translation-ready  
✅ Theme-aware styling  

---

## 🪪 License

This project is licensed under the **MIT License** – see the [LICENSE](LICENSE) file for details.

You're free to use, modify, and distribute this library in your own projects (commercial or personal).

---

## 🌍 Join Our Community

Want to stay updated with new features, get help, or contribute?

#### Links

💬 **Discord:** [Join our server](https://discord.gg/4bexJD6WVT)  
📘 **Documentation:** [How to use the library](https://github.com/Its-Kawi/Fire-Library/blob/main/Documentation.md)

---

*Made with ❤️ by developers, for developers.*  
