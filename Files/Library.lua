local tfind = table.find
local game = game
local workspace = workspace
local typeof = typeof
local newproxy = newproxy
local tostring = tostring
local tonumber = tonumber
local mrandom = math.random
local pcall = pcall
local tremove = table.remove
local spawn = task.spawn
local delay = task.delay
local wait = task.wait
local defer = task.defer
local clamp = math.clamp
local abs = math.abs
local round = math.round
local floor = math.floor
local inf, nan = 1 / 0, 0 / 0
local max = math.max
local tinsert = table.insert
local concat = table.concat
local tsort = table.sort
local tclear = table.clear
local tfreeze = table.freeze
local warn, error, print = warn, error, print
local type = type
local max32 = tonumber("2147483647")

local tclone = function(a)
	local b = { }
	for i, v in a do
		b[i] = v
	end

	return b
end

local enumLookup = { }
for i, v in Enum:GetEnums() do
	enumLookup[tostring(v)] = v
end

enumLookup.GetEnums = function() return enumLookup end

local Enum = enumLookup
local U2s = UDim2.fromScale
local U2n = UDim2.new
local U2o = UDim2.fromOffset
local Un = UDim.new
local unpack = unpack
local Inew = Instance.new
local setmetatable = setmetatable
local getmetatable = getmetatable
local select = select
local C3h = Color3.fromHex
local C3n = Color3.new
local C3R = Color3.fromRGB
local V2n = Vector2.new
local TIn = TweenInfo.new
local pack = table.pack

local function memoize(fn)
	local cache = setmetatable({ }, { __mode = "k" })

	return function(...)
		local args = pack(...)
		local key = args.n ~= 0 and concat(args, "\0") or ""

		local result = cache[key]
		if result then
			return unpack(result, 1, result.n)
		end

		result = pack(fn(...))
		cache[key] = result

		return unpack(result, 1, result.n)
	end
end

U2s, U2n, U2o, Un, C3R = memoize(U2s), memoize(U2n), memoize(U2o), memoize(Un), memoize(C3R)

local rs = game:GetService("RunService")
local function render(times)
	local start = tick()
	for i = 1, max(tonumber(times) or 0, 1) do
		rs.RenderStepped:Wait()
	end

	return tick() - start
end

local env = getfenv()
local function g(n)
	return env[n]
end

local config = require(script.Config)

local global = (env.getgenv or function() return _G end)()
local key = ... or config.Name

if global[key] then
	script.Parent:Destroy()
	render()

	return global[key]
end

--

local wf, rf, df, mf, lf, If, IF = g("writefile"), g("readfile"), g("delfile") or g("deletefile"), g("makefolder"), g("listfiles"), g("isfolder"), g("isfile") -- g function to suspend roblox studio warnings
local gca = g("getcustomasset")
local toclip = g("toclipboard") or g("setclipboard")

local configsEnabled = typeof(wf) == "function" and typeof(rf) == "function" and typeof(df) == "function" and typeof(mf) == "function" and typeof(lf) == "function" and typeof(If) == "function" and typeof(IF) == "function"

local http = game:GetService("HttpService")
local function je(c)
	return http:JSONEncode(c)
end

local function jd(c)
	return http:JSONDecode(c)
end

local function id()
	return tostring(mrandom()):sub(3, 13)
end

local cornerState = {
	[true] = Un(0, 4),
	[false] = Un(0, 0)
}

local compressor, base64 = require(script.Compressor), require(script.Base64)
local encoder = {
	Encode = function(self, str) return base64:Encode(compressor:Compress(str:reverse(), 22):reverse()):gsub("=", "ZzZ"):gsub("%+", "QqQ"):gsub("/", "XxX"):reverse() end,
	Decode = function(self, str) return compressor:Decompress(base64:Decode(str:reverse():gsub("ZzZ", "="):gsub("QqQ", "+"):gsub("XxX", "/")):reverse()):reverse() end
}

local function clean(str)
	return str:gsub("[\n\r\f\t\0 ]", "")
end

local antiRich do
	local richReplace = {
		["'"] = "&apos;",
		['"'] = "&quot;",
		["<"] = "&lt;",
		[">"] = "&gt;",
		["&"] = "&amp;"
	}

	function antiRich(str)
		return str:gsub("[&<>'\"%z]", richReplace)
	end
end

local wf = configsEnabled and function(name, contents, dontEncode)
	wf(name, typeof(contents) == "string" and (not dontEncode and encoder:Encode(contents) or contents) or encoder:Encode(je(contents)))
end

local rf = configsEnabled and function(name, decode)
	local success, content = pcall(rf, name)
	if not success or not content or content == "" then
		return nil
	end

	if not decode then
		return content
	end

	local success, decoded = pcall(encoder.Decode, encoder, content)
	if not success then
		return nil
	end

	local s, d = pcall(jd, decoded)
	if s then
		return d
	end

	return decoded
end

local mf = configsEnabled and function(name)
	if not If(name) then
		mf(name)
		return true
	end

	return false
end

local nf = configsEnabled and function(name, default, dontEncode)
	if not IF(name) then
		wf(name, default, dontEncode)
		return true
	end

	return false
end

local coreFolder = config.Name
coreFolder ..= "/"

local cacheRoute = coreFolder .. "Cache/"
local configsRoute = coreFolder .. "Configs/"

local json = "shrimp"
json = "." .. json

local themesRoute = coreFolder .. "Themes"
themesRoute ..= "/"

local library, downloadImage
local backgrounds = require(script.Backgrounds)

local function count(tbl)
	local i = 0
	for _ in tbl do
		i += 1
	end

	return i
end

local function tEqual(a, b)
	if typeof(a) ~= "table" or type(b) ~= "table" then return a == b end
	if count(a) ~= count(b) then return false end
	for i, v in a do if b[i] ~= v then return false end end
	for i, v in b do if a[i] ~= v then return false end end

	return true
end

local event = require(script.Event)
local guid = http:GenerateGUID(false):gsub("-", "")
local gsubInput, playSound

local safeReparent do
	local reparentQueue = { }
	local function flushQueue(object, queue)
		if #queue == 0 then
			reparentQueue[object] = nil
			return
		end

		object.Parent = tremove(queue, 1)

		if #queue == 0 then
			reparentQueue[object] = nil
		end
	end

	safeReparent = function(a, b)
		local myQueue = reparentQueue[a]
		if not myQueue then
			myQueue = setmetatable({ }, { __mode = "kv" })
			reparentQueue[a] = myQueue
		end

		if #myQueue == 0 or myQueue[#myQueue] ~= b then
			myQueue[#myQueue + 1] = b
			flushQueue(a, myQueue)
		end
	end

	event.Clock:Connect(function(delta, skip)
		if skip then return end

		for object, queue in reparentQueue do
			flushQueue(object, queue)
		end
	end)
end

local function readTimes(path)
	local times = rf and rf(path, false)
	if times then
		if times == "" then
			times = 1
		else
			local success, decoded = pcall(encoder.Decode, encoder, times)
			if not success then
				times = 0
			else
				times = tonumber(decoded) or 0
			end
		end

		if times then
			times += 1
		end
	end

	times = tonumber(times) or not rf and 1.1 or 1

	if configsEnabled then
		spawn(wf, path, tostring(max(round(times), 1)))
	end

	return times
end

local ranTimes : number = readTimes(coreFolder .. "FirstRun")

spawn(function()
	if mf then
		mf(coreFolder:sub(1, -2))
		mf(cacheRoute:sub(1, -2))
		mf(configsRoute:sub(1, -2))
		mf(themesRoute:sub(1, -2))
	end
end)

local uiBlur = require(script.UIBlur)
local function getObjectFromHash(self, hash)
	local cl = self.Class
	local hl = #hash
	for i, v in self[cl == "Button" or cl == "Label" or cl == "Toggle" or cl == "Input" and "ColorPickers" or "Objects"] do
		if v.Options.FlagHashFull:sub(1, hl) == hash then
			return v
		end
	end
end

local function windowSetup(object) -- in theory, that function is just a plugin for that UI lib
	local window = object.Proxy
	if window.Flag == guid then return end

	window.Options.KeybindMode = event.new()
	window.Options.KeybindModeActive = false

	local objs = { }
	window.Options.KeybindObjects = objs

	local keybindsLabel = window:FloatingLabel("Keybinds" .. id(), { Title = "Keybinds", Text = "", Position = U2n(0, 20, 0.5, 0), AnchorPoint = V2n(0, 0.5), Visible = false })
	local function drawKBL(val)
		window.Options.KeybindModeActive = val

		for i, v in window.KeybindObjects do
			v:Refresh()
		end

		local allFalses = true
		local str = ""

		for i, v in objs do
			if v.Options.Value and v.Options.Reference then
				allFalses = false

				local color = v.Options.Reference.Options.Value and window.Options.Theme.Main or window.Options.Theme.Text
				str ..= ` <font color="#{color:ToHex()}" transparency="{v.Options.Reference.Options.Disabled and 0.35 or 0}">{"[" .. gsubInput(Enum.KeyCode:FromValue(v.Options.Value).Name) .. "] " .. antiRich(v.Options.Reference.Options.Text)}</font> \n`
			end
		end

		keybindsLabel.Text = str:sub(1, -2)
		if allFalses then
			keybindsLabel.Visible = false
			return
		end

		keybindsLabel.Visible = true
	end

	drawKBL(false)
	window._Connections[#window._Connections + 1] = window.Options.KeybindMode:Connect(drawKBL)

	local settingsMainTab = window:AddTab("LibrarySettings" .. window.Flag .. "1", { Text = "Main Settings", Icon = "Cog", Order = max32 })
	local settingsConfigTab = window:AddTab("LibrarySettings" .. window.Flag .. "2", { Text = "Config Settings", Icon = "Cog", Order = max32 - 1 })
	local settingsThemeTab = window:AddTab("LibrarySettings" .. window.Flag .. "3", { Text = "Theme Settings", Icon = "Cog", Order = max32 - 2 })
	local settingsOtherTab = window:AddTab("LibrarySettings" .. window.Flag .. "4", { Text = "Other Settings", Icon = "Cog", Order = max32 - 3 })

	local current = "Main"
	local reparent

	local function tabOnTabSetup(tab)
		tab:AddButton({ Text = "Go Back", Icon = "circle-arrow-left", Callback = function()
			current = "Main"
			reparent()
		end })

		tab:AddSeparator({ Invisible = true })
	end

	tabOnTabSetup(settingsConfigTab)
	tabOnTabSetup(settingsThemeTab)
	tabOnTabSetup(settingsOtherTab)

	local db = false
	settingsMainTab:AddButton({ Icon = "Cross", Text = "Close UI", Callback = function()
		if db or window.Closed then return end
		db = true

		if window:Notification({ Side = "Left", Duration = 15, Title = "Are you sure?", Text = "Are you sure you want to close the UI?", HasButtons = true }) then
			window:Close()
		end

		db = false
	end })

	window.Options.ToggleKeyObject = settingsMainTab:AddButton({ Icon = "Exit", Text = "Toggle UI", Callback = function()
		if window.Closed then return end
		window:Toggle()
	end })

	settingsMainTab:AddInput("ToggleKey", { Text = "Toggle UI key", Value = window.Options.Keybind, Callback = function()
		if window.Closed then return end
		window:Toggle()
	end, KeySet = function(key)
		window.Options.Keybind = key or false
	end })

	settingsMainTab:AddSeparator()

	local textList = {
		"Executor: <b>" .. window.Executor .. "</b>",
		"Executor version: <b>" .. window.ExecutorVersion .. "</b>",
		"Device: <b>" .. window.Device .. "</b>",
		"Emulator: <b>" .. (window.Emulator and "Yes" or "No") .. "</b>",
		"Library version: <b>" .. window.Version .. "</b>"
	}

	local einfo = settingsMainTab:AddLabel("EINFO", { Text = concat(textList, "\n") })

	local theOnlySeparator = settingsMainTab:AddSeparator({ Visible = false })

	local langs = { }
	local pl = settingsMainTab:AddDropdown("Language", { Text = "Language", Values = langs, Convert = false, Callback = function(val)
		window.Language = window.PossibleLanguages[val]
	end, Value = 1 })

	local cp1
	local executionTimes : number = nil

	local configString
	spawn(function()
		local fl = window.FlagHash .. "/"
		local hidden = { }

		if not configsEnabled then
			settingsConfigTab:AddLabel({ Text = "Saving configs and themes are <b>unavailable in your environment!</b>" })
			settingsThemeTab:AddLabel({ Text = "Saving configs and themes are <b>unavailable in your environment!</b>" })
			settingsConfigTab:AddSeparator({ Invisible = true })
			settingsThemeTab:AddSeparator({ Invisible = true })
		end

		local lol = settingsConfigTab:AddLabel({ Text = "Loading configs and themes functions, wait...", Visible = configsEnabled })
		local lol2 = settingsThemeTab:AddLabel({ Text = "Loading configs and themes functions, wait...", Visible = configsEnabled })
		delay(10, function()
			lol.Text = "Looks like your executor experienced an error loading config and themes functions\nPlease retry!"
			lol2.Text = "Looks like your executor experienced an error loading config and themes functions\nPlease retry!"
		end)

		local loadTheme, loadConfig, getExistingConfigs, getExistingThemes
		getExistingConfigs = function()
			local configNames = { }
			for _, file in lf(configsRoute .. fl:sub(1, -2)) or { } do
				tinsert(configNames, file:sub(#configsRoute + #fl + 1, -#json - 1))
			end

			return configNames
		end

		local function validateName(name: string)
			return #name >= 1 and #name <= 32 and not name:find("\\", 1, true) and not name:find("/", 1, true)
		end

		local configRoute = configsRoute .. fl:sub(1, -2) .. "-AutoLoad" .. json
		local autosaveRoute = configsRoute .. fl:sub(1, -2) .. "-AutoSave" .. json
		local autoLoadConfig, autoSaveConfig, saveConfig
		local autoSavingEnabled = false
		local configTextBox, configDropdown, themeTextBox, themeDropdown
		local debugAutoSave = false

		if configsEnabled then
			configTextBox = settingsConfigTab:AddTextBox("ConfigName", {
				PlaceholderText = "Enter Config name",
				NoConfigs = true,
				Text = "Config Name",
				Value = "Config1",
				Visible = false,
				Instant = true,
				Callback = function(text)
					if window.Closed or not autoLoadConfig then return end

					if autoLoadConfig.Value then
						wf(configRoute, { text })
					else
						wf(configRoute, false)
					end
				end
			})
			hidden[#hidden + 1] = configTextBox

			configDropdown = settingsConfigTab:AddDropdown("ConfigsList", {
				Text = "Saved Configs",
				AllowUnselect = true,
				NoConfigs = true,
				Callback = function(text)
					if window.Closed then return end
					configTextBox.Value = text or ""
				end,
				Visible = false
			})
			hidden[#hidden + 1] = configDropdown

			function saveConfig(notifs)
				if window.Closed then return end

				local name = configTextBox.Value
				if not validateName(name) then
					if notifs then
						return window:Notification({ Title = "Error", Text = "Invalid config name. Use 1–32 characters, no \\ or /" })
					else
						configTextBox.Value = "Config1"
						name = "Config1"
					end
				end

				local route = configsRoute .. fl .. name .. json
				if notifs and IF(route) then if not window:Notification({ Side = "Left", Title = "Config Exists", Text = "Config '" .. name .. "' already exists!\nDo you want to overwrite it?", HasButtons = true, Duration = 10 }) then return end end

				wf(route, window:GetConfigString(), true)
				configDropdown.Values = getExistingConfigs()

				if notifs then
					window:Notification({ Side = "Left", Title = "Success", Text = "Config '" .. name .. "' has been saved!" })
				end
			end

			hidden[#hidden + 1] = settingsConfigTab:AddButton({
				Text = "Save Config",
				NoConfigs = true,
				Icon = "Save",
				Callback = function()
					saveConfig(true)
				end,
				Visible = false
			})

			loadConfig = function(name)
				if window.Closed then return end
				if not validateName(name) then return window:Notification({ Title = "Error", Text = "Invalid config name. Use 1–32 characters, no \\ or /" }) end

				autoSavingEnabled = false

				local route = configsRoute .. fl .. name .. json
				if not IF(route) then
					autoSavingEnabled = true
					return window:Notification({ Title = "Error", Text = "Config '" .. name .. "' does not exist" })
				end

				local data = rf(route, false)
				if data then
					local _, s = window:SetConfigString(data)
					if not s then
						-- window:SetConfig(data)
						autoSavingEnabled = true
						return
					end

					window:Notification({ Title = "Success", Text = "Config '" .. name .. "' has been successfully loaded!" })
				else
					window:Notification({ Title = "Error", Text = "Invalid config file" })
				end

				autoSavingEnabled = true
			end

			hidden[#hidden + 1] = settingsConfigTab:AddButton({
				Text = "Load Config",
				NoConfigs = true,
				Icon = "Config",
				Callback = function()
					if window.Closed then return end
					loadConfig(configTextBox.Value)
				end,
				Visible = false
			})

			hidden[#hidden + 1] = settingsConfigTab:AddButton({
				Text = "Delete Config",
				NoConfigs = true,
				Icon = "Trash",
				Callback = function()
					if window.Closed then return end
					local name = configTextBox.Value
					if not validateName(name) then return window:Notification({ Title = "Error", Text = "Invalid config name. Use 1–32 characters, no \\ or /" }) end

					local route = configsRoute .. fl .. name .. json
					if not IF(route) then return window:Notification({ Title = "Error", Text = "Config '" .. name .. "' does not exist" }) end

					if window:Notification({ Side = "Left", Title = "Delete Config", Text = "Are you sure you want to delete config '" .. name .. "'?", HasButtons = true, Duration = 10 }) then
						df(route)
						configDropdown.Values = getExistingConfigs()

						window:Notification({ Side = "Left", Title = "Success", Text = "Config '" .. name .. "' has been successfully deleted!" })
					end
				end,
				Visible = false
			})

			autoLoadConfig = settingsConfigTab:AddToggle("AutoLoadConfig", {
				Text = "Auto Load Config",
				Value = true,
				NoConfigs = true,
				Callback = function(value)
					if window.Closed then return end
					if value then
						wf(configRoute, { configTextBox.Value })
					else
						wf(configRoute, false)
					end
				end,
				Visible = false
			})

			autoSaveConfig = settingsConfigTab:AddToggle("AutoSaveConfig", {
				Text = "Auto Save Config",
				Value = false,
				Callback = function(value)
					if window.Closed then return end
					wf(autosaveRoute, value)
				end,
				NoConfigs = true,
				Visible = false
			})

			hidden[#hidden + 1] = autoLoadConfig
			hidden[#hidden + 1] = autoSaveConfig
			hidden[#hidden + 1] = settingsConfigTab:AddSeparator({ Invisible = true, Visible = false })
		end

		configString = settingsConfigTab:AddTextBox("ConfigString", {
			NoConfigs = true,
			Instant = true,
			Text = "Config Share string",
			PlaceholderText = "Click \"Generate Code\" button, or insert your config share string here",
			Callback = function(text)
				if window.Closed then return end

				if text ~= window:GetConfigString() then
					autoSavingEnabled = false
					local succeed, succeed2 = window:SetConfigString(text)
					autoSavingEnabled = true
					if not succeed and clean(text) ~= "" and text ~= "Code expired" then
						window:Notification({ Title = "Error", Text = "Invalid config share string!" })
					elseif succeed2 then
						window:Notification({ Title = "Success", Text = "Config 'SharedString' has been successfully loaded!" })
					end
				end
			end
		})

		window._Connections[#window._Connections + 1] = configString.Instance.View.Bar.Focused:Connect(function()
			configString:Set(window:GetConfigString())
		end)

		local changed = false
		spawn(function()
			while wait(0.25 + render()) and not window.Closed do
				if changed then
					configString:Set(window:GetConfigString())
					changed = false

					if autoSavingEnabled and autoSaveConfig.Value then
						defer(saveConfig, debugAutoSave)
					end
				end
			end
		end)

		local function trackChanges(obj)
			if obj == configString then return end

			local options = obj.Options
			window._Connections[#window._Connections + 1] = obj.Changed:Connect(function()
				if not changed and not options.NoConfigs then
					changed = true
				end
			end)
		end

		for i, v in window.AllObjects do
			pcall(trackChanges, v)
		end

		window._Connections[#window._Connections + 1] = window.ObjectAdded:Connect(function(v)
			pcall(trackChanges, v)
		end)

		if toclip then
			settingsConfigTab:AddButton({
				Text = "Copy Code",
				Tooltip = "If code is not generated, you can still click that button, so code generates automatically!",
				Callback = function()
					if window.Closed then return end

					configString.Value = window:GetConfigString()
					toclip(configString.Value)
					window:Notification({ Title = "Copied", Text = "Code copied to clipboard!" })
				end
			})
		end

		getExistingThemes = function()
			local themeNames = { }
			for _, file in lf(themesRoute:sub(1, -2)) or { } do
				tinsert(themeNames, file:sub(#themesRoute + 1, -#json - 1))
			end

			return themeNames
		end

		local autoLoadTheme
		local themeRoute = themesRoute:sub(1, -3) .. "-AutoLoad" .. json

		if configsEnabled then
			themeTextBox = settingsThemeTab:AddTextBox("ThemeName", {
				PlaceholderText = "Enter Theme name",
				NoConfigs = true,
				Text = "Theme Name",
				Visible = false,
				Instant = true,
				Callback = function(text)
					if window.Closed then return end

					if autoLoadTheme.Value then
						wf(themeRoute, { text })
					else
						wf(themeRoute, false)
					end
				end
			})
			hidden[#hidden + 1] = themeTextBox

			themeDropdown = settingsThemeTab:AddDropdown("ThemesList", {
				Text = "Saved Themes",
				AllowUnselect = true,
				NoConfigs = true,
				Callback = function(text)
					if window.Closed then return end

					local text = text or ""
					themeTextBox.Value = text

					if text ~= "" then
						loadTheme(text)
					end
				end,
				Visible = false
			})
			hidden[#hidden + 1] = themeDropdown

			hidden[#hidden + 1] = settingsThemeTab:AddButton({
				Text = "Save Theme",
				NoConfigs = true,
				Icon = "Save",
				Callback = function()
					if window.Closed then return end

					local name = themeTextBox.Value
					if not validateName(name) then return window:Notification({ Title = "Error", Text = "Invalid theme name. Use 1–32 characters, no \\ or /" }) end

					local route = themesRoute .. name .. json
					if IF(route) then if not window:Notification({ Side = "Left", Title = "Theme Exists", Text = "Theme '" .. name .. "' already exists!\nDo you want to overwrite it?", HasButtons = true, Duration = 10 }) then return end end

					wf(route, window:GetThemeString(), true)
					themeDropdown.Values = getExistingThemes()

					window:Notification({ Side = "Left", Title = "Success", Text = "Theme '" .. name .. "' has been saved!" })
				end,
				Visible = false
			})

			loadTheme = function(name)
				if window.Closed then return end
				if not validateName(name) then return window:Notification({ Title = "Error", Text = "Invalid theme name. Use 1–32 characters, no \\ or /" }) end

				local route = themesRoute .. name .. json
				if not IF(route) then return window:Notification({ Title = "Error", Text = "Theme '" .. name .. "' does not exist" }) end

				local data = rf(route, false)
				if data then
					if not window:SetThemeString(data) then
						window:SetTheme(data)
					end

					cp1.Value = window.Theme.Main
					window:Notification({ Title = "Success", Text = "Theme '" .. name .. "' has been successfully loaded!" })
				else
					window:Notification({ Title = "Error", Text = "Invalid theme file" })
				end
			end

			hidden[#hidden + 1] = settingsThemeTab:AddButton({
				Text = "Load Theme",
				Icon = "Star",
				Callback = function()
					if window.Closed then return end
					loadTheme(themeTextBox.Value)
				end,
				Visible = false
			})

			hidden[#hidden + 1] = settingsThemeTab:AddButton({
				Text = "Delete Theme",
				Icon = "Trash",
				Callback = function()
					if window.Closed then return end

					local name = themeTextBox.Value
					if not validateName(name) then return window:Notification({ Title = "Error", Text = "Invalid theme name. Use 1–32 characters, no \\ or /" }) end

					local route = themesRoute .. name .. json
					if not IF(route) then return window:Notification({ Title = "Error", Text = "Theme '" .. name .. "' does not exist" }) end

					if window:Notification({ Side = "Left", Title = "Delete Theme", Text = "Are you sure you want to delete theme '" .. name .. "'?", HasButtons = true, Duration = 10 }) then
						df(route)
						themeDropdown.Values = getExistingThemes()

						window:Notification({ Side = "Left", Title = "Success", Text = "Theme '" .. name .. "' has been successfully deleted!" })
					end
				end,
				Visible = false
			})

			autoLoadTheme = settingsThemeTab:AddToggle("AutoLoadTheme", {
				Text = "Auto Load Theme",
				Value = false,
				NoConfigs = true,
				Visible = false,
				Callback = function(value)
					if window.Closed then return end

					if value then
						wf(themeRoute, { themeTextBox.Value })
					else
						wf(themeRoute, false)
					end
				end,
			})
			hidden[#hidden + 1] = autoLoadTheme
			hidden[#hidden + 1] = settingsThemeTab:AddSeparator({ Invisible = true, Visible = false })
		end

		local themeString = settingsThemeTab:AddTextBox("ThemeString", {
			NoConfigs = true,
			Instant = true,
			Text = "Theme Share string",
			Callback = function(text)
				if window.Closed then return end

				if text ~= window:GetThemeString() then
					if not window:SetThemeString(text) and clean(text) ~= "" then
						window:Notification({ Title = "Error", Text = "Invalid share string!" })
					end
				end
			end
		})

		window._Connections[#window._Connections + 1] = themeString.Instance.View.Bar.Focused:Connect(function()
			themeString.Value = window:GetThemeString()
		end)

		if toclip then
			settingsThemeTab:AddButton({
				Text = "Copy Code",
				Callback = function()
					themeString.Value = window:GetThemeString()
					toclip(themeString.Value)

					window:Notification({ Title = "Copied", Text = "Code copied to clipboard!" })
				end
			})
		end

		if configsEnabled then
			executionTimes = readTimes(configsRoute .. fl:sub(1, -2) .. "-Runs")

			local cn = configTextBox.Value
			nf(configRoute, cn ~= "" and { cn } or false)
			nf(autosaveRoute, true)
			nf(themeRoute, false)
			mf(configsRoute .. fl:sub(1, -2))

			configDropdown.Values = getExistingConfigs()
			themeDropdown.Values = getExistingThemes()

			local cont = rf(themeRoute, true)
			if typeof(cont) == "table" then
				autoLoadTheme.Value = true
				themeTextBox.Value = cont[1]
				defer(loadTheme, cont[1])
			end

			local cont = rf(configRoute, true)
			autoSaveConfig.Value = rf(autosaveRoute, true)

			if typeof(cont) == "table" then
				autoLoadConfig.Value = true
				configTextBox.Value = cont[1]
				delay(1 + render(), function()
					print(cont[1])
					loadConfig(cont[1])
				end)
			else
				autoSavingEnabled = true
			end
		else
			executionTimes = 1.1
		end

		window._Connections[#window._Connections + 1] = window.ThemeChanged:Connect(function()
			themeString.Value = window:GetThemeString()
		end)

		themeString.Value = window:GetThemeString()

		local premadeThemes = require(script.DefaultThemes)
		if configsEnabled then
			if ranTimes <= 1 then
				for i, v in premadeThemes do
					spawn(function()
						wf(themesRoute .. i .. json, v, true)
						themeDropdown.Values = getExistingThemes()
					end)
				end
			end

			lol.Visible = false
			lol2.Visible = false
			for i, v in hidden do
				v.Visible = true
			end
		else
			settingsThemeTab:AddDropdown("ThemesList2", {
				Text = "Premade Themes",
				AllowUnselect = true,
				NoConfigs = true,
				Values = (function() local ret = { } for i in premadeThemes do ret[#ret + 1] = i end tsort(ret) return ret end)(),
				Callback = function(text)
					if window.Closed then return end
					window:SetThemeString(premadeThemes[text])
				end
			})
		end
	end)

	local themeObjects = { }

	settingsThemeTab:AddSeparator()
	local theme = settingsThemeTab:AddLabel({ Text = "Theme" })
	themeObjects.Main = theme:AddColorPicker({ NoConfigs = true })
	themeObjects.Text = theme:AddColorPicker({ NoConfigs = true })
	themeObjects.Stroke = theme:AddColorPicker({ NoConfigs = true })
	themeObjects.Back = theme:AddColorPicker({ NoConfigs = true })

	for i, v in themeObjects do
		v.Value = window.Theme[i]
		v.Tooltip = i .. " Color"
		v.Callback = function(color)
			if window.Closed then return end

			window.Theme[i] = color
			window:Refresh()
		end
	end

	local toggle, toggle2
	local targetColor = window.Options.Theme.Main

	local function reverseRGB(color)
		return C3n(1 - color.R, 1 - color.G, 1 - color.B)
	end

	local function rotateRGB(color, pattern)
		if not pattern then
			pattern = { "R", "G", "B" }

			while pattern[1] == "R" and pattern[2] == "G" do
				for i = 1, 3 do
					local i1, i2 = mrandom(1, 3), mrandom(1, 3)
					pattern[i], pattern[i1] = pattern[i1], pattern[i]
				end
			end
		end

		local new = { }
		for i = 1, 3 do
			new[i] = color[pattern[i]]
		end

		return C3n(unpack(new)), pattern
	end

	local warned = false
	local db = false

	local function n()
		if not warned then
			if db then
				return true
			end

			db = true
			local res = window:Notification({ Side = "Left", Title = "Theme Generator", Text = "This gonna reset your current theme!\nAre you sure" .. (mrandom(1, 10) == 1 and " you wanna accept being uncreative?\n\n(an easter egg btw)" or "?"), Duration = 15, HasButtons = true })
			db = false

			if res then
				warned = true
			else
				return true
			end
		end

		return false
	end

	local btn = settingsThemeTab:AddButton("ThemeGenerator", { Text = "Theme Generator", Icon = "Brush", Tooltip = "Generates a theme\n<b>NOTE:</b> Randomly generated themes are not perfect and can look bad!", Callback = function()
		if n() then return end

		targetColor = cp1.Value
		local mainColor = not toggle2.Value and targetColor

		if not mainColor then
			mainColor = C3n(mrandom(), mrandom(), mrandom())
		else
			mainColor = targetColor:Lerp(C3n(mrandom(), mrandom(), mrandom()), mrandom() / 10)
		end

		mainColor = C3n(clamp(mainColor.R + ((mrandom() - 0.5) / 7.5), 0, 1), clamp(mainColor.G + ((mrandom() - 0.5) / 7.5), 0, 1), clamp(mainColor.B + ((mrandom() - 0.5) / 7.5), 0, 1))

		local isLight = toggle.Value

		local n = mrandom()
		local strokeColor = mainColor:Lerp(C3n(n, n, n), 1 - clamp(mrandom() / n, 0, 1))
		local textColor = mainColor:Lerp(isLight and C3n() or C3n(1, 1, 1), (mrandom() + 1.5) / 2.5)

		local backTone = mainColor:Lerp(isLight and C3n(1, 1, 1) or C3n(), mrandom())
		local backColor = backTone:Lerp(isLight and C3n(1, 1, 1) or C3n(), (mrandom() + 1) / 2)

		if abs((backColor.R + backColor.G + backColor.B) - (textColor.R + textColor.G + textColor.B)) <= 0.2 then
			textColor = textColor:Lerp(isLight and C3n() or C3n(1, 1, 1), (mrandom() + 1) / 2)
		end

		local closest = abs((strokeColor.R + strokeColor.G + strokeColor.B) - (textColor.R + textColor.G + textColor.B)) <= 0.4 and "Text" or
			abs((strokeColor.R + strokeColor.G + strokeColor.B) - (backColor.R + backColor.G + backColor.B)) <= 0.2 and "Back" or
			abs((strokeColor.R + strokeColor.G + strokeColor.B) - (mainColor.R + mainColor.G + mainColor.B)) <= 0.3 and "Main" or
			false

		if closest then
			strokeColor = strokeColor:Lerp(closest == "Text" and textColor or closest == "Back" and backColor or mainColor:Lerp(not isLight and C3n() or C3n(1, 1, 1), (mrandom() + 1.5) / 2.5), (mrandom() + 2) / 3)
		end

		window.Options.Theme.Main = mainColor
		window.Options.Theme.Text = textColor
		window.Options.Theme.Stroke = strokeColor
		window.Options.Theme.Back = backColor

		window:Refresh()
	end })

	toggle = settingsThemeTab:AddCheckBox("LightMode", { Text = "Light Mode", Value = false, NoConfigs = true })
	toggle2 = settingsThemeTab:AddCheckBox("UseRandomColor", { Text = "Use Random Color", Value = false, NoConfigs = true, Callback = function(value)
		cp1.Disabled = not value
	end })

	cp1 = btn:AddColorPicker({ NoConfigs = true, Value = targetColor, Tooltip = "Target color" })

	settingsThemeTab:AddButton("RotateTheme", { Text = "Change Primary Color", Icon = "Repeat", Callback = function()
		if n() then return end

		local pattern
		for i, v in window.Options.Theme do
			local col, p = rotateRGB(v, pattern)
			if not pattern then
				pattern = p
			end

			window.Options.Theme[i] = col
		end

		window:Refresh()
	end })

	settingsOtherTab:AddHeader({ Text = "Info Label" })

	local infoLabelObjs = { }
	local sil = settingsOtherTab:AddToggle("ShowInfoLabel", { Text = "Show Info Label", Value = window.Options.InfoLabel.Options.Visible, Callback = function(val)
		window.Options.InfoLabel.Visible = val
		window.Options.InfoLabel:Refresh()

		for _, v in infoLabelObjs do
			v.Disabled = not val
		end
	end })

	settingsOtherTab:AddSeparator()

	for _, i in { "ShowExecutor", "ShowFPS", "ShowPing", "ShowTime", "ShowPlayers", "", "ShowGap", "ExtraInfoLabelTextEnabled" } do
		if i == "" then
			settingsOtherTab:AddSeparator()
		else
			infoLabelObjs[i] = settingsOtherTab:AddCheckBox("InfoLabel" .. i, { Text = i:gsub("Show", "Show "):gsub("Extra", "Scripted Extra"):gsub("InfoLabel", " "):gsub("TextEnabled", "text enabled") .. " in info label", Value = window.Options.InfoLabel.Options[i], Callback = function(val)
				if i ~= "ExtraInfoLabelTextEnabled" then
					window.Options.InfoLabel[i] = val
				else
					window.Options[i] = val
				end
			end, Disabled = true })
		end
	end

	settingsThemeTab:AddHeader({ Text = "Info Label" })
	local ile = settingsThemeTab:AddTextBox({ PlaceholderText = "Manual Info Label extra text", MultiLine = true, Instant = true, NoConfigs = true, Value = window.Options.InfoLabelExtra or "", Text = "Info label extra text", Callback = function(val)
		window.Options.InfoLabelExtra = val
	end })

	local ilear = settingsThemeTab:AddToggle({ Text = "Enable Rich Text for extra text", NoConfigs = true, Value = window.Options.InfoLabelExtraAntiRich, Callback = function(val)
		window.Options.InfoLabelExtraAntiRich = val
	end })

	settingsThemeTab:AddHeader({ Text = "UI Decorations" })

	local lmt, rest, mt
	local ss = settingsThemeTab:AddSlider({ Text = "Shadow Size", NoConfigs = true, Value = window.Options.ShadowSize, Callback = function(val)
		window.ShadowSize = val
	end, Min = 0, Max = 100, Step = 1, Format = "+" })
	local so = settingsThemeTab:AddSlider({ Text = "Shadow Opacity", NoConfigs = true, Value = 1 - window.Options.ShadowTransparency, Callback = function(val)
		window.ShadowTransparency = 1 - val
	end, Min = 0, Max = 1, Step = 0, Format = ".%" })
	local bo = settingsThemeTab:AddSlider({ Text = "Background Opacity", NoConfigs = true, Value = 1 - window.Options.BackgroundTransparency, Callback = function(val)
		window.BackgroundTransparency = 1 - val
	end, Min = 0, Max = 1, Step = 0, Format = ".%" })

	settingsThemeTab:AddSeparator({ Invisible = true })

	local cr = settingsThemeTab:AddSlider({ Text = "Window Round Corner radius", NoConfigs = true, Value = window.Options.CornerRadius, Callback = function(val)
		window.CornerRadius = val * 100
	end, Min = 0, Max = 1, Step = 0, Format = ".%" })
	local re = settingsThemeTab:AddToggle({ Text = "Round Everything", NoConfigs = true, Value = window.Options.RoundEverything, Callback = function(val)
		window.RoundEverything = val
	end })
	rest = settingsThemeTab:AddToggle({ Text = "Remove Strokes", NoConfigs = true, Value = window.Options.NoStrokes, Callback = function(val)
		window.NoStrokes = val
		mt.Disabled = val
		lmt.Disabled = not rest.Value and not mt.Value
	end })

	settingsThemeTab:AddSeparator({ Invisible = true })

	mt = settingsThemeTab:AddToggle({ Text = "Modern Toggles", NoConfigs = true, Value = window.Options.ModernToggles, Callback = function(val)
		window.ModernToggles = val
		lmt.Disabled = not rest.Value and not mt.Value
	end })
	lmt = settingsThemeTab:AddToggle({ Text = "Large Modern Toggles", NoConfigs = true, Value = window.Options.LargeModernToggles, Callback = function(val)
		window.LargeModernToggles = val
	end })

	lmt.Disabled = not rest.Value and not mt.Value
	settingsThemeTab:AddSeparator({ Invisible = true })

	local bbg = settingsThemeTab:AddToggle("BlurBackground", { Text = "Blur Behind UI", Tooltip = "<b>NOT ALWAYS WORKING</b>\nUsually high quality required for this feature to work", NoConfigs = true, Value = window.Options.BlurBackground, Callback = function(val)
		window.BlurBackground = val
	end })

	local bs = settingsThemeTab:AddSlider({ Text = "Blur Intensity", NoConfigs = true, Value = uiBlur.BlurSize, Callback = function(val)
		uiBlur.BlurSize = val
	end, Min = 0, Max = 1, Step = 0, Format = ".%" })

	local fbs = settingsThemeTab:AddToggle("FullBlurSize", { Text = "Full UI-Sized Blur", NoConfigs = true, Value = window.Options.BlurBackground, Callback = function(val)
		window.FullBlurSize = val
	end })

	settingsThemeTab:AddHeader({ Text = "Background Image" })

	local bie = settingsThemeTab:AddToggle({ Text = "Enabled", NoConfigs = true, Value = window.Options.ImageEnabled, Callback = function(val)
		window.ImageEnabled = val
	end })
	local bic = bie:AddColorPicker({ Value = window.Options.ImageColor, Tooltip = "Image color", Callback = function(color)
		window.ImageColor = color
	end, NoConfigs = true })

	local io = settingsThemeTab:AddSlider({ Text = "Opacity", NoConfigs = true, Value = 1 - window.Options.ImageTransparency, Callback = function(val)
		window.ImageTransparency = 1 - val
	end, Min = 0, Max = 1, Step = 0, Format = ".%" })
	local bi; bi = settingsThemeTab:AddTextBox({ PlaceholderText = gca and "Image <b>URL, rbxassetid://...</b> or <b>image ID</b>" or "<b>rbxassetid://...</b> or <b>image ID</b>", NoConfigs = true, Value = window.Options.Image, Text = "Image", Callback = function(val)
		window.Image = val
	end })

	local backgroundsConverted = { }
	for i in backgrounds do
		tinsert(backgroundsConverted, (i:gsub("(%a)(%d)", "%1 %2")))
	end

	tsort(backgroundsConverted)

	settingsThemeTab:AddDropdown({ Text = "Select an Image", NoConfigs = true, Values = backgroundsConverted, AllowUnselect = true, Callback = function(val, _, self)
		bi:Set(((val or ""):gsub(" ", "")))
	end })

	settingsThemeTab:AddHeader({ Text = "Neon/Stroke" })

	local nt = settingsThemeTab:AddSlider({ Text = "Neon Thickness", Value = window.Options.NeonThickness, Callback = function(val)
		window.NeonThickness = val
	end, Min = 0, Max = 5, Step = 1, Format = "+", NoConfigs = true })

	local neonTypes = {
		"Stroke",
		"Top",
		"None"
	}

	local nt2 = settingsThemeTab:AddDropdown({ Text = "Neon Type", NoConfigs = true, Convert = false, Values = neonTypes, Callback = function(val)
		window.Options.NeonType = neonTypes[val]
		window:Refresh()
	end, Value = tfind(neonTypes, window.Options.NeonType) or 1 })

	local ots = settingsThemeTab:AddToggle("OutsideStroke", { Text = "Outside Stroke enabled", Value = window.Options.OutsideStroke, Callback = function(val)
		window.OutsideStroke = val
	end })

	settingsThemeTab:AddHeader({ Text = "Other Theme settings" })
	settingsOtherTab:AddHeader({ Text = "Other" })

	local um = settingsOtherTab:AddToggle("UnlockMouse", { Text = "Unlock Mouse", Value = window.Options.UnlockMouse, Callback = function(val)
		window.Options.UnlockMouse = val
	end })

	local sides = {
		"Left",
		"Right"
	}

	local ns = settingsThemeTab:AddDropdown("NotificationSide", { Text = "Notifications Default side", NoConfigs = true, Values = sides, Callback = function(val)
		if window.Closed then return end
		window.Options.NotificationSide = val
		window:Notification({ Title = "This is a notification!", Text = "<b>" .. val .. "</b> side!", Duration = 2.5 + (mrandom() * 2.5) })
	end, Value = tfind(sides, window.Options.NotificationSide) or 1 })

	local nos = settingsThemeTab:AddCheckBox("NotificationOG", { Text = "Use Legacy Notification window size", NoConfigs = true, Value = window.Options.NotificationOgScaling, Callback = function(val)
		window.NotificationOgScaling = val
		if window.Closed then return end

		local randomText = ""
		for i = 1, mrandom(1, mrandom(2, mrandom(3, 4))) do
			randomText ..= "Line <b>" .. i .. "</b>\n"
		end

		window:Notification({ Title = "This is a notification!", Text = randomText:sub(1, -2) })
	end })

	local as = settingsThemeTab:AddSlider("AnimationSpeed", { Text = "Animation Speeds", NoConfigs = true, Value = window.Options.AnimationSpeed, Callback = function(val)
		window.Options.AnimationSpeed = val
	end, Min = 0.7, Max = 10, Step = 0.1, Format = ".%" })

	local mv = settingsThemeTab:AddSlider("MasterVolume", { Text = "UI Master Volume", NoConfigs = true, Value = window.Options.Volume, Callback = function(val)
		window.Volume = val
		playSound("Test", window)
	end, Min = 0, Max = 200, Step = 1, Format = "%" })

	settingsThemeTab:AddHeader({ Text = "Mobile Button" })

	local mb = settingsThemeTab:AddToggle("MobileButton", { Text = "Show Mobile Button", NoConfigs = true, Tooltip = "Shows mobile button when UI is minimized", Value = window.Options.MobileButtonVisible, Callback = function(val)
		window.MobileButtonVisible = val
	end, Visible = window.IsDesktop })

	local amb = settingsThemeTab:AddToggle("AlwaysMobileButton", { Text = "Always Show Mobile Button", NoConfigs = true, Value = window.Options.MobileButtonAlwaysVisible, Callback = function(val)
		window.MobileButtonAlwaysVisible = val
	end, Visible = window.IsDesktop })

	local mbn = settingsThemeTab:AddToggle("MobileButtonNeon", { Text = "Show Mobile Button neon", NoConfigs = true, Value = window.Options.MobileButtonNeon, Callback = function(val)
		window.MobileButtonNeon = val
	end })

	settingsOtherTab:AddButton({ Icon = "UI", Text = "Open Console", Callback = function()
		game:GetService("StarterGui"):SetCore("DevConsoleVisible", true)
	end })

	--

	local pr = window.Options.Image
	local function upd()
		if window.Closed or not window.Options.InfoLabel then return end

		ss.Value = window.Options.ShadowSize
		so.Value = 1 - window.Options.ShadowTransparency
		bo.Value = 1 - window.Options.BackgroundTransparency
		io.Value = 1 - window.Options.ImageTransparency
		nt.Value = window.Options.NeonThickness
		nt2.Value = tfind(neonTypes, window.Options.NeonType) or 1
		um.Value = window.Options.UnlockMouse
		ns.Value = tfind(sides, window.Options.NotificationSide) or 1
		as.Value = window.Options.AnimationSpeed
		pl.Visible = #window.PossibleLanguages > 1
		theOnlySeparator.Visible = pl.Visible
		bie.Value = window.Options.ImageEnabled
		bic.Value = window.Options.ImageColor
		mb.Options.Value = window.Options.MobileButtonVisible
		amb.Value = window.Options.MobileButtonAlwaysVisible
		mb.Disabled = amb.Options.Value
		mv.Value = window.Options.Volume
		nos.Value = window.Options.NotificationOgScaling
		ile.Value = window.Options.InfoLabelExtra
		ots.Value = window.Options.OutsideStroke
		cr.Value = window.Options.CornerRadius / 100
		bbg.Value = window.Options.BlurBackground
		sil.Value = window.Options.InfoLabel.Options.Visible
		fbs.Value = window.Options.FullBlurSize
		bs.Value = uiBlur.BlurSize
		re.Value = window.Options.RoundEverything
		rest.Value = window.Options.NoStrokes
		mt.Value = window.Options.ModernToggles
		mt.Disabled = window.Options.NoStrokes
		mt.Disabled = rest.Options.Value
		lmt.Disabled = not rest.Value and not mt.Value
		lmt.Value = window.Options.LargeModernToggles
		mbn.Value = window.Options.MobileButtonNeon
		ilear.Value = window.Options.InfoLabelExtraAntiRich

		for i, v in infoLabelObjs do
			if i == "ExtraInfoLabelTextEnabled" then
				v.Value = window.Options[i]
			else
				v.Value = window.Options.InfoLabel.Options[i]
			end
		end

		for i, v in themeObjects do
			v.Value = window.Theme[i]
		end

		if window.Options.Image ~= pr then
			pr = window.Options.Image
			bi.Value = window.Options.Image
		end

		if #langs ~= #window.PossibleLanguages then                                                                      
			tclear(langs)

			for i, v in window.PossibleLanguages do
				local v = window.Languages[v]
				if not v then
					tremove(window.PossibleLanguages, i)
					break
				end

				tinsert(langs, v[3] .. " " .. v[1] .. " (" .. v[2] .. ")")
			end
		end
	end

	window._Connections[#window._Connections + 1] = window.LanguageAdded:Connect(upd)
	window._Connections[#window._Connections + 1] = window.ThemeChanged:Connect(function()
		window.KeybindMode:Fire(window.KeybindModeActive)
		upd()
	end)

	window._Connections[#window._Connections + 1] = configString.Changed:Connect(upd)

	local function addTabToTab(name, icon)
		settingsMainTab:AddButton({ Text = "Go to " .. name .. " Settings page", Tooltip = name, Callback = function()
			current = name
			reparent()
		end, Icon = icon })
	end

	settingsMainTab:AddSeparator({ Invisible = true })
	settingsMainTab:AddButton({ Text = "Toggle Keybind editing mode", Callback = function()
		window.Options.KeybindMode:Fire(not window.KeybindModeActive)
	end })

	settingsMainTab:AddSeparator({ Invisible = true })
	addTabToTab("Theme", "Brush")
	addTabToTab("Config", "Cog")
	addTabToTab("Other", "Config")

	local c1, c2, c3, c4, c5, c6, c7, c8
	function reparent()
		settingsMainTab.Holder.Visible = current == "Main"
		settingsConfigTab.Holder.Visible = current == "Config"
		settingsThemeTab.Holder.Visible = current == "Theme"
		settingsOtherTab.Holder.Visible = current == "Other"

		if window.Closed then
			if c1 then c1:Disconnect() end
			if c2 then c2:Disconnect() end
			if c3 then c1:Disconnect() end
			if c4 then c2:Disconnect() end
			if c5 then c1:Disconnect() end
			if c6 then c2:Disconnect() end
			if c7 then c1:Disconnect() end
			if c8 then c2:Disconnect() end
			return
		end
	end

	c1 = settingsMainTab.Holder.Changed:Connect(function()
		settingsMainTab.Holder.Size = U2n(1, 0, 1, -1)
		settingsMainTab.Holder.Position = U2o(0, 1)
		settingsMainTab.Holder.ZIndex = 42
		safeReparent(settingsMainTab.Holder, window.Window.RealWindow.Contents.SettingsOverlay.SettingsHub)
		reparent()
	end)

	c2 = settingsMainTab.TabButton.Changed:Connect(function()
		safeReparent(settingsMainTab.TabButton, nil)
		reparent()
	end)

	c3 = settingsConfigTab.Holder.Changed:Connect(function()
		settingsConfigTab.Holder.Size = U2n(1, 0, 1, -1)
		settingsConfigTab.Holder.Position = U2o(0, 1)
		settingsConfigTab.Holder.ZIndex = 42
		safeReparent(settingsConfigTab.Holder, window.Window.RealWindow.Contents.SettingsOverlay.SettingsHub)
		reparent()
	end)

	c4 = settingsConfigTab.TabButton.Changed:Connect(function()
		safeReparent(settingsConfigTab.TabButton, nil)
		reparent()
	end)

	c5 = settingsThemeTab.Holder.Changed:Connect(function()
		settingsThemeTab.Holder.Size = U2n(1, 0, 1, -1)
		settingsThemeTab.Holder.Position = U2o(0, 1)
		settingsThemeTab.Holder.ZIndex = 42
		safeReparent(settingsThemeTab.Holder, window.Window.RealWindow.Contents.SettingsOverlay.SettingsHub)
		reparent()
	end)

	c6 = settingsThemeTab.TabButton.Changed:Connect(function()
		safeReparent(settingsThemeTab.TabButton, nil)
		reparent()
	end)

	c7 = settingsOtherTab.Holder.Changed:Connect(function()
		settingsOtherTab.Holder.Size = U2n(1, 0, 1, -1)
		settingsOtherTab.Holder.Position = U2o(0, 1)
		settingsOtherTab.Holder.ZIndex = 42
		safeReparent(settingsOtherTab.Holder, window.Window.RealWindow.Contents.SettingsOverlay.SettingsHub)
		reparent()
	end)

	c8 = settingsOtherTab.TabButton.Changed:Connect(function()
		safeReparent(settingsOtherTab.TabButton, nil)
		reparent()
	end)

	window._Connections[#window._Connections + 1] = c1
	window._Connections[#window._Connections + 1] = c2
	window._Connections[#window._Connections + 1] = c3
	window._Connections[#window._Connections + 1] = c4
	window._Connections[#window._Connections + 1] = c5
	window._Connections[#window._Connections + 1] = c6
	window._Connections[#window._Connections + 1] = c7
	window._Connections[#window._Connections + 1] = c8

	reparent()
	repeat render() until executionTimes

	window.Options.FirstExecution = executionTimes <= 1
	window.Options.ExecutionTimes = round(executionTimes)

	textList[#textList + 1] = "Library executions: <b>" .. ranTimes .. "</b>"
	einfo.Text = concat(textList, "\n")

	window:Refresh()
end

local function fixNum(n)
	local str = tostring(n)
	local dot = str:find(".", 1, true)

	if dot then
		local before = str:sub(1, dot - 1)
		local after = str:sub(dot + 1)

		if #after > 6 then
			after = after:sub(1, 5):gsub("0+$", "")
		end

		if after ~= "" then
			return before .. "." .. after
		else
			return before
		end
	else
		return str
	end
end

local functions = {
	-- Basic value display
	["."] = function(self)
		return fixNum(self.Value)
	end,

	-- Percent with % symbol (raw)
	["%"] = function(self)
		return round(self.Value) .. "%"
	end,

	-- Rounded percent (0–100 scale, rounded to nearest integer)
	[".%"] = function(self)
		return (round(self.Value * 100)) .. "%"
	end,

	-- Rounded percent with 1 decimal place
	[".1%"] = function(self)
		return ("%.1f%%"):format(self.Value * 100)
	end,

	-- Rounded percent with 2 decimal places
	[".2%"] = function(self)
		return ("%.2f%%"):format(self.Value * 100)
	end,

	-- Fraction display: Value / Max
	["/"] = function(self)
		return fixNum(self.Value) .. " / " .. fixNum(self.Max)
	end,

	-- Fraction as decimal (Value / Max)
	["//"] = function(self)
		return ("%.3f"):format(self.Value / self.Max)
	end,

	-- Fraction as percentage of Max (same as .% but relative to Max)
	["/%"] = function(self)
		return (round(((self.Value - self.Min) / (self.Max - self.Min)) * 100)) .. "%"
	end,

	-- Absolute value (useful for negative numbers)
	["a"] = function(self)
		return tostring(abs(self.Value))
	end,

	-- Signed display: +5, -3
	["+"] = function(self)
		return (self.Value > 0 and "+" or "") .. tostring(self.Value)
	end,

	-- Currency format (e.g., $1,234.56)
	["$"] = function(self)
		local val = self.Value
		local absVal = abs(val)
		local integer = round(absVal)
		return (val < 0 and "-" or "") .. "$" .. ("%d"):format(integer):gsub("(%d)(%d%d%d)(%d%d%d)$", "%1,%2,%3"):gsub("(%d)(%d%d%d)$", "%1,%2") .. "." .. ("%02d"):format(floor((absVal - integer) * 100 + 0.5))
	end,

	-- Scientific notation (for very large/small numbers)
	["e"] = function(self)
		return ("%.2e"):format(self.Value)
	end,

	-- Hexadecimal representation
	["x"] = function(self)
		local n = round(self.Value)
		return ("0x%X"):format(n)
	end,

	-- Comma-separated thousands (e.g., 1,234,567)
	[","] = function(self)
		local val = round(self.Value)
		return (val < 0 and "-" or "") .. ("%d"):format(abs(val)):gsub("(%d)(%d%d%d)(%d%d%d)$", "%1,%2,%3"):gsub("(%d)(%d%d%d)$", "%1,%2")
	end
}

local gui = script.Parent
local defaultWindow = gui.Holder.Window
local defaultDisplay = defaultWindow.RealWindow.Contents.Display
local placeholders = script.Placeholders
local sounds = script.Sounds

local emojis = {
	utf8.char(128156),
	utf8.char(128293),
	utf8.char(127826),
	utf8.char(127872),
	utf8.char(128520),
	utf8.char(128081),
	utf8.char(9889),
	utf8.char(128178)
}

local name = config.Name .. " | "
for i = 1, 10 do
	name = name .. emojis[mrandom(1, #emojis)]
end

gui.Name = name

local tween		= game:GetService("TweenService")
local uis		= game:GetService("UserInputService")
local http		= game:GetService("HttpService")
local textS		= game:GetService("TextService")
local plrs		= game:GetService("Players")
local mps		= game:GetService("MarketplaceService")
local cachedThingy = { }

local function getTextSize(text, size, font, bounds)
	local font = Font.fromEnum(font)
	local index = text .. size .. tostring(font) .. tostring(bounds)
	local value = cachedThingy[index]

	if value then
		return value
	end

	local textParams = Inew("GetTextBoundsParams")
	textParams.Text = text
	textParams.Size = size
	textParams.Font = font
	textParams.RichText = true
	textParams.Width = tonumber(bounds) or bounds.X

	local result = textS:GetTextBoundsAsync(textParams)
	cachedThingy[index] = result
	textParams:Destroy()

	return result
end

local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()
local userIcon = "rbxthumb://type=AvatarHeadShot&id=" .. plr.UserId .. "&w=420&h=420"

local icons			= require(script.Icons)
local langs 		= require(script.Languages)

defaultWindow.RealWindow.Contents.TopbarZone.TitleZone.UIListLayout.FillDirection = Enum.FillDirection.Horizontal
defaultWindow.RealWindow.Contents.TopbarZone.TitleZone.UIListLayout.Wraps = true
defaultWindow.RealWindow.InsideStroke.BorderStrokePosition = Enum.BorderStrokePosition.Inner
defaultDisplay.Pages.Page.NormalZone.Label.ColorPickers.Picker.Display.UIStroke.BorderStrokePosition = Enum.BorderStrokePosition.Center
gui.Enabled = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local function addPlaceholder(obj, newName)
	obj.Name = newName or obj.Name
	safeReparent(obj, placeholders)
end

addPlaceholder(defaultDisplay.Pages.Page.NormalZone.Label.ColorPickers.Picker, "ColorPicker")
addPlaceholder(defaultDisplay.Pages.Page.NormalZone.Label.ColorPickers.KeybindPicker)
addPlaceholder(defaultDisplay.Pages.Page.NormalZone.Label.ColorPickers)

addPlaceholder(defaultDisplay.PageButtons.List.PageButton, "TabButton")
addPlaceholder(defaultDisplay.PageButtons.List.PageHeader, "TabHeader")
addPlaceholder(defaultDisplay.PageButtons.List.PageSeparator, "TabSeparator")
addPlaceholder(defaultWindow.RealWindow.Contents.Display.Pages.Page.NormalZone.Dropdown.View.List.List.Row, "DropdownRow")

addPlaceholder(gui.Holder.MobileButton)
addPlaceholder(sounds)

for _, v in defaultDisplay.Pages.Page.NormalZone:GetChildren() do
	if v:IsA("GuiObject") then
		addPlaceholder(v)
	end
end

for _, v in defaultDisplay.Pages.Page.GroupboxZone.LeftGroupboxZone.Groupbox.Holder.Contents:GetChildren() do
	if v:IsA("GuiObject") then
		v:Destroy()
	end
end

addPlaceholder(defaultDisplay.Pages.Page.GroupboxZone.LeftGroupboxZone.Groupbox)
addPlaceholder(defaultDisplay.Pages.Page, "Tab")
addPlaceholder(defaultDisplay.Pages.CustomPage, "CustomTab")
addPlaceholder(defaultWindow)

addPlaceholder(gui.Holder.ColorPickerWindow)
addPlaceholder(gui.Tooltip)
addPlaceholder(gui.Notifications.NotificationsLeft.Holder, "Notification")

addPlaceholder(gui.FloatingLabel)

safeReparent(script, nil)
pcall(function()
	gui.OnTopOfCoreBlur = true
end)

local isMobile = uis.TouchEnabled and not uis.KeyboardEnabled
local emulator, realPlatform = false, nil
local s, platform = pcall(uis.GetPlatform, uis)
if s then
	realPlatform = platform
	local isMobilePlatform = tfind({ Enum.Platform.IOS, Enum.Platform.Android, Enum.Platform.Ouya }, platform)
	if isMobilePlatform and not isMobile or isMobile and not isMobilePlatform then
		emulator = true
	end
else
	realPlatform = not isMobile and Enum.Platform.Windows or Enum.Platform.Android
end

if platform ~= Enum.Platform.Windows and platform ~= Enum.Platform.IOS and platform ~= Enum.Platform.Android then
	platform = not isMobile and Enum.Platform.Windows or Enum.Platform.Android
end

local device = emulator and (platform == Enum.Platform.Windows and "Mobile" or "PC") or (platform == Enum.Platform.Windows and "PC" or "Mobile")
local executor, version = (env.identifyexecutor or function()
	return (rs:IsStudio() and "Studio" or "") .. "Client", g("version")()
end)()

if not executor then
	executor = (rs:IsStudio() and "Studio" or "") .. "Client"
end

if not version then
	version = g("version")()
end

if device == "Mobile" then
	for i, v in gui.Notifications:GetChildren() do
		v.Size = U2n(v.Size.X.Scale, v.Size.X.Offset - 75, v.Size.Y.Scale, v.Size.Y.Offset)
	end
end

local tooltipObject, coreWindow

local circle = Inew("Frame")
circle.BackgroundTransparency = 0.95
circle.AnchorPoint = V2n(0.5, 0.5)
circle.Size = U2o(0, 10000)
circle.BorderSizePixel = 0
circle.ZIndex = 3
circle.BackgroundColor3 = C3R(255, 255, 255)

Inew("UICorner", circle).CornerRadius = Un(1, 0)
Inew("UIAspectRatioConstraint", circle)

addPlaceholder(circle, "Circle")

safeReparent(placeholders, gui)
safeReparent(gui, (g("gethui") or function() return game:GetService("CoreGui") or game:GetService("Players").LocalPlayer.PlayerGui end)())

local tbMeasurer = Inew("ScreenGui", gui.Parent)
tbMeasurer.ScreenInsets = Enum.ScreenInsets.TopbarSafeInsets
tbMeasurer.ResetOnSpawn = false

local function getPlaceholder(name) : Instance?
	local found = placeholders:FindFirstChild(name)
	if found then
		return found:Clone() 
	end
end

local function tweenOnce(obj: Instance, ti: TweenInfo, props: { any })
	local ti = ti or TIn(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	if ti.Time > 0.005 then
		local tween = tween:Create(obj, ti, props)

		obj = nil
		ti = nil
		props = nil

		tween:Play()
		defer(tween.Destroy, tween)
	else
		for i, v in props do
			obj[i] = v
		end
	end
end

local function paintRichText(text, color)
	return "<font color=\"#" .. C3n(clamp(color.R, 0, 1), clamp(color.G, 0, 1), clamp(color.B, 0, 1)):ToHex() .. "\">" .. text .. "</font>"
end

local references = { }
local ridx = max32

local getWindow do
	local objectCache = setmetatable({ }, { __mode = "kv" })
	getWindow = function(obj)
		local v = objectCache[obj]
		if v ~= nil then
			return v
		end

		local origObj = obj
		obj = obj.Proxy or obj
		obj = references[obj] or obj

		while true do
			if not obj then
				return
			end

			if obj.Class == "Window" then
				objectCache[origObj] = obj.Proxy
				return obj.Proxy
			end

			obj = obj.Parent
			obj = references[obj] or obj
		end
	end
end

local newObject do
	local currentProperty = ""

	local function prop(self, value)
		local inited = references[self] or self
		if inited.Options[currentProperty] == nil then
			error("Expected ':' not '.' calling Set function", 0)
		end

		local proxy = inited.Proxy
		if not proxy then
			inited[currentProperty] = value
			inited:Refresh()
		else
			proxy[currentProperty] = value
		end
	end

	local function getprop(self, value)
		local inited = references[self] or self
		if not inited.Options[currentProperty] then
			error("Expected ':' not '.' calling Get function", 0)
		end

		return inited.Options[currentProperty]
	end

	local printM do
		local function tryTostring(v, t)
			local str = tostring(v)
			if --[[t == "table" and str:sub(1, 7) == "table: "]] false then
				local strList = { }
				local can = false

				for i, va in v do
					if tonumber(i) then
						if can and typeof(va) == "table" then
							local s, e = pcall(http.JSONEncode, http, v)
							if not s then
								can = false
							else
								return e
							end
						end

						strList[#strList + 1] = i .. " = " .. tostring(va)
					end
				end

				return concat(strList, " ; ")
			end

			return str
		end

		function printM(self)
			local inited = references[self]
			if not inited then return warn("== NO METHODS/READONLY PROPERTIES FOUND FOR", self, "==") end

			local methods, props = "    :Get???() -> any -- Gets property/option 'x'\n    :Set???(...) -- Sets property/option 'x'\nExample: object:SetValue(999)\n    :PrintAll()\n", ""
			for i, v in inited do
				if i == "Self" or i == "self" or i:sub(1, 1) == "_" or i == "Proxy" then continue end

				local type = typeof(v)
				if type == "function" then
					methods ..= "    :" .. i .. "(...) -> any?\n"
				elseif i ~= "Options" then
					local stringVer = tryTostring(v, type)
					if #stringVer >= 130 then
						stringVer = stringVer:sub(1, 128) .. "..."
					end

					props ..= "    ." .. i .. " : " .. stringVer .. " : " .. type .. " (read only)\n"
				else
					props ..= "    ." .. i .. " : table (read only)\n"
				end
			end

			print(self, "\n== METHODS & READONLY PROPERTIES OF", inited.Class or "Object", "==\n\nMethods:\n" .. methods, "\nR.O. Properties:\n" .. props, "\n")
		end
	end

	local function idx(self, indx)
		local inited = references[self]
		local index = (indx:sub(1, 1):upper() .. indx:sub(2)):gsub("Caption", "Tooltip"):gsub("HoverText", "Tooltip")
		local id = index:sub(1, 3)

		if index == "PrintAll" then
			return printM
		elseif (id ~= "Set" and id ~= "Get") or #indx == 3 or inited[index] ~= nil then
			local val = inited[indx]
			if val ~= nil then
				return val
			else
				local val = inited.Options[indx]
				if val == nil then
					if inited.Objects then
						val = inited.Objects[indx]
						if val == nil then
							error(("No properties, methods or options called '%s'"):format(indx), 0)
						end
					end
				end

				return val
			end
		elseif id == "Set" then
			indx = indx:sub(4)
			if inited.Options[indx] ~= nil then
				currentProperty = indx
				return prop
			else
				error(("No properties, methods or options called '%s'"):format(indx), 0)
			end
		elseif id == "Get" then
			indx = indx:sub(4)
			if inited.Options[indx] ~= nil then
				currentProperty = indx
				return getprop
			else
				error(("No properties, methods or options called '%s'"):format(indx), 0)
			end
		end
	end

	local deferedRefreshes = { }
	local function objectRefresh(inited, s)
		inited:Refresh()
		deferedRefreshes[s] = nil
	end

	local function newidx(self, key, val)
		local key = (key:sub(1, 1):upper() .. key:sub(2)):gsub("Caption", "Tooltip"):gsub("HoverText", "Tooltip")

		local inited = references[self] or self
		local newValue = key == "Enabled" and not val or key ~= "Enabled" and (val ~= nil and val or false)

		if inited.Options[key] ~= newValue then
			inited.Options[key] = newValue

			local s = tostring(inited)
			if not deferedRefreshes[s] then
				deferedRefreshes[s] = true
				defer(objectRefresh, inited, s)
			end
		end
	end

	local function getOptions(window, self, ...)
		local counters = window and window.Counters or { }

		local options, flag = select(1, ...)
		if typeof(options) == "string" then
			options, flag = flag, options
		end

		local options = setmetatable(typeof(options) == "table" and options or { }, { __index = self.DefaultOptions })
		local ID = typeof(flag) == "string" and flag or options.ID or options.id or options.Flag or options.flag or options.Id or options.Idx or options.Index or options.idx or options.index
		if not ID then
			local str = options.Text ~= "" and options.Text or options.Title ~= "" and options.Title or ""
			if #str == 0 then
				str = "Object"
			end

			str = clean(str)

			counters[str] = (counters[str] or -1) + 1
			ID = str .. (counters[str] ~= 0 and counters[str] or "")
		end

		ID = clean(tostring(ID), false)

		local flag: string = ID
		options.Flag = flag

		ID = ID:lower():gsub("[\0-\47\58-\64\92-\94\96\123-\255]", "") .. "_id"
		counters[ID] = (counters[ID] or -1) + 1
		ID ..= counters[ID]

		local hash = compressor:Hash(ID)
		local h = hash:sub(1, clamp(#flag, 2, 3) - 1)
		counters[h] = (counters[h] or -1) + 1
		h ..= (counters[h] ~= 0 and counters[h] or "")

		options.FlagHashShort = h
		options.FlagHash = hash:sub(1, 16)
		options.FlagHashLong = hash
		options.FlagHashFull = hash

		if options.Default ~= nil then
			options.Value, options.Default = options.Default, nil
		end

		return options
	end

	local tostrLookups = { }
	local function tostrmt(self)
		local self = references[self] and self or self.Proxy
		local str = tostrLookups[self]
		local ref = references[self]

		if not str or not ref then
			return "???: 0x????????????????"
		end

		return (str:gsub("userdata", ref.Class or "Object"))
	end

	newObject = function(instructions, parent, ...)
		local window = parent and getWindow(parent)
		local inited = instructions:Init(getOptions(parent and getWindow(parent), instructions, ...))
		for i, v in instructions do
			if i ~= "Init" and i ~= "DefaultOptions" then
				inited[i] = inited[i] or v
			end
		end

		local object = newproxy(true)
		tostrLookups[object] = tostring(object)

		local meta : { any } = getmetatable(object)
		meta.__metatable = getmetatable(game)
		meta.__index = idx
		meta.__newindex = newidx
		meta.__tostring = tostrmt
		meta.__metatable = "LOL!"

		tfreeze(meta)
		references[object] = inited
		inited.Proxy = object
		inited.Parent = parent

		if window then
			tinsert(window.AllObjects, object)
			window.ObjectAdded:Fire(object)
		end

		return object:Refresh() or object
	end
end

local function addFunctions(toAdd, list)
	for i, v in list do
		if typeof(i) == "string" and i ~= "DefaultOptions" and i ~= "Init" and toAdd[i] == nil then
			toAdd[i] = i == "Translations" and tclone(v) or v
		end
	end

	toAdd.Self = toAdd
	return toAdd
end

local function handleAnimationSpeed(value)
	if value < 0.1 or value >= 10 then
		return inf -- instant animation
	end

	return value
end

local function OR(...)
	local cons = { }
	local done = false

	local function cn()
		for i, v in cons do
			if v.Connected then
				v:Disconnect()
			end
		end

		done = true
	end

	for i = 1, select("#", ...) do
		cons[#cons + 1] = select(i, ...):Connect(cn)
	end

	repeat render() until done
end

local function castCircle(button, window, holder)
	local circle = getPlaceholder("Circle")
	safeReparent(circle, holder or button)

	local mp = V2n(mouse.X, mouse.Y)
	local pos = V2n(mp.X - button.AbsolutePosition.X, mp.Y - button.AbsolutePosition.Y)
	local relative = U2s(pos.X / button.AbsoluteSize.X, pos.Y / button.AbsoluteSize.Y)

	circle.Position = relative
	circle.BackgroundColor3 = window.Theme.Text

	local time = 0.35 / handleAnimationSpeed(window.AnimationSpeed)
	tweenOnce(circle, TIn(time), { Size = U2n(2.5, 0, 0, 10000), BackgroundTransparency = 0.9 })
	OR(button.MouseButton1Up, button.MouseLeave, button.Destroying)
	tweenOnce(circle, TIn(time * 2.5), { BackgroundTransparency = 1 })
	wait(time * 2.5)

	circle:Destroy()
end

local function quickCount(str1, str2)
	if str2 == "" then return 0 end

	local count = 0
	local start = 1
	local len = #str2

	while true do
		local pos = str1:find(str2, start, true)
		if not pos then break end

		count += 1
		start = pos + len
	end

	return count
end

local getIcon, setIcon do
	local encodingServ = game:GetService("EncodingService")
	local blockExstensions = {
		"com", "ru", "web", "online", "org", "net", "biz", "info", "pro", "mobi", "us", "ca", "co", "cc", "tv", "fr", "to", "jp", "it", "de", "se", "no", "es", "pt"
	}

	local imageCache = { }
	local tryDownloadImage = gca and function(url)
		local ext = "png"
		local start, stop = url:reverse():find("%.")
		local att = url:sub(-stop + 1)

		local br = att:find("?", 0, true) or att:find("&", 0, true) or att:find("=", 0, true) or att:find("/", 0, true) or att:find("\\", 0, true)
		if br then
			att = att:sub(1, br - 1)
		end

		ext = tfind(blockExstensions, att) and "png" or att
		local fileHash = cacheRoute .. (encodingServ:ComputeStringHash(url, Enum.HashAlgorithm.Md5):gsub(".", function(str) return ("%02x"):format(str:byte()) end)) .. "." .. ext

		if imageCache[fileHash] then
			return imageCache[fileHash]
		end

		if IF(fileHash) then
			local asset = gca(fileHash)
			imageCache[fileHash] = asset

			return asset
		end

		local success, result = pcall(function()
			local content = game:HttpGet(url, true)
			if #content < 128 then
				error("Image size too small!", 0)
				return ""
			end

			wf(fileHash, content, true)

			local asset = gca(fileHash)
			imageCache[fileHash] = asset

			return asset
		end)

		if not success then
			warn("Download", "\"" .. url .. "\"", "failed:", result)
		end

		return success and result or ""
	end or function(url)
		warn("Unable to download", "\"" .. url .. "\"!")
		return ""
	end

	downloadImage = function(...)
		local s, e = pcall(tryDownloadImage, ...)
		return s and e or ""
	end

	local lucideIcons = require(script.LucideIcons)
	local allIcons = lucideIcons[1]
	local iconPositions = lucideIcons[2][48]

	local function valueSafeCheck(value, list)
		if type(value) ~= "string" then
			return ""
		end

		local ret = value
		if list then
			local upper = value:sub(1, 1):upper() .. value:sub(2)
			if list[upper] then
				ret = list[upper]
			end
		end

		local lucide
		if tonumber(ret) then
			ret = "rbxassetid://" .. ret
		elseif value:sub(1, 4):lower() == "l://" then
			local found = tfind(allIcons, value:sub(5):lower())
			if found then
				lucide = found
			else
				return ""
			end
		elseif tfind(allIcons, value) then
			lucide = tfind(allIcons, value)
		elseif ret:sub(1, 4) == "http" and not ret:find("roblox.", 0, true) then
			return ret, true
		end

		if lucide then
			return false, false, iconPositions[lucide]
		end

		if ret:sub(1, 13) == "rbxassetid://" and not tonumber(ret:sub(14)) then
			ret = ""
		end

		return ret
	end

	local spriteSheets = {
		[1] = "rbxassetid://115353617237502",
		[2] = "rbxassetid://110997322179595"
	}

	local function _getIcon(value, list, dontUseLucide)
		local val, download, isLucide = valueSafeCheck(value, list)
		if isLucide then
			if dontUseLucide then
				return ""
			end

			local imageIndex, rectSize, rectOffset = unpack(isLucide)
			return spriteSheets[imageIndex], rectSize, rectOffset
		end

		if download then
			val = downloadImage(val)
		end

		return val
	end

	playSound = function(sound, holder)
		holder = getWindow(holder or coreWindow)
		sound = tostring(sound)

		if holder.Window.Sounds:FindFirstChild(sound) then
			sound = holder.Window.Sounds[sound]
		end

		if typeof(sound) == "Instance" then
			if sound:IsA("Sound") then
				sound = sound.SoundId
			else
				sound = ""
			end
		end

		sound = _getIcon(sound)
		if #sound <= 11 then return end

		local snd = Inew("Sound", holder.Window.SoundCache)
		snd.SoundGroup = holder.Window.SoundCache
		snd.SoundId = sound
		snd.Volume = 0.5
		snd:Play()

		snd.Ended:Wait()
		snd:Destroy()
	end

	local cache = { }
	getIcon = function(value, list, object, dontUseLucide)
		value = value or ""
		local str = tostring(value) .. tostring(list)

		if tonumber(value) then
			cache[str] = { "rbxassetid://" .. value }
		end

		if cache[str] then
			return unpack(cache[str])
		end

		spawn(function()
			cache[str] = { "" }
			cache[str] = { _getIcon(value, list, dontUseLucide) }

			if object then
				object:Refresh()
			end
		end)

		local c = cache[str]
		if c then
			return unpack(c)
		end

		return ""
	end

	setIcon = function(value, list, object, instance, dontUseLucide)
		local image, imageRectSize, imageRectOffset = getIcon(value, list, object, dontUseLucide)
		image = image or ""

		instance.Image = image
		instance.ImageRectOffset = imageRectOffset and V2n(unpack(imageRectOffset)) or V2n()
		instance.ImageRectSize = imageRectSize and V2n(unpack(imageRectSize)) or V2n()

		return clean(image)
	end
end

local function translate(self, category)
	local window = getWindow(self)
	local language = window.Options.Language or "EN"
	local options = self.Options

	local translationsPage = options.Translations and (options.Translations[language] or options.Translations.EN)
	if not translationsPage then
		return options[category] or ""
	end

	return typeof(translationsPage) == "string" and translationsPage ~= "" and category:sub(1, 1):upper() .. category:sub(2) == "Text" and translationsPage or typeof(translationsPage) == "table" and translationsPage[category] or options[category] or ""
end

local function hoverLogic(object, instance)
	local window = getWindow(object)
	local cons = window._Connections
	local mouseIn = false

	cons[#cons + 1] = instance.MouseEnter:Connect(function()
		if not object.Options.Disabled then
			spawn(playSound, "Hover", window)
		end

		mouseIn = true

		render()

		local tt = object.Options.Disabled and translate(object, "DisabledTooltip")
		if not tt or #tt == 0 then tt = translate(object, "Tooltip") or "" end

		tooltipObject.Options.Window = window
		tooltipObject.Options.Dark = object.Options.Disabled
		tooltipObject.Text = tt
	end)

	cons[#cons + 1] = instance.MouseLeave:Connect(function()
		mouseIn = false

		tooltipObject.Options.Window = coreWindow
		tooltipObject.Options.Dark = false
		tooltipObject.Text = ""
	end)
end

local _refreshEverything; _refreshEverything = function(enumerable)
	pcall(enumerable.Refresh, enumerable)

	local cl = enumerable.Class
	if cl == "ColorPicker" or cl == "Keybind" then
		for i, v in enumerable.ColorPickers do
			pcall(_refreshEverything, v)
		end
	end

	for i, v in enumerable.Objects do
		pcall(_refreshEverything, v)
	end
end

local function refreshEverything(window)
	pcall(_refreshEverything, window)
end

local function addPossibleTranslations(object)
	local window = getWindow(object)
	if not window then return end

	if object.Translations then
		for lang in object.Translations do
			if langs[lang] and not tfind(window.PossibleLanguages, lang) then
				tinsert(window.PossibleLanguages, lang)
				window.LanguageAdded:Fire(window.PossibleLanguages, lang)
			end
		end
	end
end

local allIcons = { }
for icon in icons do
	tinsert(allIcons, icon)
end

tfreeze(allIcons)

local allBackgrounds = { }
for icon in backgrounds do
	tinsert(allBackgrounds, icon)
end

tfreeze(allBackgrounds)

local inputting = false
local blockedKeys = {
	Enum.KeyCode.Unknown,
	Enum.KeyCode.Power,
	Enum.KeyCode.Left,
	Enum.KeyCode.Right,
	Enum.KeyCode.Up,
	Enum.KeyCode.Down,
	Enum.KeyCode.F11,
	Enum.KeyCode.F9,
	Enum.KeyCode.CapsLock,
	Enum.KeyCode.ScrollLock,
	Enum.KeyCode.NumLock
}

local gsubs = {
	Left = "L", Right = "R", Minus = "-",
	Slash = "/", BackSlash = "\\", Period = ".",
	Zero = "0", One = "1", Two = "2",
	Three = "3", Four = "4", Five = "5",
	Six = "6", Seven = "7", Eight = "8",
	Nine = "9", Equals = "=", LeftBracket = "[",
	RightBracket = "]", LBracket = "[", RBracket = "]",
	Quote = "'", Backquote = "`", Comma = ",",
	Semicolon = ";", Plus = "+", Asterisk = "*",
	Multiply = "*", Divide = "/", Keypad = "Kp",
	Return = "Enter", Escape = "Esc",
	Insert = "Ins", Delete = "Del",
	PageUp = "PgUp", PageDown = "PgDown"
}

gsubInput = function(inp)
	for i, v in gsubs do
		inp = inp:gsub(i, v)
	end

	return inp
end

uis.InputBegan:Connect(function(inp, chat)
	if not inputting or tfind(blockedKeys, inp.KeyCode) then
		return
	end

	if chat or inputting.Disabled then
		local i = inputting
		inputting = false
		i:Refresh(true)

		return
	end

	local i = inputting
	inputting = false
	i:Call(inp.KeyCode.Value)
end)

local function addDefault(object, table)
	if object.Options.Value ~= nil and object.Set then
		table[object] = object.Options.Value
	end
end

local function addCons(object, cons)
	local window = getWindow(object)
	local connections = window._Connections

	for i, v in cons do
		tinsert(connections, v)
	end

	pcall(addDefault, object, window.Defaults)
end

local units = {
	{ 30 * 24 * 60 * 60, "mo" },
	{ 24 * 60 * 60, "d" },
	{ 60 * 60, "h" },
	{ 60, "m" },
	{ 1, "s" }
}

local function formatTime(sec)
	sec = floor(sec)

	if sec >= 1e9 then
		return "NEVER"
	elseif sec >= 1e8 then
		return "1y+"
	end

	local parts = { }
	for _, u in units  do
		local val = floor(sec / u[1])
		if val > 0 then
			tinsert(parts, tostring(val) .. u[2])
			sec %= u[1]
		end
	end

	while #parts > 3 do
		tremove(parts, #parts)
	end

	return #parts > 0 and concat(parts, " ") or "EXPIRED"
end

local function themeSync(object)
	local window = getWindow(object)
	window._Connections[#window._Connections + 1] = window.ThemeChanged:Connect(function()
		object:Refresh()
	end)
end

local function orderUpdate(a, b)
	if a.LayoutOrder ~= b and b then
		a.LayoutOrder = b
	end
end

local acp
local colorPickerBase = {
	DefaultOptions = {
		Value = C3n(1, 1, 1),
		Callback = function(color) end,
		Disabled = false,
		Visible = true,
		Tooltip = "",
		DisabledTooltip = "",
		Order = 0,

		_connected = false
	},
	AddColorPicker = function(self, ...)
		return acp(self.Parent, ...)
	end,
	ColorPicker = function(self, ...)
		return self:AddColorPicker(...)
	end,
	NewColorPicker = function(self, ...)
		return self:AddColorPicker(...)
	end,
	Set = function(self, value)
		local old = self.Options.Value
		self.Options.Value = value
		self:Refresh()

		if old ~= self.Options.Value then
			self.Changed:Fire(self.Options.Value, self)
			spawn(self.Options.Callback, self.Options.Value, self)
		end
	end,
	Init = function(self, options)
		local instance = getPlaceholder("ColorPicker")
		local object = addFunctions({
			Options = options,
			Class = "ColorPicker",
			Instance = instance,
			Changed = event.new()
		}, self)

		defer(hoverLogic, object, instance)

		local picking = false
		local cons = { }
		defer(addCons, object, cons)

		cons[#cons + 1] = instance.MouseButton1Click:Connect(function()
			if picking or object.Options.Disabled then return end
			picking = true
			spawn(playSound, "Click", object)

			local tt =  object.Options.Tooltip
			local color = getWindow(object.Proxy):ColorPicker({ Value = object.Options.Value, Text = #tt > 0 and tt or object.Proxy.Parent and object.Proxy.Parent.Text or "Color Picker" })
			if color then
				object:Call(color)
			end

			picking = false
		end)

		defer(themeSync, object)
		return object
	end,
	Call = function(self, color)
		self:Refresh()

		if self.Options.Disabled then return end

		self.Options.Value = color
		self:Refresh()
		spawn(self.Options.Callback, color, self)
	end,
	Refresh = function(self)
		local window = getWindow(self)
		local sinst = self.Instance
		local inst = sinst.Display
		local options = self.Options
		local woptions = window.Options

		inst.BackgroundColor3 = options.Value
		inst.UIStroke.Color = window.Theme.Stroke
		inst.Darker.Visible = options.Disabled
		inst.Parent.Visible = options.Visible
		inst.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
		inst.UIStroke.Enabled = not woptions.NoStrokes
		orderUpdate(inst, options.Order)

		local parent = self.Parent
		if not parent then return end

		local instance = parent.Instance
		local pickers = instance:FindFirstChild("ColorPickers") or getPlaceholder("ColorPickers")

		safeReparent(pickers, instance)
		safeReparent(sinst, pickers)
	end
}

acp = function(...)
	local colorPicker = newObject(colorPickerBase, ...)
	tinsert((...).ColorPickers, colorPicker)

	return colorPicker
end

local keybindBase = {
	DefaultOptions = {
		Reference = false,
		Visible = false,
		Value = false,

		KeySet = function() end
	},
	Set = function(self, value)
		local old = self.Options.Value
		self.Options.Value = value
		self:Refresh()

		if old ~= self.Options.Value then
			self.Changed:Fire(self.Options.Value ~= false and Enum.KeyCode:FromValue(self.Options.Value) or nil, self.Proxy)
			spawn(self.Options.KeySet, self.Options.Value ~= false and Enum.KeyCode:FromValue(self.Options.Value) or nil, self.Proxy)
		end

		local window = getWindow(self)
		window.KeybindMode:Fire(window.KeybindModeActive)
	end,
	Callback = function(self, state)
		local options = self.Options
		if not options.Reference then return end

		local r = options.Reference
		if not state and r.Class ~= "Button" then return end
		r:Click(state)
	end,
	Init = function(self, options)
		local instance = getPlaceholder("KeybindPicker")
		local object = addFunctions({
			Options = options,
			Instance = instance,
			Class = "Keybind",
			Changed = event.new()
		}, self)

		local cons = { }
		defer(addCons, object, cons)

		cons[#cons + 1] = instance.MouseButton1Click:Connect(function()
			object.Proxy:Click()
		end)

		defer(object.Setup, object)

		return object
	end,
	Setup = function(self)
		self = self.Proxy

		local window = getWindow(self)
		local started = false
		window._Connections[#window._Connections + 1] = uis.InputBegan:Connect(function(input, chat)
			if chat or input.KeyCode.Value ~= self.Options.Value or started then return end

			started = true
			self:Callback(true)
		end)

		window._Connections[#window._Connections + 1] = uis.InputEnded:Connect(function(input, chat)
			if input.KeyCode.Value ~= self.Options.Value or not started then return end

			started = false
			self:Callback(false)
		end)

		window._Connections[#window._Connections + 1] = self.Options.Reference.Changed:Connect(function()
			window.KeybindMode:Fire(window.KeybindModeActive) -- cast a refresh
		end)

		tinsert(window.KeybindObjects, self)
	end,
	Call = function(self, value)
		self.Options.Value = value
		self.Proxy:Refresh()

		self.Changed:Fire(self.Options.Value ~= false and Enum.KeyCode:FromValue(self.Options.Value) or nil, self.Proxy)

		local window = getWindow(self)
		window.KeybindMode:Fire(window.KeybindModeActive)
	end,
	Click = function(self)
		if self.Options.Disabled then return end

		local i = inputting
		inputting = self
		spawn(playSound, "Click", self)

		if i then
			if i == inputting then
				inputting = false
				self:Call(false)
			else
				i:Refresh(true)
			end
		end

		self:Refresh(true)
	end,
	Refresh = function(self, set)
		local window = getWindow(self)
		local sinst = self.Instance
		local inst = sinst.Display
		local options = self.Options
		local woptions = window.Options

		local theme = window.Theme
		local themeS = theme.Stroke

		inst.TextColor3 = theme.Main
		inst.UIStroke.Color = themeS
		inst.Parent.Visible = window.IsDesktop and window.KeybindModeActive
		inst.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
		inst.UIStroke.Enabled = not woptions.NoStrokes
		inst.BackgroundColor3 = themeS
		orderUpdate(inst, -max32)

		local v = options.Value
		if typeof(v) == "EnumItem" then
			v = v.Value
		elseif tonumber(v) then
			v = tonumber(v)
		elseif Enum.KeyCode:FromName(tostring(v)) then
			v = Enum.KeyCode:FromName(tostring(v)).Value
		else
			v = false
		end

		options.Value = v
		if inputting == self then
			inst.Text = "..."
		else
			inst.Text = (not options.Value or not Enum.KeyCode:FromValue(options.Value)) and "None" or gsubInput(Enum.KeyCode:FromValue(options.Value).Name)
		end

		if set then
			window.KeybindMode:Fire(window.KeybindModeActive)
		end

		local ref = options.Reference
		if not ref then return end

		local gb = ref.Parent.Class == "Groupbox"
		local pad = Un(0, gb and 2 or 3)

		inst.UIPadding.PaddingBottom = pad
		inst.UIPadding.PaddingTop = pad
		inst.UIPadding.PaddingLeft = pad
		inst.UIPadding.PaddingRight = pad
		inst.Parent.UIAspectRatioConstraint.AspectRatio = gb and 2 or 1.65

		local instance = ref.Instance
		local pickers = instance:FindFirstChild("ColorPickers") or getPlaceholder("ColorPickers")

		safeReparent(pickers, instance)
		safeReparent(sinst, pickers)
	end
}

local keybindSetup; keybindSetup = function(object, depth)
	depth = depth or 10
	if depth ~= 0 then
		return defer(keybindSetup, object, depth - 1)
	end

	local object = object.Proxy
	local obj = newObject(keybindBase, object, { Reference = object })
	object.ColorPickers[0] = obj

	return obj
end

local basicObjects = {
	Button = {
		DefaultOptions = {
			Text = "Button",
			Callback = function() end,
			Visible = true,
			RecolorIcon = true,
			Disabled = false,
			Holdable = false,
			Value = false,
			Tooltip = "",
			DisabledTooltip = "",
			Icon = "Cursor",
			Order = false,
			Translations = tfreeze({ })
		},
		AddColorPicker = acp,
		ColorPicker = acp,
		NewColorPicker = acp,
		GetObjectFromHash = getObjectFromHash,
		Init = function(self, options)
			local instance = getPlaceholder("Button")
			local object = addFunctions({
				ColorPickers = { },
				Options = options,
				Instance = instance,
				Class = "Button",
				Changed = event.new()
			}, self)

			defer(hoverLogic, object, instance)
			defer(keybindSetup, object)

			local cons = { }
			defer(addCons, object, cons)

			cons[#cons + 1] = instance.MouseButton1Click:Connect(function()
				if object.Options.Holdable then return end
				object:Click()
			end)

			local holding = false
			cons[#cons + 1] = instance.MouseButton1Down:Connect(function()
				if holding then return end
				object.Options.Value = true
				object.Changed:Fire(true)

				if not object.Options.Holdable then return end

				holding = true
				object:Click(true)
			end)

			cons[#cons + 1] = instance.MouseButton1Up:Connect(function()
				if not holding then return end
				object.Options.Value = false
				object.Changed:Fire(false)

				holding = false
				object:Click(false)
			end)

			cons[#cons + 1] = instance.MouseButton1Down:Connect(function()
				if object.Proxy.Disabled then return end
				castCircle(instance, getWindow(object))
			end)

			return object
		end,
		Call = function(self, isDown, dontFire)
			if not dontFire then
				self.Changed:Fire(isDown == nil and self.Proxy or isDown, isDown ~= nil and self.Proxy, self.Proxy)
			end

			self.Options.Callback(isDown == nil and self.Proxy or isDown, isDown ~= nil and self.Proxy, self.Proxy) -- cuz
		end,
		Click = function(self, isDown, dontFire)
			self.Options.Value = not self.Options.Disabled and isDown
			self.Proxy:Refresh()

			if self.Options.Disabled then return end
			if isDown == false and not self.Options.Holdable then
				self.Changed:Fire(false, self.Proxy)
				return
			end

			if not self.Options.Disabled then
				spawn(playSound, "Click", self)
			end

			self:Call(self.Options.Holdable and (isDown == nil and true or isDown ~= nil and not not isDown) or not self.Options.Holdable and nil, dontFire)
		end,
		Refresh = function(self)
			local par = self.Parent
			local pclass = par.Class

			local y = pclass == "Groupbox" and 25 or 40
			local y2 = pclass == "Groupbox" and 14 or 16
			local x = pclass == "Groupbox" and 7 or 15

			local window = getWindow(self)
			local inst = self.Instance
			local view = inst.View
			local opts = self.Options

			local themeT = window.Theme.Text
			inst.Separator.BackgroundColor3 = themeT
			view.Label.TextColor3 = themeT
			view.Icon.ImageColor3 = opts.RecolorIcon and themeT or C3n(1, 1, 1)

			inst.Size = U2n(1, 0, 0, y)
			view.Size = U2n(100, 0, 0, y2)
			view.Position = U2n(0, x, 0.5, 0)
			inst.Visible = opts.Visible

			orderUpdate(inst, opts.Order)
			safeReparent(inst, pclass == "Groupbox" and par.Holder.Holder.Contents or par.Holder.NormalZone)

			view.Label.Text = translate(self, "Text")
			view.Label.TextTransparency = opts.Disabled and 0.35 or 0
			view.Icon.ImageTransparency = opts.Disabled and 0.35 or 0

			setIcon(opts.Icon, icons, self, view.Icon)
		end
	},
	Dropdown = {
		DefaultOptions = {
			Text = "Dropdown",
			NoConfigs = false,
			Callback = function(valueOrValues) end,
			Visible = true,
			Disabled = false,
			Tooltip = "",
			DisabledTooltip = "",
			Multi = false,
			Opened = false,
			Value = false, -- automatically converts into a table/number when needed
			AllowUnselect = false, -- Only for non-multi
			Convert = true,
			AutoHide = true, -- Only for non-multi
			Values = { 1, 2, 3 }, -- List of possible values (numbers, strings, etc.)
			Variants = { }, -- Deprecated, use Values
			Order = false,
			Translations = { }
		},
		Set = function(self, value)
			local old = self.Options.Value
			self.Options.Value = value
			self:Refresh()

			if old ~= self.Options.Value then
				local value = self.Options.Value
				local converted = self:Convert(value)

				if self.Options.Convert then
					value, converted = converted, value
				end

				self.Changed:Fire(value, converted, self)
				spawn(self.Options.Callback, value, converted, self)
			end
		end,
		Init = function(self, options)
			local instance = getPlaceholder("Dropdown")
			local object = addFunctions({
				Options = options,
				Instance = instance,
				Class = "Dropdown",
				DynamicConnections = { },
				Changed = event.new()
			}, self)

			defer(hoverLogic, object, instance)

			local cons = { }
			defer(addCons, object, cons)

			cons[#cons + 1] = instance.MouseButton1Click:Connect(function()
				object:Click()
			end)

			cons[#cons + 1] = instance.MouseButton1Down:Connect(function()
				if object.Proxy.Disabled then return end
				castCircle(instance, getWindow(object))
			end)

			return object
		end,

		Click = function(self)
			if self.Options.Disabled then
				self.Options.Opened = false
				return self.Proxy:Refresh()
			end

			spawn(playSound, "Click", self)
			self.Options.Opened = not self.Options.Opened
			self.Proxy:Refresh()
		end,

		Call = function(self, value, converted)
			if self.Options.Disabled then return end
			self.Changed:Fire(value, converted, self.Proxy)
			self.Options.Callback(value, converted, self.Proxy)
		end,

		Convert = function(self, value, toDisplay)
			local opts = self.Options
			if toDisplay then
				if opts.Multi then
					local texts = { }
					for _, idx in value do
						tinsert(texts, tostring(opts.Values[idx]))
					end

					return #texts > 0 and (#texts < #opts.Values and concat(texts, ", ") or "*Everything*") or "None"
				else
					return tostring(opts.Values[value] or "None")
				end
			else
				if opts.Multi then
					local val = { }
					for i, v in self.Options.Values do
						val[v] = not not tfind(value, i)
					end

					return val
				else
					if value and value >= 1 and value <= #opts.Values then
						return opts.Values[tonumber(value)] or tonumber(value) or value
					elseif opts.AllowUnselect then
						return false
					else
						return nil
					end
				end
			end
		end,

		Refresh = function(self)
			local parnt = self.Parent
			local ispgb = parnt.Class == "Groupbox"
			local y = ispgb and 44 or 50
			local y2 = ispgb and 14 or 16
			local y3 = ispgb and 10 or 14

			local options = self.Options
			local window = getWindow(self)
			local inst = self.Instance
			local view = inst.View
			local label = view.Label
			local viewList = view.List

			local labelL = label.Label
			local viewLNC = viewList.NoContents
			local viewLS = viewList.Selected
			local viewLL = viewList.List
			local licon = label.Icon

			local viewLSVal = viewLS.Value
			local vuis = viewList.UIStroke

			local theme = window.Theme
			local themeT = theme.Text
			local themeS = theme.Stroke
			local themeM = theme.Main

			orderUpdate(inst, options.Order)
			inst.Separator.BackgroundColor3 = themeT
			labelL.TextColor3 = themeT
			licon.ImageColor3 = themeT
			licon.Opened.ImageColor3 = themeT
			viewList.BackgroundColor3 = themeS
			viewLNC.TextColor3 = themeM
			viewLNC.TextStrokeColor3 = themeS
			viewLSVal.TextColor3 = themeM
			viewLSVal.TextStrokeColor3 = themeS
			vuis.Color = themeS

			if options.Value ~= false and typeof(options.Value) ~= "number" and typeof(options.Value) ~= "table" then
				options.Value = tfind(options.Values, options.Value) or false
			end

			if options.Multi then
				if type(options.Value) ~= "table" then
					options.Value = options.Value and { options.Value } or { }
				end
			else
				if type(options.Value) == "table" then
					options.Value = options.Value[1] or false
				end
			end

			if options.Value ~= false and typeof(options.Value) ~= "number" and typeof(options.Value) ~= "table" then
				options.Value = tfind(options.Values, options.Value) or false
			end

			if typeof(options.Value) == "table" then
				local isBool = false
				for i, v in options.Value do
					isBool = typeof(v) == "boolean"
					break
				end

				if isBool then
					local newValue = { }
					for i, v in options.Value do
						if v then
							tinsert(newValue, i)
						end
					end

					options.Value = newValue
				end

				for i, v in options.Value do
					if v ~= false and typeof(v) ~= "number" then
						options.Value[i] = tfind(options.Values, v) or nil
					end
				end
			end

			if options.Variants and #options.Variants > 0 then
				options.Values = options.Variants
				options.Variants = { }
			end

			inst.Visible = options.Visible
			safeReparent(inst, ispgb and parnt.Holder.Holder.Contents or parnt.Holder.NormalZone)
			labelL.Text = translate(self, "Text")
			labelL.TextTransparency = options.Disabled and 0.35 or 0
			licon.ImageTransparency = options.Disabled and 0.35 or 0
			viewLSVal.TextTransparency = options.Disabled and 0.35 or 0

			local displayText = self:Convert(options.Value, true)
			viewLSVal.Text = displayText or "None"

			viewLL.Visible = false
			viewLS.Visible = false
			viewLNC.Visible = false
			view.Position = ispgb and U2o(7, 4) or U2o(15, 8)
			view.Size = ispgb and U2n(1, -14, 0, 14) or U2n(1, -30, 0, 16)
			licon.ImageTransparency = options.Opened and 1 or 0
			licon.Opened.Visible = options.Opened
			viewList.UICorner.CornerRadius = cornerState[window.Options.RoundEverything]
			vuis.Enabled = not window.Options.NoStrokes

			local dc = self.DynamicConnections
			for _, conn in dc do
				if conn.Connected then
					conn:Disconnect()
				end
			end
			tclear(dc)

			if options.Opened then
				if #options.Values == 0 then
					viewLNC.Visible = true
					inst.Size = U2n(1, 0, 0, y)
					viewList.Size = U2n(1, 0, 0, y2)

					for _, child in viewLL:GetChildren() do
						if child:IsA("GuiObject") then
							child:Destroy()
						end
					end
				else
					viewLL.Visible = true
					inst.Size = U2n(1, 0, 0, (y - y3) + (#options.Values * 14))
					viewList.Size = U2n(1, 0, 0, #options.Values * 14)

					for i, val in options.Values do
						local row = viewLL:FindFirstChild(tostring(i))
						if not row then
							row = getPlaceholder("DropdownRow")
							row.Name = tostring(i)
						end

						safeReparent(row, viewLL)
						row.Text = tostring(val)
						row.Size = U2s(1, 1 / #options.Values)
						row.TextColor3 = ((options.Multi and tfind(options.Value, i)) or (not options.Multi and options.Value == i)) and themeM or themeT
						row.TextStrokeColor3 = themeS

						dc[#dc + 1] = row.MouseButton1Click:Connect(function()
							if options.Multi then
								local found = tfind(options.Value, i)
								if found then
									tremove(options.Value, found)
								else
									tinsert(options.Value, i)
								end

								tsort(options.Value)
							else
								local old = options.Value
								if options.AllowUnselect and options.Value == i then
									options.Value = false
								else
									options.Value = i
								end

								options.Opened = not options.AutoHide and old ~= options.Value or options.AutoHide
							end

							local value = options.Value
							local converted = self:Convert(value)

							if options.Convert then
								value, converted = converted, value
							end

							spawn(playSound, "Click", self)
							self:Refresh()
							self:Call(value, converted)
						end)

						dc[#dc + 1] = row.MouseButton1Down:Connect(function()
							castCircle(row, getWindow(self))
						end)

						dc[#dc + 1] = row.MouseEnter:Connect(function()
							spawn(playSound, "Hover", self)
						end)
					end

					for _, child in viewLL:GetChildren() do
						if child:IsA("GuiObject") and tonumber(child.Name) and tonumber(child.Name) > #options.Values then
							child:Destroy()
						end
					end
				end
			else
				viewLS.Visible = true
				inst.Size = U2n(1, 0, 0, y)
				viewList.Size = U2n(1, 0, 0, y2)

				for _, child in viewLL:GetChildren() do
					if child:IsA("GuiObject") then
						child:Destroy()
					end
				end
			end
		end
	},

	Slider = {
		DefaultOptions = {
			Text = "Slider",
			NoConfigs = false,
			Callback = function(value) end,
			Format = "/",
			Visible = true,
			Disabled = false,
			Styled = false,
			Compact = false,
			AllowSetValue = false,
			BypassSetValue = false,
			ShowCompactValue = true,
			_SettingValue = false,
			Minimum = nil,
			Maximum = nil,
			Min = 0,
			Max = 100,
			Step = 1,
			Value = 50,
			_Value = -1,
			Tooltip = "",
			DisabledTooltip = "",
			Order = false,
			Translations = tfreeze({ })
		},
		FixNum = function(self, ...)
			return fixNum(...)
		end,
		Set = function(self, value)
			local old = self.Options.Value
			self.Options.Value = value
			self.Options._Value = (value - self.Options.Min) / (self.Options.Max - self.Options.Min)

			self:Refresh()

			if old ~= self.Options.Value then
				self.Changed:Fire(self.Options.Value, self)
				spawn(self.Options.Callback, self.Options.Value, self)
			end
		end,
		BeginSetValue = function(self)
			self = self.Proxy or self
			self.Options._SettingValue = true
			self.Instance.View.Bar.InputProgress.Visible = true
			self.Instance.View.Bar.InputProgress.Text = self.Value
			self.Instance.View.Bar.Progress.Visible = false
			self.Instance.View.Bar.InputProgress:CaptureFocus()
			self:Refresh()
		end,
		Init = function(self, options)
			local instance = getPlaceholder("Slider")
			local object = addFunctions({
				Options = options,
				Instance = instance,
				Class = "Slider",
				Changed = event.new()
			}, self)

			defer(hoverLogic, object, instance)

			local sliding = false
			local bar = instance.View.Bar

			local cons = { }
			defer(addCons, object, cons)

			local mouseDown = false
			local clicks = 0

			cons[#cons + 1] = instance.MouseButton1Down:Connect(function()
				mouseDown = true
				clicks += 1

				if clicks == 2 and options.AllowSetValue then
					object:BeginSetValue()
				end

				wait(0.75)
				clicks -= 1
			end)

			cons[#cons + 1] = instance.MouseButton2Down:Connect(function()
				if options.AllowSetValue then
					object:BeginSetValue()
				end
			end)

			cons[#cons + 1] = instance.MouseButton1Up:Connect(function()
				mouseDown = false
			end)

			cons[#cons + 1] = instance.View.Bar.InputProgress.FocusLost:Connect(function()
				options._SettingValue = false
				instance.View.Bar.InputProgress.Visible = false
				instance.View.Bar.Progress.Visible = true

				local number
				for i, v in instance.View.Bar.InputProgress.Text:gsub("[\n\r\f\s\t\0]", " "):split(" ") do
					number = tonumber(v)
					if number then break end
				end

				if number then
					if options.BypassSetValue then
						object:Set(number)
					else
						spawn(object.Call, object, (number - object.Options.Min) / (object.Options.Max - object.Options.Min), true)
					end
				end

				object.Proxy:Refresh()
			end)

			local con; con = instance.InputBegan:Connect(function(input)
				local touch = input.UserInputType == Enum.UserInputType.Touch
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and not touch or clicks > 1 or not mouseDown then return end

				if object.Options.Disabled then sliding = false return end
				sliding = true

				local c; c = mouse.Button1Up:Connect(function()
					sliding = false
					c:Disconnect()
				end)

				local startX = mouse.X
				local startY = mouse.Y

				while device == "Mobile" do
					mouse.Move:Wait()
					local d = render()

					if abs(mouse.Y - startY) > 25 then
						sliding = false
						c:Disconnect()
						return
					end

					if abs(mouse.X - startX) > 25 then
						break
					end
				end

				while sliding and not object.Options.Disabled and con.Connected do
					spawn(object.Call, object, clamp((mouse.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1), true)
					render()
				end

				if c.Connected then
					c:Disconnect()
				end

				sliding = false
			end)

			cons[#cons + 1] = con
			cons[#cons + 1] = instance.InputEnded:Connect(function(input) 
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end)

			object.Options._Value = clamp(object.Options.Value / (object.Options.Max - object.Options.Min), 0, 1)
			return object
		end,
		Call = function(self, value, valueCompare)	
			value = clamp(tonumber(value) or 0.5, 0, 1)

			if value ~= value then
				value = 0
			end

			local realValue = value * (self.Options.Max - self.Options.Min) + self.Options.Min
			realValue = round(realValue * 1e8) / 1e8

			if self.Options.Step > 0 then
				realValue = floor((realValue + self.Options.Step / 2) / self.Options.Step) * self.Options.Step
			end

			realValue = clamp(realValue, self.Options.Min, self.Options.Max)
			if valueCompare and realValue == self.Options.Value then return self:Refresh() end

			self.Options._Value = value
			self.Options.Value = realValue

			self:Refresh()
			spawn(playSound, "Hover", self)
			self.Changed:Fire(realValue, self.Proxy)
			self.Options.Callback(realValue, self.Proxy)
		end,
		Refresh = function(self)
			local texttt = translate(self, "Text")
			local forceCompact = clean(texttt) == ""
			local options = self.Options
			local compact = options.Compact or forceCompact
			local parnt = self.Parent
			local ispgb = parnt.Class == "Groupbox"

			local y = ispgb and (compact and 30 or 40) or (compact and 30 or 50)
			local y2 = ispgb and 14 or 16
			local x = ispgb and -14 or -30

			if options.Minimum ~= nil then
				options.Min, options.Minimum = options.Minimum, nil
			end
			if options.Maximum ~= nil then
				options.Max, options.Maximum = options.Maximum, nil
			end

			local window = getWindow(self)
			local woptions = window.Options

			local inst = self.Instance
			local view = inst.View
			local theme = window.Theme
			local themeT = theme.Text
			local themeS = theme.Stroke

			local viewBar = view.Bar
			local viewLabel = view.Label

			local viewBarProgress = viewBar.Progress
			local viewBarFill = viewBar.Fill

			inst.Separator.BackgroundColor3 = themeT
			viewLabel.TextColor3 = themeT
			viewBar.BackgroundColor3 = themeS
			viewBarFill.BackgroundColor3 = theme.Main
			viewBarProgress.TextColor3 = themeT
			viewBarProgress.TextStrokeColor3 = themeS
			viewBar.Position = U2s(0.5, compact and 0.5 or 1.65)
			viewBar.UIStroke.Color = themeS
			orderUpdate(inst, options.Order)

			inst.Visible = options.Visible
			safeReparent(inst, ispgb and parnt.Holder.Holder.Contents or parnt.Holder.NormalZone)

			options.Maximum = options.Max
			options.Minimum = options.Min

			if typeof(options.Format) ~= "function" then
				options.Format = functions[options.Format or ""] or functions["/"]
			end

			local formattedText = options.Format and (typeof(options.Format) == "string" and options["Format"] --[[suspend studio warning]] or tostring(options.Format(options))) or fixNum(self.Value) .. " / " .. fixNum(self.Max)

			viewLabel.Visible = not compact
			viewBarProgress.TextXAlignment = compact and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
			viewBarProgress.Visible = not options._SettingValue
			viewBar.InputProgress.Visible = options._SettingValue
			viewBar.InputProgress.TextXAlignment = viewBarProgress.TextXAlignment

			if not compact then
				viewBarProgress.Text = formattedText
				viewLabel.Text = texttt
			else
				viewBarProgress.Text = forceCompact and (options.ShowCompactValue and formattedText or "") or texttt .. (options.ShowCompactValue and " (" .. formattedText .. ")" or "")
			end

			viewLabel.TextTransparency = options.Disabled and 0.35 or 0
			viewBarFill.BackgroundTransparency = options.Disabled and 0.35 or 0

			local style = options.Styled
			local styled = not not style
			viewBarProgress.TextTransparency = options.Disabled and not styled and 0.35 or 0

			local styleObject = viewBar:FindFirstChild("Style")
			styleObject.Visible = styled
			styleObject.Shadow.Visible = style == true or style == "Shadow"
			styleObject.Shine.Visible = style == true or style == "Shine"

			inst.Size = U2n(1, 0, 0, y)
			view.Size = U2n(1, x, 0, y2)
			view.Position = ispgb and U2n(0, 7, compact and 0.5 or 0.275, 0) or U2n(0, 15, compact and 0.5 or 0.3, 0)
			viewBar.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
			viewBarFill.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
			viewBar.UIStroke.Enabled = not woptions.NoStrokes

			local x = options.Value == -inf and 0 or options.Value == inf and 1 or clamp((options.Value - options.Min) / (options.Max - options.Min), 0, 1)
			if x ~= x then
				x = 0
			end

			tweenOnce(viewBarFill, TIn(max(0.25 / handleAnimationSpeed(getWindow(self).AnimationSpeed), 0.05), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = U2s(x, 0) })
		end
	},
	TextBox = {
		DefaultOptions = {
			Text = "Text Box",
			NoConfigs = false,
			Callback = function(text) end,
			Visible = true,
			MultiLine = false,
			RequiresEnter = false, -- WARNING: if MultiLine is enabled, this will be ignored
			Instant = false, -- when true, it will always call the Callback when text changes
			ValueUsesPlaceholder = false, -- when true, if text == "", it will use placeholder text instead
			Tooltip = "",
			DisabledTooltip = "",
			PlaceholderText = "Type here...", -- supports Rich Text
			Value = "",
			Disabled = false,
			Order = false,
			Translations = tfreeze({ })
		},
		Set = function(self, value)
			local old = self.Options.Value
			self.Options.Value = value
			self:Refresh()

			if old ~= self.Options.Value then
				self.Changed:Fire(self.Options.Value, self)
				spawn(self.Options.Callback, self.Options.Value, self)
			end
		end,
		Init = function(self, options)
			local instance = getPlaceholder("TextBox")
			local object = addFunctions({
				Options = options,
				Instance = instance,
				Class = "TextBox",
				Changed = event.new()
			}, self)

			defer(hoverLogic, object, instance)

			local cons = { }
			defer(addCons, object, cons)

			cons[#cons + 1] = instance.MouseButton1Click:Connect(function()
				object:Click()
			end)

			cons[#cons + 1] = instance.MouseButton1Down:Connect(function()
				if object.Proxy.Disabled then return end
				castCircle(instance, getWindow(object))
			end)

			cons[#cons + 1] = instance.MouseEnter:Connect(function()
				if object.Proxy.Disabled then return end
				spawn(playSound, "Hover", object)
			end)

			cons[#cons + 1] = instance.View.Bar.FocusLost:Connect(function(enter)
				if (object.Options.MultiLine or object.Options.RequiresEnter and enter or not object.Options.RequiresEnter) and not object.Options.Instant then
					object:Call(instance.View.Bar.Text)
				end

				object:Refresh(true)
				render()
				object:Refresh(true)
			end)

			local cd = true
			cons[#cons + 1] = instance.View.BarInvisible.Changed:Connect(function()
				if not cd or not getWindow(object).Visible then return end
				cd = false
				object:Refresh(true)
				render()
				object:Refresh(true)
				cd = true
				render()
				object:Refresh(true)
			end)

			local oldN = 1
			cons[#cons + 1] = instance.View.Bar:GetPropertyChangedSignal("Text"):Connect(function()
				local new = instance.View.Bar.Text

				local newN = quickCount(new, "\n")
				local diff = newN - oldN

				oldN = newN

				if object.Proxy.Parent.Class ~= "Groupbox" then
					object.Proxy.Parent.Holder.CanvasPosition += V2n(0, diff * 12)
				end

				instance.View.BarInvisible.RichText = #new == 0
				instance.View.BarInvisible.Text = (#new == 0 and object.Options.PlaceholderText or new):sub(0, 199999)
				object:Refresh(true)

				if not object.Options.Instant then return end
				object:Call(new)
			end)

			return object
		end,
		Call = function(self, text)
			text = tostring(text)
			self.Options.Value = text

			if text == "" and self.Options.ValueUsesPlaceholder then
				text = tostring(self.Options.PlaceholderText)
			end

			self.Proxy:Refresh(true)
			self.Changed:Fire(text, self.Proxy)
			self.Options.Callback(text, self.Proxy)
		end,
		Click = function(self)
			spawn(playSound, "Click", self)
			self.Proxy:Refresh()
			self.Instance.View.Bar:CaptureFocus()
		end,
		Refresh = function(self, dontSetText)
			local parnt = self.Parent
			local ispgb = parnt.Class == "Groupbox"
			local y = ispgb and 40 or 50
			local y2 = ispgb and 14 or 16
			local x = ispgb and -14 or -30

			local options = self.Options

			local window = getWindow(self)
			local inst = self.Instance
			local view = inst.View
			local woptions = window.Options

			local theme = window.Theme
			local themeT = theme.Text
			local themeS = theme.Stroke
			
			local viewLabel = view.Label
			local viewBar = view.Bar
			local vbph = viewBar.Placeholder
			local vuis = viewBar.UIStroke
			
			inst.Separator.BackgroundColor3 = themeT
			viewLabel.TextColor3 = themeT
			viewBar.BackgroundColor3 = themeS
			viewBar.PlaceholderColor3 = themeT
			viewBar.TextColor3 = themeT
			vbph.TextColor3 = themeT
			vuis.Color = themeS
			orderUpdate(inst, options.Order)

			inst.Visible = options.Visible
			safeReparent(inst, ispgb and parnt.Holder.Holder.Contents or parnt.Holder.NormalZone)
			viewBar.PlaceholderText = ""
			viewLabel.Text = translate(self, "Text")
			viewBar.MultiLine = options.MultiLine
			viewBar.TextEditable = not options.Disabled
			viewBar.TextTransparency = options.Disabled and (viewBar.Text == "" and 0.85 or 0.65) or viewBar.Text == "" and 0.45 or 0
			viewLabel.TextTransparency = options.Disabled and 0.35 or 0
			vbph.Text = translate(self, "PlaceholderText"):sub(1, 199999)
			vbph.Visible = viewBar.Text == ""
			vbph.RichText = true
			viewBar.RichText = false
			vbph.TextTransparency = viewBar.TextTransparency
			viewBar.Size = U2n(1, 0, 0, view.BarInvisible.TextBounds.Y + 2)
			inst.Size = U2n(1, 0, 0, (y - 14) + viewBar.Size.Y.Offset)
			view.Size = U2n(1, x, 0, y2)
			view.Position = ispgb and U2n(0, 7, 0, 1) or U2n(0, 15, 0, 8)
			view.AnchorPoint = V2n(0, 0)
			viewBar.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
			vuis.Enabled = not woptions.NoStrokes

			if not dontSetText then
				viewBar.Text = options.Value
			end
		end
	},
	Label = {
		DefaultOptions = {
			Text = "Label",
			Visible = true,
			Order = false,
			Translations = tfreeze({ })
		},
		AddColorPicker = acp,
		ColorPicker = acp,
		NewColorPicker = acp,
		GetObjectFromHash = getObjectFromHash,
		Init = function(self, options)
			local instance = getPlaceholder("Label")
			local object = addFunctions({
				Options = options,
				ColorPickers = { },
				Instance = instance,
				Class = "Label"
			}, self)

			local cons = { }
			defer(addCons, object, cons)

			local cd = true
			cons[#cons + 1] = instance.Label.Changed:Connect(function()
				if not cd or not getWindow(object).Visible then return end

				cd = false
				instance.Label.Size = U2n(1, -30, 0, getTextSize(instance.Label.Text, instance.Label.TextSize, instance.Label.Font, V2n(instance.Label.AbsoluteSize.X, 99999)).Y)
				instance.Size = U2n(1, 0, 0, instance.Label.TextBounds.Y + (24 - (object.Proxy.Parent.Class == "Groupbox" and 9 or 0)))
				render()
				instance.Label.Size = U2n(1, -30, 0, getTextSize(instance.Label.Text, instance.Label.TextSize, instance.Label.Font, V2n(instance.Label.AbsoluteSize.X, 99999)).Y)
				instance.Size = U2n(1, 0, 0, instance.Label.TextBounds.Y + (24 - (object.Proxy.Parent.Class == "Groupbox" and 9 or 0)))
				cd = true
				render()
				instance.Label.Size = U2n(1, -30, 0, getTextSize(instance.Label.Text, instance.Label.TextSize, instance.Label.Font, V2n(instance.Label.AbsoluteSize.X, 99999)).Y)
				instance.Size = U2n(1, 0, 0, instance.Label.TextBounds.Y + (24 - (object.Proxy.Parent.Class == "Groupbox" and 9 or 0)))
			end)

			return object
		end,
		Refresh = function(self)
			local parnt = self.Parent
			local ispgb = parnt.Class == "Groupbox"
			local y = ispgb and 14 or 16

			local window = getWindow(self)
			local inst = self.Instance

			local themeT = window.Theme.Text
			
			inst.Separator.BackgroundColor3 = themeT
			inst.Label.TextColor3 = themeT
			inst.Label.TextSize = y

			orderUpdate(inst, self.Options.Order)
			inst.Visible = self.Options.Visible
			safeReparent(inst, ispgb and parnt.Holder.Holder.Contents or parnt.Holder.NormalZone)
			inst.Label.Text = translate(self, "Text"):sub(0, 199999)
			inst.Label.Position = ispgb and U2o(9, 5) or U2o(15, 12)
		end
	},
	Header = {
		DefaultOptions = {
			Text = "Header",
			Visible = true,
			Order = false,
			Translations = tfreeze({ }),
			ShowStart = true,
		},
		Init = function(self, options)
			local instance = getPlaceholder("Header")
			local object = addFunctions({
				Options = options,
				Instance = instance,
				Class = "Header"
			}, self)

			local cons = { }
			defer(addCons, object, cons)

			local cd = true
			cons[#cons + 1] = instance.View.Label.Changed:Connect(function()
				if not cd or not getWindow(object).Visible then return end

				cd = false
				instance.View.Label.Size = U2n(0, getTextSize(instance.View.Label.Text, instance.View.Label.TextSize, instance.View.Label.Font, V2n(99999, 99999)).X, 1, 0)
				render()
				instance.View.Label.Size = U2n(0, getTextSize(instance.View.Label.Text, instance.View.Label.TextSize, instance.View.Label.Font, V2n(99999, 99999)).X, 1, 0)
				cd = true
				render()
				instance.View.Label.Size = U2n(0, getTextSize(instance.View.Label.Text, instance.View.Label.TextSize, instance.View.Label.Font, V2n(99999, 99999)).X, 1, 0)
			end)

			return object
		end,
		Refresh = function(self)
			local window = getWindow(self)
			local inst = self.Instance
			local options = self.Options
			local parnt = self.Parent
			local ispgb = parnt.Class == "Groupbox"

			inst.Separator.BackgroundColor3 = window.Theme.Text
			inst.View.Left.BackgroundColor3 = window.Theme.Text
			inst.View.Right.BackgroundColor3 = window.Theme.Text
			inst.View.Label.TextColor3 = window.Theme.Text
			inst.View.Left.Visible = options.ShowStart

			orderUpdate(inst, options.Order)
			inst.Visible = options.Visible
			safeReparent(inst, ispgb and parnt.Holder.Holder.Contents or parnt.Holder.NormalZone)
			inst.View.Label.Text = translate(self, "Text"):sub(0, 199999)
			inst.View.Label.Position = ispgb and U2o(9, 5) or U2o(15, 12)
		end
	},
	Separator = {
		DefaultOptions = {
			Visible = true,
			Invisible = false,
			Order = false,
		},
		Init = function(self, options)
			local instance = getPlaceholder("Separator")
			return addFunctions({
				Options = options,
				Instance = instance,
				Class = "Separator"
			}, self)
		end,
		Refresh = function(self)
			local inst = self.Instance
			local options = self.Options
			local parnt = self.Parent
			
			local themeT = getWindow(self).Theme.Text
			
			inst.Separator.BackgroundColor3 = themeT
			inst.SeparatorMiddle.BackgroundColor3 = themeT

			inst.Visible = options.Visible
			orderUpdate(inst, options.Order)
			safeReparent(inst, parnt.Class == "Groupbox" and parnt.Holder.Holder.Contents or parnt.Holder.NormalZone)
			inst.SeparatorMiddle.Visible = not options.Invisible
			inst.Size = U2n(1, 0, 0, 10)
		end
	},
	Toggle = {
		DefaultOptions = {
			Text = "Toggle",
			NoConfigs = false,
			Callback = function(bool) end,
			Visible = true,
			Value = false,
			Disabled = false,
			CheckBox = false,
			Tooltip = "",
			DisabledTooltip = "",
			Order = false,
			Translations = tfreeze({ })
		},
		Set = function(self, value)
			local old = self.Options.Value
			self.Options.Value = value
			self:Refresh()

			if old ~= self.Options.Value then
				self.Changed:Fire(self.Options.Value, self)
				spawn(self.Options.Callback, self.Options.Value, self)
			end
		end,
		AddColorPicker = acp,
		ColorPicker = acp,
		NewColorPicker = acp,
		GetObjectFromHash = getObjectFromHash,
		Init = function(self, options)
			local instance = getPlaceholder("Toggle")
			local object = addFunctions({
				Options = options,
				ColorPickers = { },
				Instance = instance,
				Class = "Toggle",
				Changed = event.new()
			}, self)

			defer(hoverLogic, object, instance)
			defer(keybindSetup, object)

			local cons = { }
			defer(addCons, object, cons)

			cons[#cons + 1] = instance.MouseButton1Click:Connect(function()
				object:Click()
			end)

			cons[#cons + 1] = instance.MouseButton1Down:Connect(function()
				if object.Proxy.Disabled then return end
				castCircle(instance, getWindow(object))
			end)

			return object
		end,
		Call = function(self, value)
			self.Changed:Fire(value, self.Proxy)
			self.Options.Callback(value, self.Proxy)
		end,
		Toggle = function(self, value, noCallback)
			if value == nil then
				value = not self.Options.Value
			end

			self.Options.Value = not not value
			self.Proxy:Refresh()

			if not noCallback then
				self:Call(self.Options.Value)
			end
		end,
		Click = function(self)
			if self.Options.Disabled then return end
			spawn(playSound, "Click", self)
			self:Toggle()
		end,
		Refresh = function(self)
			local parnt = self.Parent
			local ispgb = parnt.Class == "Groupbox"

			local y = ispgb and 25 or 40
			local y2 = ispgb and 14 or 16
			local x = ispgb and 7 or 15

			local inst = self.Instance
			local view = inst.View
			local options = self.Options

			inst.Visible = options.Visible
			orderUpdate(inst, options.Order)
			safeReparent(inst, ispgb and parnt.Holder.Holder.Contents or parnt.Holder.NormalZone)

			local label = view.Label
			local vicon = view.Icon
			local iconFrame = vicon.Frame
			local frState = iconFrame.State
			local uic = iconFrame.UICorner
			local uis = iconFrame.UIStroke

			label.Text = translate(self, "Text")
			label.TextTransparency = options.Disabled and 0.35 or 0
			vicon[options.CheckBox and "BackgroundTransparency" or "ImageTransparency"] = 1
			inst.Size = U2n(1, 0, 0, y)
			view.Size = U2n(100, 0, 0, y2)
			view.Position = U2n(0, x, 0.5, 0)
			vicon.Size = ispgb and U2s(1, 1) or U2s(1.2, 1.2)

			local window = getWindow(self)
			local woptions = window.Options
			
			local theme = window.Theme
			local themeS = theme.Stroke
			local themeT = theme.Text
			local themeM = theme.Main
			
			inst.Separator.BackgroundColor3 = themeT
			label.TextColor3 = themeT
			vicon.ImageColor3 = themeM
			vicon.BackgroundColor3 = themeM
			vicon.UIStroke.Color = themeS
			frState.BackgroundColor3 = themeT:Lerp(themeM, 0.67 --[[omg another 67]]):Lerp(themeS, options.Disabled and 0.5 or 0)
			vicon.UICorner.CornerRadius = cornerState[woptions.RoundEverything]

			local strokes = not woptions.NoStrokes
			local isModern = not strokes or woptions.ModernToggles and not options.CheckBox
			vicon.UIStroke.Enabled = not isModern and strokes
			iconFrame.Visible = isModern
			vicon.UIAspectRatioConstraint.AspectRatio = not isModern and 0.975 or (ispgb or woptions.LargeModernToggles) and 1.7 or 1.3
			uic.CornerRadius = Un(woptions.RoundEverything and 1 or 0, 0)
			frState.UICorner.CornerRadius = uic.CornerRadius
			uis.Enabled = strokes
			uis.Color = themeS
			
			local as = 0.3 / handleAnimationSpeed(window.AnimationSpeed)
			tweenOnce(iconFrame, TIn(as), { BackgroundColor3 = (options.Value and themeM or themeS):Lerp(themeS, options.Disabled and 0.5 or 0) })
			tweenOnce(frState, TIn(as), { Position = U2s(options.Value and 1 or 0), AnchorPoint = V2n(options.Value and 1 or 0, 0) })

			if not isModern then
				tweenOnce(vicon, TIn(as), { [options.CheckBox and "BackgroundTransparency" or "ImageTransparency"] = 1, [options.CheckBox and "ImageTransparency" or "BackgroundTransparency"] = not options.Disabled and (options.Value and 0 or 1) or options.Value and 0.75 or 1 })
			else
				tweenOnce(vicon, TIn(0.01), { ImageTransparency = 1, BackgroundTransparency = 1 })
			end
		end
	},
	Input = {
		DefaultOptions = {
			Text = "Input",
			NoConfigs = false,
			KeySet = function(value : Enum.KeyCode) end,
			Callback = function() end,
			Visible = true,
			Value = false,
			Disabled = false,
			Order = false,

			Tooltip = "",
			DisabledTooltip = "",

			Translations = tfreeze({ })
		},
		Set = function(self, value)
			local old = self.Options.Value
			self.Options.Value = value
			self:Refresh()

			if old ~= self.Options.Value then
				self.Changed:Fire(self.Options.Value ~= false and Enum.KeyCode:FromValue(self.Options.Value) or nil, self.Proxy)
				spawn(self.Options.KeySet, self.Options.Value ~= false and Enum.KeyCode:FromValue(self.Options.Value) or nil, self.Proxy)
			end
		end,
		AddColorPicker = acp,
		ColorPicker = acp,
		NewColorPicker = acp,
		GetObjectFromHash = getObjectFromHash,
		Init = function(self, options)
			local instance = getPlaceholder("Input")
			local object = addFunctions({
				Options = options,
				ColorPickers = { },
				Instance = instance,
				Class = "Input",
				Changed = event.new()
			}, self)

			defer(hoverLogic, object, instance)

			local cons = { }
			defer(addCons, object, cons)

			cons[#cons + 1] = instance.MouseButton1Click:Connect(function()
				object.Proxy:Click()
			end)

			cons[#cons + 1] = instance.MouseButton1Down:Connect(function()
				if object.Proxy.Disabled then return end
				castCircle(instance, getWindow(object))
			end)

			defer(object.Setup, object)

			return object
		end,
		Setup = function(self)
			self = self.Proxy

			local window = getWindow(self)
			window._Connections[#window._Connections + 1] = uis.InputBegan:Connect(function(input, chat)
				if chat or input.KeyCode.Value ~= self.Options.Value then return end
				self:Callback()
			end)
		end,
		KeyClick = function(self)
			if self.Options.Disabled then return end
			spawn(self.Options.Callback, self)
		end,
		Call = function(self, value)
			self.Options.Value = value
			self.Proxy:Refresh()

			self.Changed:Fire(self.Options.Value ~= false and Enum.KeyCode:FromValue(self.Options.Value) or nil, self.Proxy)
			self.Options.KeySet(self.Options.Value ~= false and Enum.KeyCode:FromValue(self.Options.Value) or nil, self.Proxy)
		end,
		Click = function(self)
			if self.Options.Disabled then return end

			spawn(playSound, "Click", self)
			local i = inputting
			inputting = self

			if i then
				if i == inputting then
					inputting = false
					self:Call(false)
				else
					i:Refresh()
				end
			end

			self:Refresh()
		end,
		Refresh = function(self)
			local parnt = self.Parent
			local ispgb = parnt.Class == "Groupbox"
			local options = self.Options

			local y = ispgb and 25 or 40
			local y2 = ispgb and 14 or 16
			local x = ispgb and 7 or 15

			local window = getWindow(self)
			local woptions = window.Options
			
			local inst = self.Instance
			local view = inst.View
			local viewLabel = view.Label
			local viewDisplay = view.Display
			local vuis = viewDisplay.UIStroke

			orderUpdate(inst, options.Order)
			inst.Visible = options.Visible and window.IsDesktop
			safeReparent(inst, ispgb and parnt.Holder.Holder.Contents or parnt.Holder.NormalZone)
			viewLabel.Text = translate(self, "Text")
			viewLabel.TextTransparency = options.Disabled and 0.35 or 0
			viewDisplay.TextTransparency = options.Disabled and 0.35 or 0
			inst.Size = U2n(1, 0, 0, y)
			view.Size = U2n(100, 0, 0, y2)
			view.Position = U2n(0, x, 0.5, 0)
			
			local theme = window.Theme
			local themeT = theme.Text
			local themeS = theme.Stroke

			inst.Separator.BackgroundColor3 = themeT
			viewLabel.TextColor3 = themeT
			viewDisplay.TextColor3 = theme.Main
			vuis.Color = themeS
			viewDisplay.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
			vuis.Enabled = not woptions.NoStrokes
			viewDisplay.BackgroundColor3 = themeS

			local v = options.Value
			if typeof(v) == "EnumItem" then
				v = v.Value
			elseif tonumber(v) then
				v = tonumber(v)
			elseif Enum.KeyCode:FromName(tostring(v)) then
				v = Enum.KeyCode:FromName(tostring(v)).Value
			else
				v = false
			end

			options.Value = v
			if inputting == self then
				viewDisplay.Text = "..."
			else
				viewDisplay.Text = (not options.Value or not Enum.KeyCode:FromValue(options.Value)) and "None" or gsubInput(Enum.KeyCode:FromValue(options.Value).Name)
			end
		end
	}
}

local groupBoxFuncs = {
	DefaultOptions = {
		Text = "",
		Side = "Left",
		Visible = true,
		Order = 0,
		Translations = tfreeze({ })
	},
	GetObjectFromHash = getObjectFromHash,
	Init = function(self, options)
		local groupbox = getPlaceholder("Groupbox")

		local object = addFunctions({
			Options = options,
			Holder = groupbox,
			Objects = { },
			Class = "Groupbox",
			ChildAdded = event.new()
		}, self)

		options._Objects = 0
		addPossibleTranslations(object)

		local cons = { }
		defer(addCons, object, cons)

		cons[#cons + 1] = object.ChildAdded:Connect(function(newObject)
			options._Objects += 1

			if newObject and newObject.Options then
				if newObject.Options.Order == false then
					newObject.Order = -max32 + options._Objects
				end

				if typeof(object.Options.Translations) == "table" and object.Options.Translations[newObject.Flag] then
					newObject.Options.Translations = object.Options.Translations[newObject.Flag]
					addPossibleTranslations(newObject)

					newObject:Refresh()
				end
			else
				warn("Invalid object", newObject)
			end
		end)

		local function r()
			object.Proxy:Refresh()
		end

		cons[#cons + 1] = object.Holder.Holder.Contents.ChildAdded:Connect(function(ch)
			cons[#cons + 1] = ch:GetPropertyChangedSignal("Visible"):Connect(r)
			cons[#cons + 1] = ch:GetPropertyChangedSignal("Size"):Connect(r)
			r()
		end)

		cons[#cons + 1] = object.Holder.Holder.Contents.ChildRemoved:Connect(r)

		return object
	end,
	Refresh = function(self)
		local window = getWindow(self)
		local holder = self.Holder.Holder
		local options = self.Options
		local woptions = window.Options
		local theme = window.Theme
		local themeT = theme.Text
		local themeS = theme.Stroke
		
		local hp = holder.Parent
		local hc = holder.Contents
		local huis = holder.UIStroke
		local ht = holder.Title

		holder.BackgroundColor3 = themeT
		huis.Color = themeS
		hc.BackgroundColor3 = themeS
		holder.Frame.BackgroundColor3 = window.Theme.Main
		ht.TextColor3 = themeT
		holder.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
		hc.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
		huis.Enabled = not woptions.NoStrokes

		local texttt = translate(self, "Text")
		local textVisible = clean(texttt) ~= ""

		ht.Text = texttt
		safeReparent(hp, self.Parent.Holder.GroupboxZone[options.Side .. "GroupboxZone"])
		orderUpdate(hp, options.Order)

		local ySize = 0
		for i, v in hc:GetChildren() do
			if v:IsA("GuiObject") and v.Visible then
				ySize += v.AbsoluteSize.Y
			end
		end

		hc.Position = U2n(0.5, 0, 0, textVisible and 20 or 7)
		hc.Size = U2n(1, -10, 1, textVisible and -25 or -10)
		hp.Size = U2n(1, 0, 0, ySize ~= 0 and (textVisible and 35 or 20) + ySize or 0)
		hp.Visible = options.Visible and ySize ~= 0
	end
}

local function initTabButton(tabButton, object, cons, options)
	defer(hoverLogic, object, tabButton)

	cons[#cons + 1] = tabButton.MouseButton1Down:Connect(function()
		castCircle(tabButton, getWindow(object))
	end)

	cons[#cons + 1] = tabButton.MouseEnter:Connect(function()
		spawn(playSound, "Hover", object)
		tweenOnce(tabButton.ButtonItself.Icon, TIn(0.4 / handleAnimationSpeed(getWindow(object).AnimationSpeed)), { ImageTransparency = 0 })
		tweenOnce(tabButton.ButtonItself.Title, TIn(0.4 / handleAnimationSpeed(getWindow(object).AnimationSpeed)), { TextTransparency = 0 })
	end)

	cons[#cons + 1] = tabButton.MouseLeave:Connect(function()
		if object.Parent.CurrentTab and object.Parent.CurrentTab.Holder ~= object.Holder or not object.Parent.CurrentTab then
			tweenOnce(tabButton.ButtonItself.Icon, TIn(0.6 / handleAnimationSpeed(getWindow(object).AnimationSpeed)), { ImageTransparency = 0.25 })
			tweenOnce(tabButton.ButtonItself.Title, TIn(0.6 / handleAnimationSpeed(getWindow(object).AnimationSpeed)), { TextTransparency = 0.25 })
		end
	end)

	cons[#cons + 1] = tabButton.MouseButton1Click:Connect(function()
		spawn(playSound, "Click", object)
		object:SwitchTo()
	end)

	cons[#cons + 1] = tabButton.ButtonItself.Icon.Changed:Connect(function()
		tabButton.ButtonItself.Icon.Visible = setIcon(options.Icon, icons, object.Proxy, tabButton.ButtonItself.Icon) ~= ""
	end)
end

local tabFuncs = {
	DefaultOptions = {
		Icon = "",
		Text = "Tab",
		Visible = true,
		Tooltip = "",
		DisabledTooltip = "",
		RecolorIcon = true,
		Translations = tfreeze({ }),
		Order = 0,
		Image = ""
	},
	GetObjectFromHash = getObjectFromHash,
	Init = function(self, options)
		local tabButton = getPlaceholder("TabButton")
		local tab = getPlaceholder("Tab")

		local object = addFunctions({
			Options = options,
			TabButton = tabButton,
			Holder = tab,
			Objects = { },
			Class = "Tab",
			ChildAdded = event.new()
		}, self)

		options._Objects = 0
		addPossibleTranslations(object)

		local cons = { }
		defer(addCons, object, cons)

		cons[#cons + 1] = object.ChildAdded:Connect(function(newObject)
			options._Objects += 1

			if newObject and newObject.Options then
				if newObject.Options.Order == false then
					newObject.Order = -max32 + options._Objects
				end

				if typeof(object.Options.Translations) == "table" and object.Options.Translations[newObject.Flag] then
					newObject.Options.Translations = object.Options.Translations[newObject.Flag]
					addPossibleTranslations(newObject)
					newObject:Refresh()
				end
			else
				warn("Invalid object", newObject)
			end
		end)

		initTabButton(tabButton, object, cons, options)

		cons[#cons + 1] = tab.NormalZone.ChildAdded:Connect(function(child)
			object.Proxy:Refresh()

			if child:IsA("GuiObject") then
				cons[#cons + 1] = child:GetPropertyChangedSignal("Visible"):Connect(function()
					object.Proxy:Refresh()
				end)
				cons[#cons + 1] = child:GetPropertyChangedSignal("Size"):Connect(function()
					object.Proxy:Refresh()
				end)
			end
		end)

		cons[#cons + 1] = tab.NormalZone.ChildRemoved:Connect(function()
			object.Proxy:Refresh()
		end)

		local gbc2 = function()
			object.Proxy:Refresh()
		end

		local gbc; gbc = function(child)
			object.Proxy:Refresh()

			if child:IsA("GuiObject") then
				cons[#cons + 1] = child:GetPropertyChangedSignal("Visible"):Connect(function()
					object.Proxy:Refresh()
				end)

				cons[#cons + 1] = child:GetPropertyChangedSignal("Size"):Connect(function()
					object.Proxy:Refresh()
				end)
			end
		end

		cons[#cons + 1] = tab.GroupboxZone.LeftGroupboxZone.ChildAdded:Connect(gbc)
		cons[#cons + 1] = tab.GroupboxZone.LeftGroupboxZone.ChildRemoved:Connect(gbc2)
		cons[#cons + 1] = tab.GroupboxZone.RightGroupboxZone.ChildAdded:Connect(gbc)
		cons[#cons + 1] = tab.GroupboxZone.RightGroupboxZone.ChildRemoved:Connect(gbc2)

		local cnt = 0
		cons[#cons + 1] = rs.RenderStepped:Connect(function()
			cnt = (cnt + 1) % 5

			if cnt == 0 then
				tab.MobileSizeFix.Size = U2n(mrandom(), 0, 0, 1)
			end
		end)

		defer(function()
			if not object.Parent.CurrentTab then
				object.Proxy:SwitchTo()
			end
		end)

		return object
	end,
	SwitchTo = function(self, dont)
		local window = getWindow(self)
		if not window then return self end

		for i, v in self.Parent.Objects do
			if v.Class == "Tab" or v.Class == "CustomTab" then
				local visible = v.Proxy == self.Proxy
				v.Holder.Visible = visible

				tweenOnce(v.TabButton.ButtonItself.Icon, TIn(0.75 / handleAnimationSpeed(window.AnimationSpeed)), { ImageTransparency = visible and 0 or 0.25 })
				tweenOnce(v.TabButton.ButtonItself.Title, TIn(0.75 / handleAnimationSpeed(window.AnimationSpeed)), { TextTransparency = visible and 0 or 0.25 })
				tweenOnce(v.TabButton, TIn(1.5 / handleAnimationSpeed(window.AnimationSpeed)), { BackgroundTransparency = visible and 0.95 or 1 })
				tweenOnce(v.TabButton.Indicator, TIn(0.5 / handleAnimationSpeed(window.AnimationSpeed)), { Position = U2n(0, visible and 0 or -2, 0.5, 0) })
			end
		end

		self.Parent.Self.CurrentTab = self.Proxy
		return self:Refresh(dont)
	end,
	Refresh = function(self, dont)
		local window = getWindow(self)
		if not window then return self end

		local options = self.Options
		local tb = self.TabButton
		local bi = tb.ButtonItself
		local holder = self.Holder
		local class = self.Class
		local parnt = self.Parent
		local prox = self.Proxy

		local ls = "LibrarySettings" .. window.Flag
		if options.Flag:sub(1, #ls) ~= ls then
			local pwrcd = parnt.Window.RealWindow.Contents.Display
			safeReparent(tb, pwrcd.PageButtons.List)
			safeReparent(holder, pwrcd.Pages)
		end

		setIcon(options.Icon, icons, prox, bi.Icon)
		bi.Title.Text = translate(self, "Text")
		bi.Visible = options.Visible
		
		local theme = window.Theme
		local themeM = theme.Main
		local themeT = theme.Text

		tb.BackgroundColor3 = themeM
		tb.Indicator.BackgroundColor3 = themeM
		tb.Filler.BackgroundColor3 = themeT
		setIcon(options.Image, backgrounds, prox, tb.ImageLabel)
		orderUpdate(tb, tonumber(options.Order) or 0)
		bi.Icon.ImageColor3 = options.RecolorIcon and themeT or C3n(1, 1, 1)
		bi.Title.TextColor3 = themeT

		if class == "Tab" then
			holder.ScrollBarImageColor3 = themeM

			local ySize = 0
			for i, v in holder.NormalZone:GetChildren() do
				if v:IsA("GuiObject") and v.Visible then
					ySize += v.AbsoluteSize.Y
				end
			end

			holder.NormalZone.Size = U2n(1, 0, 0, ySize)

			local leftYSize = 0
			local rightYSize = 0

			local gbz = holder.GroupboxZone
			for i, v in gbz.LeftGroupboxZone:GetChildren() do
				if v:IsA("GuiObject") and v.Visible then
					leftYSize += v.AbsoluteSize.Y
				end
			end

			for i, v in gbz.RightGroupboxZone:GetChildren() do
				if v:IsA("GuiObject") and v.Visible then
					rightYSize += v.AbsoluteSize.Y
				end
			end

			gbz.Size = U2n(1, 0, 0, max(leftYSize, rightYSize))
		end

		if not options.Visible and parnt.CurrentTab and parnt.CurrentTab.Proxy == prox then
			parnt.CurrentTab.Holder.Visible = false
			parnt.Self.CurrentTab = false
		elseif options.Visible and parnt.CurrentTab and prox == parnt.CurrentTab.Proxy and not dont then
			return self:SwitchTo(true)
		end

		return self
	end,
	AddGroupbox = function(...)
		local object = newObject(groupBoxFuncs, ...);
		(...).Objects[object.Flag] = object;
		(...).ChildAdded:Fire(object)

		return object
	end,
	Groupbox = function(self, ...)
		return self:AddGroupbox(...)
	end,
	NewGroupbox = function(self, ...)
		return self:AddGroupbox(...)
	end,
	AddLeftGroupbox = function(self, ...)
		local gb = self:AddGroupbox(...)
		gb.Side = "Left"

		return gb
	end,
	LeftGroupbox = function(self, ...)
		return self:AddLeftGroupbox(...)
	end,
	NewLeftGroupbox = function(self, ...)
		return self:AddLeftGroupbox(...)
	end,
	AddRightGroupbox = function(self, ...)
		local gb = self:AddGroupbox(...)
		gb.Side = "Right"

		return gb
	end,
	RightGroupbox = function(self, ...)
		return self:AddRightGroupbox(...)
	end,
	NewRightGroupbox = function(self, ...)
		return self:AddRightGroupbox(...)
	end
}

local customTabFuncs = {
	Init = function(self, options)
		local tabButton = getPlaceholder("TabButton")
		local tab = getPlaceholder("CustomTab")

		local object = addFunctions({
			Options = options,
			TabButton = tabButton,
			Holder = tab,
			Frame = tab,
			Class = "CustomTab",
			ConfigSet = event.new()
		}, self)

		addPossibleTranslations(object)

		local cons = { }
		defer(addCons, object, cons)
		initTabButton(tabButton, object, cons, options)

		defer(function()
			if not object.Parent.CurrentTab then
				object.Proxy:SwitchTo()
			end
		end)

		return object
	end,
	Set = function(self, value)
		local oldValue = self.Value
		if value ~= oldValue then
			self.Value = value
			self.ConfigSet:Fire(value)
		end
	end,
	SwitchTo = tabFuncs.SwitchTo,
	Refresh = tabFuncs.Refresh
}

customTabFuncs.DefaultOptions = tclone(tabFuncs.DefaultOptions)
customTabFuncs.DefaultOptions.Value = ""
customTabFuncs.DefaultOptions.NoConfigs = false

basicObjects.Keybind = basicObjects.Input
for i, v in basicObjects do
	tabFuncs["Add" .. i] = function(...)
		local object = newObject(v, ...);
		(...).Objects[object.Flag] = object;
		(...).ChildAdded:Fire(object)

		return object
	end

	tabFuncs[i] = function(...) return tabFuncs["Add" .. i](...) end
	tabFuncs["New" .. i] = function(...) return tabFuncs["Add" .. i](...) end

	groupBoxFuncs["Add" .. i] = tabFuncs[i]
	groupBoxFuncs["New" .. i] = tabFuncs[i]
	groupBoxFuncs[i] = tabFuncs[i]
end

local toggle = tabFuncs.AddToggle
tabFuncs.AddCheckBox = function(...)
	local toggle = toggle(...)
	toggle.CheckBox = true

	return toggle
end

tabFuncs.CheckBox = tabFuncs.AddCheckBox
tabFuncs.NewCheckBox = tabFuncs.AddCheckBox
groupBoxFuncs.AddCheckBox = tabFuncs.AddCheckBox
groupBoxFuncs.CheckBox = tabFuncs.AddCheckBox
groupBoxFuncs.NewCheckBox = tabFuncs.AddCheckBox

local function unlockMouse()
	uis.MouseBehavior = Enum.MouseBehavior.Default
end

local function makeDraggable(instance, object, cons)
	local dragStartPos, dragStartPosition, dragConnection, dragUpConnection
	local con = instance.MouseButton1Down:Connect(function()
		local window = getWindow(object)

		dragStartPos = V2n(mouse.X, mouse.Y)
		dragStartPosition = instance.Position

		if dragConnection then
			dragConnection:Disconnect()
			dragConnection = nil
		end

		if dragUpConnection then
			dragUpConnection:Disconnect()
			dragUpConnection = nil
		end

		dragConnection = mouse.Move:Connect(function()
			local delta = V2n(mouse.X, mouse.Y) - dragStartPos
			instance:TweenPosition(U2n(dragStartPosition.X.Scale, dragStartPosition.X.Offset + delta.X, dragStartPosition.Y.Scale, dragStartPosition.Y.Offset + delta.Y), nil, nil, 0.35 / handleAnimationSpeed(window.Options.AnimationSpeed), true)
		end)

		dragUpConnection = uis.InputEnded:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end

			dragConnection:Disconnect()
			dragUpConnection:Disconnect()

			dragConnection, dragUpConnection = nil, nil
		end)
	end)

	if cons then
		cons[#cons + 1] = con
	end
end

local defaultNotificationOptions = { __index = {
	Duration = 5,
	Title = "Notification",
	Text = "Hello, world!",
	HasButtons = false,
	Icon = "",
	Side = "-",
	UseOgScaling = "-",
	Callback = function(state) end
} }

local defaultColorPickerOptions = { __index = {
	Text = "Color picker",
	Value = C3n(1, 1, 1),
	Callback = function(color) end
} }

local floatingLabel = {
	DefaultOptions = {
		Text = "",
		Title = "",
		Position = U2n(0, 20, 0.5, 0),
		AnchorPoint = V2n(0, 0.5),
		Visible = true,
		Icon = "",

		_text = "",
		_icon = "",
		_title = "",
		_position = "",
	},

	Init = function(self, options)
		local floatingLabel = getPlaceholder("FloatingLabel")

		local cons = { }
		local object = addFunctions({
			Label = floatingLabel,
			Options = options,
			Connections = cons,
			Class = "FloatingLabel",
			Destroying = event.new()
		}, self)

		defer(addCons, object, cons)

		local canChange = true
		cons[#cons + 1] = floatingLabel.Changed:Connect(function()
			if not canChange then return end

			canChange = false
			object:_Rescale()

			render()

			object:_Rescale()
			canChange = true
		end)

		makeDraggable(floatingLabel, object, cons)
		object.Options._text ..= " "

		return object
	end,

	Destroy = function(self)
		self.Destroying:Fire()
		self.Label:Destroy()

		for i, v in self.Connections do
			v:Disconnect()
		end

		local window = getWindow(self)
		if not window then return end

		window.Objects[self.Flag] = nil
	end,

	_Rescale = function(self)
		local l = self.Label
		if not l or not l:FindFirstChild("Contents") then return end

		local l1, l2 = l.Contents.Contents.Text, l.Contents.Contents.Title
		local t1, t2 = l1.TextBounds, l2.TextBounds
		local hasIcon = setIcon(self.Options.Icon, icons, self, l2.ImageLabel) ~= ""

		l2.ImageLabel.Visible = hasIcon

		local add = hasIcon and 24 or 0
		local a1, a2 = #l1.Text ~= 0, #l2.Text ~= 0

		l1.Size = U2n(1, 0, 1, -16)
		l1.Position = U2o(0, 16)
		l.Visible = self.Options.Visible and (a1 or a2)

		if a1 and a2 then
			l.Size = U2o(max(t1.X, t2.X + 16) + 8 + add, t1.Y + t2.Y + 7)
		elseif a1 then
			l1.Size = U2s(1, 1)
			l1.Position = U2s(0, 0)

			l.Size = U2o(t1.X + 8, t1.Y + 8)
		elseif a2 then
			l.Size = U2o(t2.X + 24 + add, 22)
		end
	end,

	Refresh = function(self)
		local window = getWindow(self)
		if not window or window.Closed then return end

		local l = self.Label
		local options = self.Options

		safeReparent(l, gui.FloatingLabels)
		
		local lc = l.Contents
		local lcc = lc.Contents
		local lcct = lcc.Title
		local lcct2 = lcc.Text
		
		l.AnchorPoint = options.AnchorPoint
		l.Visible = options.Visible and (#lcct2.Text ~= 0 or #lcct.Text ~= 0)

		local op = options.Position
		if options._position ~= op then
			options._position = op
			l.Position = op
		end

		if options._text ~= options.Text or options._title ~= options.Title or options._icon ~= options.Icon then
			options._text, options._title, options._icon = options.Text, options.Title, options.Icon

			lcct2.Text = options.Text:sub(1, 199999)
			lcct.Text = options.Title:sub(1, 199999)
			self:_Rescale()
		end
		
		local theme = window.Theme
		local themeT = theme.Text
		local woptions = window.Options

		lc.BackgroundColor3 = theme.Back
		lc.OutsideStroke.Color = theme.Stroke
		lcct.TextColor3 = themeT
		lcct2.TextColor3 = themeT
		lc.TopNeon.BackgroundColor3 = theme.Main
		lc.UICorner.CornerRadius = cornerState[woptions.RoundEverything]
		lc.OutsideStroke.Enabled = not woptions.NoStrokes
	end
}

local tabHeaderFuncs = {
	DefaultOptions = {
		Text = "Header",
		Visible = true,
		Order = false,
		Translations = tfreeze({ }),
		ShowStart = true
	},
	Init = function(self, options)
		local instance = getPlaceholder("TabHeader")
		local object = addFunctions({
			Options = options,
			Instance = instance,
			Class = "Header"
		}, self)

		local cons = { }
		defer(addCons, object, cons)

		local cd = true
		cons[#cons + 1] = instance.View.Label.Changed:Connect(function()
			if not cd or not getWindow(object).Visible then return end

			cd = false
			instance.View.Label.Size = U2n(0, getTextSize(instance.View.Label.Text, instance.View.Label.TextSize, instance.View.Label.Font, V2n(99999, 99999)).X, 1, 0)
			render()
			instance.View.Label.Size = U2n(0, getTextSize(instance.View.Label.Text, instance.View.Label.TextSize, instance.View.Label.Font, V2n(99999, 99999)).X, 1, 0)
			cd = true
			render()
			instance.View.Label.Size = U2n(0, getTextSize(instance.View.Label.Text, instance.View.Label.TextSize, instance.View.Label.Font, V2n(99999, 99999)).X, 1, 0)
		end)

		return object
	end,
	Refresh = function(self)
		local inst = self.Instance
		local options = self.Options
		
		local themeT = getWindow(self).Theme.Text
		local view = inst.View
		local left = view.Left
		local label = view.Label

		inst.Separator.BackgroundColor3 = themeT
		left.BackgroundColor3 = themeT
		view.Right.BackgroundColor3 = themeT
		label.TextColor3 = themeT
		left.Visible = options.ShowStart

		orderUpdate(inst, options.Order)
		inst.Visible = options.Visible
		safeReparent(inst, self.Parent.Window.RealWindow.Contents.Display.PageButtons.List)
		label.Text = translate(self, "Text"):sub(0, 199999)
	end
}

local tabSeparatorFuncs = {
	DefaultOptions = {
		Visible = true,
		Invisible = false,
		Order = false,
	},
	Init = function(self, options)
		local instance = getPlaceholder("TabSeparator")
		return addFunctions({
			Options = options,
			Instance = instance,
			Class = "Separator"
		}, self)
	end,
	Refresh = function(self)
		local inst = self.Instance
		local window = getWindow(self)
		local options = self.Options

		local spm = inst.SeparatorMiddle
		local themeT = window.Theme.Text

		inst.Separator.BackgroundColor3 = themeT
		spm.BackgroundColor3 = themeT

		inst.Visible = options.Visible
		orderUpdate(inst, options.Order)
		safeReparent(inst, self.Parent.Window.RealWindow.Contents.Display.PageButtons.List)
		spm.Visible = not options.Invisible
		inst.Size = U2n(1, 0, 0, 10)
	end
}

local function _decodeThingy(thing)
	return jd(encoder:Decode(thing))
end

local windowFuncs; windowFuncs = {
	GetTheme = function(window)
		local theme = {
			Type = 7,

			["0"] = window.Options.ShadowSize,
			["1"] = floor(window.Options.ShadowTransparency * 100),
			["2"] = floor(window.Options.BackgroundTransparency * 100),
			["3"] = window.Options.ImageEnabled and 1 or 0,
			["4"] = tonumber(window.Options.ImageColor:ToHex(), 16),
			["5"] = floor(window.Options.ImageTransparency * 100),
			["6"] = window.Options.Image,
			["7"] = window.Options.NeonThickness,
			["8"] = window.Options.NeonType,
			["9"] = window.Options.NotificationSide,
			["10"] = window.Options.AnimationSpeed,
			["11"] = window.Options.Volume,
			["12"] = window.Options.MobileButtonAlwaysVisible and 1 or 0,
			["13"] = window.Options.MobileButtonVisible and 1 or 0,
			["14"] = window.Options.NotificationOgScaling and 1 or 0,
			["15"] = tonumber(window.Options.Theme.Main:ToHex(), 16),
			["16"] = tonumber(window.Options.Theme.Stroke:ToHex(), 16),
			["17"] = tonumber(window.Options.Theme.Back:ToHex(), 16),
			["18"] = tonumber(window.Options.Theme.Text:ToHex(), 16),
			["19"] = window.Options.InfoLabelExtra,
			["20"] = window.Options.ExtraInfoLabelTextEnabled and 1 or 0,
			["21"] = window.Options.OutsideStroke and 1 or 0,
			["22"] = floor(window.Options.CornerRadius),
			["23"] = window.Options.BlurBackground and 1 or 0,
			["24"] = window.Options.FullBlurSize and 1 or 0,
			["25"] = floor(uiBlur.BlurSize * 100),
			["26"] = window.Options.RoundEverything and 1 or 0,
			["27"] = window.Options.NoStrokes and 1 or 0,
			["28"] = window.Options.ModernToggles and 1 or 0,
			["29"] = window.Options.LargeModernToggles and 1 or 0,
			["30"] = window.Options.InfoLabelExtraAntiRich and 1 or 0
		}

		return theme
	end,
	SetTheme = function(window, theme)
		local type = tonumber(theme.Type)
		if not type or floor(type) ~= type or type > 7 or type < 1 then window:Notification({ Title = "Theme", Text = "The given theme is not a theme (most likely a config!)" }) return false end

		if type == 1 then
			window.Options.ShadowSize = theme.ShadowSize
			window.Options.ShadowTransparency = theme.ShadowTransparency
			window.Options.BackgroundTransparency = theme.BackgroundTransparency
			window.Options.ImageEnabled = theme.ImageEnabled
			window.Options.ImageColor = C3h(string["for" .. "mat"]("%06x", theme.ImageColor)) -- suspend studio warning
			window.Options.ImageTransparency = theme.ImageTransparency
			window.Options.Image = theme.Image
			window.Options.NeonThickness = theme.NeonThickness
			window.Options.NeonType = theme.NeonType
			window.Options.NotificationSide = theme.NotificationSide
			window.Options.AnimationSpeed = theme.AnimationSpeed
			window.Options.Volume = theme.Volume
			window.Options.MobileButtonAlwaysVisible = theme.MobileButtonAlwaysVisible
			window.Options.MobileButtonVisible = theme.MobileButtonVisible
			window.Options.Theme.Main = C3h(string["for" .. "mat"]("%06x", theme.Main)) -- same here and under
			window.Options.Theme.Stroke = C3h(string["for" .. "mat"]("%06x", theme.Stroke))
			window.Options.Theme.Back = C3h(string["for" .. "mat"]("%06x", theme.Back))
			window.Options.Theme.Text = C3h(string["for" .. "mat"]("%06x", theme.Text))
			window.Options.OutsideStroke = true
			window.Options.CornerRadius = 0
			window.Options.BlurBackground = false
			window.Options.InfoLabelExtra = ""
			window.Options.ExtraInfoLabelTextEnabled = true
			window.Options.NotificationOgScaling = false
			window.Options.FullBlurSize = false
			uiBlur.BlurSize = 1
			window.Options.RoundEverything = false
			window.Options.NoStrokes = false
			window.Options.ModernToggles = false
			window.Options.LargeModernToggles = false
			window.Options.InfoLabelExtraAntiRich = true
		else
			window.Options.ShadowSize = theme["0"]
			window.Options.ShadowTransparency = theme["1"] / 100
			window.Options.BackgroundTransparency = theme["2"] / 100
			window.Options.ImageEnabled = theme["3"] == 1
			window.Options.ImageColor = C3h(string["for" .. "mat"]("%06x", theme["4"])) -- suspend studio warning
			window.Options.ImageTransparency = theme["5"] / 100
			window.Options.Image = theme["6"]
			window.Options.NeonThickness = theme["7"]
			window.Options.NeonType = theme["8"]
			window.Options.NotificationSide = theme["9"]
			window.Options.AnimationSpeed = theme["10"]
			window.Options.Volume = theme["11"]
			window.Options.MobileButtonAlwaysVisible = theme["12"] == 1
			window.Options.MobileButtonVisible = theme["13"] == 1
			window.Options.NotificationOgScaling = theme["14"] == 1
			window.Options.Theme.Main = C3h(string["for" .. "mat"]("%06x", theme["15"])) -- same here and under
			window.Options.Theme.Stroke = C3h(string["for" .. "mat"]("%06x", theme["16"]))
			window.Options.Theme.Back = C3h(string["for" .. "mat"]("%06x", theme["17"]))
			window.Options.Theme.Text = C3h(string["for" .. "mat"]("%06x", theme["18"]))

			if type >= 3 then
				window.Options.InfoLabelExtra = theme["19"]
				window.Options.ExtraInfoLabelTextEnabled = theme["20"] == 1
			else
				window.Options.InfoLabelExtra = ""
				window.Options.ExtraInfoLabelTextEnabled = true
			end

			if type >= 4 then
				window.Options.OutsideStroke = theme["21"] == 1
				window.Options.CornerRadius = theme["22"]
				window.Options.BlurBackground = theme["23"] == 1
			else
				window.Options.OutsideStroke = true
				window.Options.CornerRadius = 0
				window.Options.BlurBackground = false
			end

			if type >= 5 then
				window.Options.FullBlurSize = theme["24"] == 1
			else
				window.Options.FullBlurSize = false
			end

			if type >= 6 then
				uiBlur.BlurSize = theme["25"] / 100
			else
				uiBlur.BlurSize = 1
			end

			if type >= 7 then
				window.Options.RoundEverything = theme["26"] == 1
				window.Options.NoStrokes = theme["27"] == 1
				window.Options.ModernToggles = theme["28"] == 1
				window.Options.LargeModernToggles = theme["29"] == 1
				window.Options.InfoLabelExtraAntiRich = theme["30"] == 1
			else
				window.Options.RoundEverything = false
				window.Options.NoStrokes = false
				window.Options.ModernToggles = false
				window.Options.LargeModernToggles = false
				window.Options.InfoLabelExtraAntiRich = true
			end
		end

		window:Refresh()
		return true
	end,
	GetConfig = function(self, cfg, getCfg)
		getCfg = getCfg or self.GetConfig
		cfg = cfg or { Type = 0 }

		local options = self.Options
		local cl = self.Class
		local fl = options.Flag

		if cl == "FloatingLabel" or cl == "Separator" or cl == "Header" then return end

		if cl == "ColorPicker" then
			if options.NoConfigs then return end
			return tonumber(options.Value:ToHex(), 16)
		end

		if cl == "Keybind" then
			return options.Value or -1 -- bypass NoConfigs, because you can set keybind to anything
		end

		if cl == "Button" or cl == "Label" then
			local pickers = { }
			for i, v in self.ColorPickers do
				pickers[tostring(i)] = getCfg(v, cfg, getCfg)
			end

			if count(pickers) == 0 then return end
			return { ColorPickers = pickers } -- fun fact: Keybinds also count as ColorPickers in that situation XD
		end

		if cl == "Toggle" or cl == "Input" then
			local pickers = { }
			for i, v in self.ColorPickers do
				pickers[tostring(i)] = getCfg(v, cfg, getCfg)
			end

			local c = count(pickers)
			local nc = options.NoConfigs

			if c == 0 and nc then return end

			local value = cl == "Toggle" and (options.Value and 1 or 0) or options.Value
			return c ~= 0 and not nc and {
				Value = value,
				ColorPickers = pickers
			} or c ~= 0 and {
				ColorPickers = pickers
			} or value
		end

		if cl == "Dropdown" or cl == "Slider" or cl == "TextBox" or cl == "CustomTab" then
			if options.NoConfigs then return end
			return options.Value
		end

		if cl == "Window" or cl == "Tab" or cl == "Groupbox" then
			for i, v in self.Objects do
				cfg[i] = getCfg(v, { }, getCfg)
			end

			return cfg
		end

		return warn("Unknown class", cl)
	end,
	SetConfig = function(self, cfg, setCfg)
		setCfg = setCfg or self.SetConfig

		local cl = self.Class
		local window = getWindow(self) or cl == "Window" and self
		if self == window and cfg.Type ~= 0 then window:Notification({ Title = "Config", Text = "The given config is not a config (most likely a theme!)" }) return false end

		local options = self.Options
		local fl = options.Flag
		if cfg == nil or cl == "FloatingLabel" or cl == "Separator" or cl == "Header" then return end

		if cl == "ColorPicker" then
			if options.NoConfigs then return end
			local newCol = C3h(string["for" .. "mat"]("%06x", cfg)) -- suspend studio warning
			if options.Value == newCol then return end

			return self:Set(newCol)
		end

		if cl == "Keybind" then
			return self:Set(cfg ~= -1 and cfg or nil) -- also bypass NoConfigs here
		end

		if cl == "CustomTab" then
			if options.NoConfigs then return end
			return self:Set(cfg)
		end

		if cl == "Dropdown" then
			if options.NoConfigs or tEqual(options.Value, cfg) then return end
			return self:Set(cfg)
		end

		if cl == "Window" or cl == "Tab" or cl == "Groupbox" then
			for i, v in cfg do
				local obj = self.Objects[i]
				if obj then
					setCfg(obj, v, setCfg)
				end
			end

			return
		end

		local isToggle = cl == "Toggle"
		if typeof(cfg) == "table" then
			if cfg.ColorPickers then
				for i, v in cfg.ColorPickers do
					i = tonumber(i)

					local obj = self.ColorPickers[i]
					if obj then
						setCfg(obj, v, setCfg)
					end
				end
			end

			if cfg.Value ~= nil then
				local b = typeof(cfg.Value) == "boolean"
				local value = b and cfg or not b and isToggle and cfg.Value == 1 or not isToggle and cfg.Value

				if options.NoConfigs or options.Value == value then return end
				self:Set(value)
			end
		else
			local b = typeof(cfg) == "boolean"
			local value = b and cfg or not b and isToggle and cfg == 1 or not isToggle and cfg

			if options.NoConfigs or options.Value == value then return end
			self:Set(value)
		end

		return true
	end,

	GetThemeString = function(self)
		return self:EncodeShareString(self:GetTheme())
	end,
	SetThemeString = function(self, str)
		local result = self:DecodeShareString(str)
		if not result or typeof(result) ~= "table" then return false, false end

		local res = self:SetTheme(result)
		return true, res == nil and true or res
	end,

	GetConfigString = function(self)
		return self:EncodeShareString(self:GetConfig())
	end,
	SetConfigString = function(self, str)
		local result = self:DecodeShareString(str)
		if not result or typeof(result) ~= "table" then return false, false end

		local res = self:SetConfig(result)
		return true, res == nil and true or res
	end,

	DecodeShareString = function(self, str)
		local s, e = pcall(_decodeThingy, str)
		return s and e or false
	end,
	EncodeShareString = function(self, str)
		return encoder:Encode(je(str))
	end,

	FloatingLabel = function(...)
		local label = newObject(floatingLabel, ...);
		(...).Objects[label.Flag] = label;
		(...).ChildAdded:Fire(label)

		return label
	end,
	ColorPicker = function(self, options)
		local opts = setmetatable(options or { }, defaultColorPickerOptions)
		local options = self.Options

		local cp = getPlaceholder("ColorPickerWindow")
		safeReparent(cp, gui.Holder.ColorPickerWindows)
		cp.Visible = true

		local cons = { }

		local first = true
		local function applyTheme()
			if options.KeepTheme and not first then return end
			first = false

			local options = self.Options
			cp.Contents.BackgroundColor3 = self.Theme.Back
			cp.Contents.TopNeon.BackgroundColor3 = self.Theme.Main
			cp.Contents.OutsideStroke.Color = self.Theme.Stroke
			cp.Contents.OutsideStroke.Enabled = not options.NoStrokes
			cp.Contents.UICorner.CornerRadius = cornerState[options.RoundEverything]
			cp.Contents.Contents.TopbarZone.Title.TextColor3 = self.Theme.Text
			cp.Contents.Contents.TopbarZone.Right.Close.ImageLabel.ImageColor3 = self.Theme.Text
			cp.Contents.Contents.Display.ColorZone.HUEZone.UIStroke.Color = self.Theme.Stroke
			cp.Contents.Contents.Display.ColorZone.HUEZone.Cursor.BackgroundColor3 = self.Theme.Text
			cp.Contents.Contents.Display.ColorZone.HUEZone.Cursor.UIStroke.Color = self.Theme.Stroke
			cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.UIStroke.Color = self.Theme.Stroke
			cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.Cursor.BackgroundColor3 = self.Theme.Text
			cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.Cursor.UIStroke.Color = self.Theme.Stroke
			cp.Contents.Contents.Display.ColorZone.Preview.UIStroke.Color = self.Theme.Stroke
			cp.Contents.Contents.TopbarZone.Title.Text = options.Text or "Color Picker"
			cp.Contents.Contents.Display.ColorZone.Preview.UICorner.CornerRadius = cornerState[options.RoundEverything]
			cp.Contents.Contents.Display.ColorZone.HUEZone.UICorner.CornerRadius = cornerState[options.RoundEverything]
			cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.UICorner.CornerRadius = cornerState[options.RoundEverything]
			cp.Contents.Contents.Display.BottomZone.TextButton.UICorner.CornerRadius = cornerState[options.RoundEverything]
			cp.Contents.Contents.Display.BottomZone.TextBoxes.R.UICorner.CornerRadius = cornerState[options.RoundEverything]
			cp.Contents.Contents.Display.BottomZone.TextBoxes.G.UICorner.CornerRadius = cornerState[options.RoundEverything]
			cp.Contents.Contents.Display.BottomZone.TextBoxes.B.UICorner.CornerRadius = cornerState[options.RoundEverything]

			cp.Contents.Contents.Display.ColorZone.Preview.UIStroke.Enabled = not options.NoStrokes
			cp.Contents.Contents.Display.ColorZone.HUEZone.UIStroke.Enabled = not options.NoStrokes
			cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.UIStroke.Enabled = not options.NoStrokes
			cp.Contents.Contents.Display.BottomZone.TextButton.UIStroke.Enabled = not options.NoStrokes
			cp.Contents.Contents.Display.BottomZone.TextBoxes.R.UIStroke.Enabled = not options.NoStrokes
			cp.Contents.Contents.Display.BottomZone.TextBoxes.G.UIStroke.Enabled = not options.NoStrokes
			cp.Contents.Contents.Display.BottomZone.TextBoxes.B.UIStroke.Enabled = not options.NoStrokes

			for i, v in cp.Contents.Contents.Display.BottomZone.TextBoxes:GetChildren() do
				if v:IsA("TextButton") then
					v.BackgroundColor3 = self.Theme.Stroke
					v.UIStroke.Color = self.Theme.Stroke
					v.TextBox.TextColor3 = self.Theme.Text
					v.TextLabel.TextColor3 = self.Theme.Text
				end
			end

			cp.Contents.Contents.Display.BottomZone.TextButton.BackgroundColor3 = self.Theme.Text
			cp.Contents.Contents.Display.BottomZone.TextButton.TextColor3 = self.Theme.Text
			cp.Contents.Contents.Display.BottomZone.TextButton.UIStroke.Color = self.Theme.Stroke
		end

		cons[#cons + 1] = self.ThemeChanged:Connect(applyTheme)
		applyTheme()

		cp.Size = U2o(50, 50)

		tweenOnce(cp, TIn(1 / handleAnimationSpeed(options.AnimationSpeed), Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = U2s(0.8, 0.8) })

		local HSV = { }
		HSV.H, HSV.S, HSV.V = opts.Value:ToHSV()

		local fHSV = Color3.fromHSV
		local function updateColor()
			local rgb = fHSV(HSV.H, HSV.S, HSV.V)

			cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.Cursor.Position = U2s(HSV.S, 1 - HSV.V)
			cp.Contents.Contents.Display.ColorZone.HUEZone.Cursor.Position = U2s(0.5, HSV.H)
			cp.Contents.Contents.Display.ColorZone.Preview.BackgroundColor3 = rgb
			cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.BackgroundColor3 = fHSV(HSV.H, 1, 1)
			cp.Contents.Contents.Display.BottomZone.TextBoxes.R.TextBox.Text = tostring(clamp(round(rgb.R * 255), 0, 255))
			cp.Contents.Contents.Display.BottomZone.TextBoxes.G.TextBox.Text = tostring(clamp(round(rgb.G * 255), 0, 255))
			cp.Contents.Contents.Display.BottomZone.TextBoxes.B.TextBox.Text = tostring(clamp(round(rgb.B * 255), 0, 255))

			render()
		end

		makeDraggable(cp, self, cons)

		local HDragging = false
		local VSDragging = false

		local con1; con1 = cp.Contents.Contents.Display.ColorZone.HUEZone.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			HDragging = true

			local old = uis.MouseIconEnabled
			uis.MouseIconEnabled = false
			tweenOnce(cp.Contents.Contents.Display.ColorZone.HUEZone.Cursor, TIn(0.35 / handleAnimationSpeed(options.AnimationSpeed)), { Size = U2n(1, 2, 0, 5), BackgroundTransparency = 0 })

			while HDragging and con1.Connected do
				HSV.H = clamp((mouse.Y - cp.Contents.Contents.Display.ColorZone.HUEZone.AbsolutePosition.Y) / cp.Contents.Contents.Display.ColorZone.HUEZone.AbsoluteSize.Y, 0, 1)
				self.Tooltip = "Hue: " .. floor(HSV.H * 360) .. "°"
				tooltipObject.CustomMousePosition = cp.Contents.Contents.Display.ColorZone.HUEZone.Cursor.AbsolutePosition + V2n(cp.Contents.Contents.Display.ColorZone.HUEZone.Cursor.AbsoluteSize.X - 2)

				updateColor()
			end

			tooltipObject.CustomMousePosition = mouse
			uis.MouseIconEnabled = old
			tweenOnce(cp.Contents.Contents.Display.ColorZone.HUEZone.Cursor, TIn(0.5 / handleAnimationSpeed(options.AnimationSpeed)), { Size = U2n(1, 2, 0, 2), BackgroundTransparency = 0.25 })

			wait(render())
			self.Tooltip = ""
		end)

		cons[#cons + 1] = cp.Contents.Contents.Display.ColorZone.HUEZone.InputEnded:Connect(function(input) 
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
				HDragging = false
			end
		end)

		local con2; con2 = cp.Contents.Contents.Display.ColorZone.PickerZone.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
			VSDragging = true

			local old = uis.MouseIconEnabled
			uis.MouseIconEnabled = false
			tweenOnce(cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.Cursor, TIn(0.35 / handleAnimationSpeed(options.AnimationSpeed)), { Size = U2o(7, 7), BackgroundTransparency = 0 })

			while VSDragging and con2 do
				HSV.S = clamp((mouse.X - cp.Contents.Contents.Display.ColorZone.PickerZone.AbsolutePosition.X) / cp.Contents.Contents.Display.ColorZone.PickerZone.AbsoluteSize.X, 0, 1)
				HSV.V = 1 - clamp((mouse.Y - cp.Contents.Contents.Display.ColorZone.PickerZone.AbsolutePosition.Y) / cp.Contents.Contents.Display.ColorZone.PickerZone.AbsoluteSize.Y, 0, 1)
				self.Tooltip = "Hue: " .. floor(HSV.H * 360) .. "°; Saturation: " .. floor(HSV.S * 100) .. "%; Value: " .. floor(HSV.V * 100) .. "%"
				tooltipObject.CustomMousePosition = cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.Cursor.AbsolutePosition - (cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.Cursor.AbsoluteSize / 2)

				updateColor()
			end

			tooltipObject.CustomMousePosition = mouse
			uis.MouseIconEnabled = old
			tweenOnce(cp.Contents.Contents.Display.ColorZone.PickerZone.Contents.Cursor, TIn(0.5 / handleAnimationSpeed(options.AnimationSpeed)), { Size = U2o(5, 5), BackgroundTransparency = 0.25 })

			wait(render())
			self.Tooltip = ""
		end)

		cons[#cons + 1] = con1
		cons[#cons + 1] = con2

		cons[#cons + 1] = cp.Contents.Contents.Display.ColorZone.PickerZone.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
				VSDragging = false 
			end
		end)

		local function setupTextBox(textBox, component)
			textBox.FocusLost:Connect(function(enterPressed)
				local text = textBox.Text
				if tonumber(text) then
					local value = tonumber(text) / 255
					if component == "R" then
						local newH, newS, newV = fHSV(HSV.H, HSV.S, HSV.V):ToHSV()
						local newColor = fHSV(newH, newS, newV)
						HSV.H, HSV.S, HSV.V = C3n(value, newColor.G, newColor.B):ToHSV()
					elseif component == "G" then
						local newH, newS, newV = fHSV(HSV.H, HSV.S, HSV.V):ToHSV()
						local newColor = fHSV(newH, newS, newV)
						HSV.H, HSV.S, HSV.V = C3n(newColor.R, value, newColor.B):ToHSV()
					elseif component == "B" then
						local newH, newS, newV = fHSV(HSV.H, HSV.S, HSV.V):ToHSV()
						local newColor = fHSV(newH, newS, newV)
						HSV.H, HSV.S, HSV.V = C3n(newColor.R, newColor.G, value):ToHSV()
					end
				end

				updateColor()
			end)
		end

		setupTextBox(cp.Contents.Contents.Display.BottomZone.TextBoxes.R.TextBox, "R")
		setupTextBox(cp.Contents.Contents.Display.BottomZone.TextBoxes.G.TextBox, "G")
		setupTextBox(cp.Contents.Contents.Display.BottomZone.TextBoxes.B.TextBox, "B")

		local result = nil
		local completed = false

		cons[#cons + 1] = cp.Contents.Contents.Display.BottomZone.TextButton.MouseButton1Click:Connect(function()
			result = fHSV(HSV.H, HSV.S, HSV.V)
			completed = true
		end)

		cons[#cons + 1] = cp.Contents.Contents.TopbarZone.Right.Close.MouseButton1Click:Connect(function()
			result = nil
			completed = true
		end)

		updateColor()

		repeat render() until completed

		for i, v in cons do
			if v.Connected then
				v:Disconnect()
			end
		end

		spawn(opts.Callback, result)
		spawn(function()
			tweenOnce(cp, TIn(0.5 / handleAnimationSpeed(options.AnimationSpeed), Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = U2o(0, 0) })
			wait(0.5 / handleAnimationSpeed(options.AnimationSpeed))

			cp:Destroy()
		end)

		spawn(playSound, "Click", self)
		return result
	end,
	PlaySound = function(self, name)
		spawn(playSound, name, self)
	end,
	Notify = function(self, ...)
		return self:Notification(...)
	end,
	Notification = function(self, options)
		options = setmetatable(options or { }, defaultNotificationOptions)

		if options.HasButtons then
			if options.Duration >= 1000 or options.Duration <= 0 then
				options.Duration = inf
			end
		else
			if options.Duration >= 1000 or options.Duration <= 0 then
				options.Duration = 120
			end

			options.Duration = clamp(options.Duration, 2, 120)
		end

		local opts = self.Options

		if options.Side == "-" then
			options.Side = opts.NotificationSide or "Left"
		end

		if options.UseOgScaling == "-" then
			options.UseOgScaling = opts.NotificationOgScaling or false
		end

		local s = options.Side
		if s == "-" then
			s = "Left"
		end

		gui.Notifications.NotificationsRight.Position = U2n(1, 0, 0, tbMeasurer.AbsoluteSize.Y + 2)

		local scaling = options.UseOgScaling
		local text = options.Text
		local side = gui.Notifications["Notifications" .. s]

		local tpos = U2n(s == "Left" and -1 or 1, s == "Right" and 1 or -1, 0, 0)
		local tpos2 = U2n(s == "Left" and -1 or 2, 0, 0, 3)

		if s == "Right" then
			ridx -= 1
		end

		local notif = getPlaceholder("Notification")
		local scale = U2n(1, 0, 0, scaling and (device == "Mobile" and 80 or 110) or max(getTextSize(text, 14, notif.Background.Holder.Text.Font, V2n(side.AbsoluteSize.X - 15, 99999)).Y, 14) + 33)

		safeReparent(notif, side)
		orderUpdate(notif, s == "Right" and ridx or 0)

		notif.Size = scale
		notif.Background.Position = tpos
		notif.Background.Holder.Position = tpos2
		notif.Background.Holder.AnchorPoint = V2n(s == "Left" and 0 or 1, 0)
		notif.Background.Holder.Title.Text = options.Title
		notif.Background.Holder.Text.Text = text
		notif.Background.Progress.Fill.Size = U2s(1, 1)
		notif.Background.Progress.Fill.AnchorPoint = V2n(s == "Left" and 0 or 1, 0)
		notif.Background.Progress.Fill.Position = U2s(s == "Left" and 0 or 1, 0)
		notif.Background.Holder.Buttons.Visible = options.HasButtons
		notif.Background.Holder.Halfer.Position = U2s(s == "Left" and 0 or 0.5, 0)
		notif.Background.OutsideStroke.Enabled = not opts.NoStrokes
		notif.Background.UICorner.CornerRadius = cornerState[opts.RoundEverything]
		notif.Background.Holder.UICorner.CornerRadius = cornerState[opts.RoundEverything]
		notif.Background.Progress.CanvasGroup.Half2.UICorner.CornerRadius = cornerState[opts.RoundEverything]
		safeReparent(notif.Background.Progress.CanvasGroup.Half2.UICorner, notif.Background.Progress.CanvasGroup["Half" .. (s == "Left" and "2" or "1")])
		notif.Background.Progress.CanvasGroup.Half2.Position = U2s(s == "Left" and 0 or 0.5, 0)
		notif.Background.Progress.CanvasGroup.Half2.Size = U2s(s == "Left" and 1 or 0.5, 1)
		notif.Background.Progress.CanvasGroup.Half1.Size = U2s(s == "Left" and 0.5 or 1, 1)
		notif.Visible = true

		notif.Background.Holder.BackgroundColor3 = self.Theme.Back
		notif.Background.BackgroundColor3 = self.Theme.Back
		notif.Background.Progress.CanvasGroup.GroupColor3 = self.Theme.Main
		notif.Background.Progress.Fill.BackgroundColor3 = self.Theme.Main
		notif.Background.Holder.Frame.BackgroundColor3 = self.Theme.Text
		notif.Background.Holder.Buttons.BackgroundColor3 = self.Theme.Back
		notif.Background.Holder.Title.TextColor3 = self.Theme.Text
		notif.Background.Holder.Text.TextColor3 = self.Theme.Text
		notif.Background.Holder.Buttons.Yes.ImageColor3 = self.Theme.Text
		notif.Background.Holder.Buttons.No.ImageColor3 = self.Theme.Text
		notif.Background.Holder.Halfer.BackgroundColor3 = self.Theme.Back

		local old = notif.Size
		notif.Size = U2s(1, 0)

		local function main()
			spawn(playSound, "Notification", self)
			local pick = false
			local done = false

			if options.Duration ~= inf then
				spawn(function()
					render()

					tweenOnce(notif.Background.Progress.Fill, TIn(options.Duration, Enum.EasingStyle.Linear), { Size = U2s(0, 1) })
					wait(options.Duration)
					done = true
				end)
			end

			local con1 = notif.Background.Holder.Buttons.Yes.MouseButton1Click:Connect(function()
				pick = true
				done = true
			end)

			local con2 = notif.Background.Holder.Buttons.No.MouseButton1Click:Connect(function()
				pick = false
				done = true
			end)

			spawn(function()
				tweenOnce(notif, TIn(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Size = old })

				wait(0.2)
				if done then return end

				tweenOnce(notif.Background, TIn(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Position = U2o(s == "Right" and 1 or 0, 0) })
				tweenOnce(notif.Background.Holder, TIn(.67 * 1.67 --[[AAAA, 67]], Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Position = U2n(s == "Left" and 0 or 1, 0, 0, 3) })
			end)

			repeat render() until done

			con1:Disconnect()
			con2:Disconnect()

			spawn(function()
				tweenOnce(notif.Background.Holder, TIn(0.3, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), { Position = tpos2 })
				wait(0.2)

				tweenOnce(notif.Background, TIn(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), { Position = tpos })
				wait(0.5)

				tweenOnce(notif, TIn(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), { Size = U2s(1, 0) })
				wait(0.2)

				notif:Destroy()
			end)

			spawn(options.Callback, options.HasButtons and pick or nil)
			return pick
		end

		if options.HasButtons then
			return main()
		else
			spawn(main)
		end
	end,
	DefaultOptions = {
		RecolorIcon = false,
		Icon = "",
		Image = "",
		ImageColor = C3n(1, 1, 1),
		Title = config.Name,
		Text = "",
		Footer = "",
		NotificationSide = "Right",
		ExtraInfoLabelText = "",
		InfoLabelExtra = "",
		ExtraInfoLabelTextEnabled = true,
		NotificationOgScaling = false,
		Closed = false,
		Visible = true,
		BlurBackground = false,
		DisableBlurBackground = false,
		OutsideStroke = true,
		CornerRadius = 0,
		_PrevVisible = false,
		_OldVisible = false,
		MobileButtonVisible = false,
		MobileButtonAlwaysVisible = false,
		AnimationSpeed = 1,
		NeonThickness = 1,
		BackgroundTransparency = 0,
		ImageTransparency = 0.85,
		ImageEnabled = true,
		ShadowTransparency = 0.5,
		Size = device == "Mobile" and U2n(1.35, 0, 0.5, 75) or U2n(0.7, 250, 0.375, 150), -- better dont change it, I forgot to implement it correctly, now I'm just lazy to fix it
		ShadowSize = 27,
		OnClose = function() end,
		Tooltip = "",
		NeonType = "Stroke", -- None, Stroke, Top
		Translations = tfreeze({ }),
		Language = "EN",
		_PrevLang = "EN",
		UnlockMouse = false,
		FullBlurSize = false,
		Keybind = Enum.KeyCode.LeftAlt,
		Debounce = false,
		First = true,
		UserProfile = false,
		SubscriptionExpiry = false,
		NoStrokes = false,
		RoundEverything = false,
		ModernToggles = false,
		LargeModernToggles = false,
		_LargeString = "",
		MobileButtonNeon = true,
		_Ready = false,
		InfoLabelExtraAntiRich = true,
		ThemeString = "",

		NotificationSound = sounds.Notification.SoundId,
		ClickSound = sounds.Click.SoundId,
		HoverSound = sounds.Hover.SoundId,
		Volume = 100, -- being divided by 200

		Theme = tfreeze({
			Back = C3R(20, 20, 20),
			Main = C3R(255, 0, 127),
			Stroke = C3R(0, 0, 0),
			Text = C3R(255, 255, 255)
		})
	},
	GetObjectFromHash = getObjectFromHash,
	Init = function(self, options)
		local window = getPlaceholder("Window")
		local mobileButton = getPlaceholder("MobileButton")
		local sounds = getPlaceholder("Sounds")
		safeReparent(sounds, window)

		local destroying = event.new()
		local cons = { }
		local object = addFunctions({
			Options = options,
			Window = window,
			MobileButton = mobileButton,
			Objects = { },
			AllObjects = { },
			ObjectAdded = event.new(),
			OnRefresh = event.new(),
			Defaults = { },
			Counters = { },
			PossibleLanguages = { "EN" },
			_Connections = cons,
			CurrentTab = false,
			Languages = langs,
			Class = "Window",
			ChildAdded = event.new(),
			LanguageAdded = event.new(),
			ThemeChanged = event.new(),
			Destroying = destroying,
			OnClose = destroying,
			BlurFrame = window.Blur,
			Icons = allIcons,
			Background = allBackgrounds,
			Emulator = emulator,
			IsMobile = device == "Mobile",
			IsDesktop = device == "PC",
			Platform = platform,
			RealPlatform = realPlatform,
			Device = device,
			Executor = executor,
			ExecutorVersion = version,
			Version = config.Version,
			Name = config.Name,
			Author = config.Author,
			Config = config
		}, self)

		uiBlur:Bind(window.Blur)
		object.Options.Theme = tclone(object.Options.Theme)
		object.Options._PrevTheme = tclone(object.Options.Theme)

		addPossibleTranslations(object)
		cons[#cons + 1] = object.ChildAdded:Connect(function(newObject)
			if newObject and newObject.Options then
				if typeof(object.Options.Translations) == "table" and object.Options.Translations[newObject.Flag] then
					newObject.Options.Translations = object.Options.Translations[newObject.Flag]
					addPossibleTranslations(newObject)
					newObject:Refresh()
				end
			else
				warn("Invalid object", newObject)
			end
		end)

		object._PrevLang = options.Language

		local titleZone = window.RealWindow.Contents.TopbarZone.TitleZone
		local cd = true

		cons[#cons + 1] = titleZone.Title.Changed:Connect(function()
			if not cd then return end

			cd = false
			titleZone.Title.Size = U2n(0, titleZone.Title.TextBounds.X, 1, 0)
			render()
			titleZone.Title.Size = U2n(0, titleZone.Title.TextBounds.X, 1, 0)
			cd = true
		end)

		cons[#cons + 1] = titleZone.Icon.Changed:Connect(function()
			titleZone.Icon.Visible = setIcon(options.Icon, icons, object.Proxy, titleZone.Icon) ~= ""
		end)

		local footer = window.RealWindow.Contents.Footer.Label
		cons[#cons + 1] = footer:GetPropertyChangedSignal("Text"):Connect(function()
			if not object.Options.Visible then return end

			local isVisible = clean(footer.Text) ~= ""

			footer.Parent.Visible = isVisible
			window.RealWindow.Contents.Display.Size = U2n(1, 0, 1, isVisible and -15 or 0)
		end)

		makeDraggable(window, object, cons)
		makeDraggable(mobileButton, object, cons)

		local start = 0
		cons[#cons + 1] = mobileButton.MouseButton1Down:Connect(function()
			start = tick()
		end)

		cons[#cons + 1] = mobileButton.MouseButton1Click:Connect(function()
			if tick() - start > 0.35 then return end
			object:Toggle()
		end)

		local startPos, startPosition, startSize, moveConnection, upConnection

		local oldDeltaX, oldDeltaY = 0, 0
		local function move()
			if not moveConnection or not upConnection then return end

			local delta = V2n(mouse.X, mouse.Y) - startPos
			local xOffset, yOffset = max(0, startSize.X.Offset + delta.X), max(0, startSize.Y.Offset + delta.Y)

			window:TweenSizeAndPosition(U2n(startSize.X.Scale, xOffset, startSize.Y.Scale, yOffset), U2n(startPosition.X.Scale, startPosition.X.Offset + (xOffset > 0 and delta.X / 2 or oldDeltaX), startPosition.Y.Scale, startPosition.Y.Offset + (yOffset > 0 and delta.Y / 2 or oldDeltaY)), nil, nil, 0.35 / handleAnimationSpeed(object.Options.AnimationSpeed), true)

			oldDeltaX, oldDeltaY = xOffset > 0 and delta.X / 2 or oldDeltaX, yOffset > 0 and delta.Y / 2 or oldDeltaY
		end

		cons[#cons + 1] = window.RealWindow.Corner.Resize.MouseButton1Down:Connect(function()
			startPos = V2n(mouse.X, mouse.Y)
			startSize = window.Size
			startPosition = window.Position

			oldDeltaX, oldDeltaY = 0, 0

			if moveConnection then
				moveConnection:Disconnect()
				moveConnection = nil
			end

			if upConnection then
				upConnection:Disconnect()
				upConnection = nil
			end

			moveConnection = mouse.Move:Connect(function()
				defer(move) -- wait for full mouse update
			end)

			upConnection = uis.InputEnded:Connect(function(input)
				if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end

				moveConnection:Disconnect()
				upConnection:Disconnect()

				moveConnection, upConnection = nil, nil
			end)
		end)

		local dontRefresh = false
		cons[#cons + 1] = object.ThemeChanged:Connect(function()
			if dontRefresh then return end

			dontRefresh = true
			object.Proxy:RefreshAll()
			dontRefresh = false
		end)

		local shOpen = false
		local msf = window.RealWindow.Contents.Display.PageButtons.List.MobileSizeFix
		local cnt = 0

		cons[#cons + 1] = rs.RenderStepped:Connect(function()
			cnt = (cnt + 1) % 5

			if cnt == 0 then
				msf.Size = U2n(mrandom(), 0, 0, 1)
			end

			for i, v in object.Options._PrevTheme do
				if object.Options.Theme[i] ~= v then
					object.Options._PrevTheme = tclone(object.Options.Theme)
					object.ThemeChanged:Fire(object.Options.Theme)
					break
				end
			end

			if not object.Options.UnlockMouse and not shOpen or not object.Options.Visible then return end
			unlockMouse()
		end)

		local tui = window.RealWindow.Contents.TopbarZone.Right.ToggleUI
		cons[#cons + 1] = tui.MouseEnter:Connect(function()
			tweenOnce(tui.ImageLabel, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { ImageTransparency = 0 })
		end)

		cons[#cons + 1] = tui.MouseLeave:Connect(function()
			tweenOnce(tui.ImageLabel, TIn(0.6 / handleAnimationSpeed(object.Options.AnimationSpeed)), { ImageTransparency = 0.25 })
		end)

		cons[#cons + 1] = tui.MouseButton1Click:Connect(function()
			object:Toggle()
		end)

		local s = window.RealWindow.Contents.TopbarZone.Right.Settings
		local so = window.RealWindow.Contents.SettingsOverlay

		so.Visible = false
		so.SettingsHub.AnchorPoint = V2n(0, 0)
		so.BackgroundTransparency = 1
		so.SettingsHub.Image.Position = U2s(0, 0)

		window.Visible = false
		window.Size = U2s(0, 0)
		window.RealWindow.ClipsDescendants = true
		window.RealWindow.Overlay.Visible = true
		window.Shadow.Size = U2s(0, 0)
		window.Shadow.ImageTransparency = 1
		window.RealWindow.Overlay.BackgroundTransparency = 0
		options._LargeString = tostring(options.NoStrokes) .. tostring(options.ModernToggles) .. tostring(options.RoundEverything) .. tostring(options.LargeModernToggles)

		cons[#cons + 1] = s.MouseEnter:Connect(function()
			tweenOnce(s.ImageLabel, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { ImageTransparency = 0 })
		end)

		cons[#cons + 1] = s.MouseLeave:Connect(function()
			if not shOpen then
				tweenOnce(s.ImageLabel, TIn(0.6 / handleAnimationSpeed(object.Options.AnimationSpeed)), { ImageTransparency = 0.25 })
			end
		end)

		cons[#cons + 1] = s.MouseButton1Click:Connect(function()
			shOpen = not shOpen

			if shOpen then
				so.Visible = true

				tweenOnce(so, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { BackgroundTransparency = 0.75 })
				tweenOnce(so.SettingsHub, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { AnchorPoint = V2n(0, 1) })
				tweenOnce(so.SettingsHub.Image, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { Position = U2s(0, 1) })
			else
				tweenOnce(so, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { BackgroundTransparency = 1 })
				tweenOnce(so.SettingsHub, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { AnchorPoint = V2n(0, 0) })
				tweenOnce(so.SettingsHub.Image, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { Position = U2s(0, 0) })

				wait(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed))
				if shOpen then return end

				so.Visible = false
			end
		end)

		cons[#cons + 1] = so.MouseButton1Click:Connect(function()
			shOpen = false

			tweenOnce(so, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { BackgroundTransparency = 1 })
			tweenOnce(so.SettingsHub, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { AnchorPoint = V2n(0, 0) })
			tweenOnce(so.SettingsHub.Image, TIn(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed)), { Position = U2s(0, 0) })
			tweenOnce(s.ImageLabel, TIn(0.6 / handleAnimationSpeed(object.Options.AnimationSpeed)), { ImageTransparency = 0.25 })

			wait(0.4 / handleAnimationSpeed(object.Options.AnimationSpeed))
			if shOpen then return end

			so.Visible = false
		end)

		defer(windowSetup, object)

		local origOptions = options
		local options = { Position = U2o(20, 65), AnchorPoint = V2n(0, 0),
			Visible = false,
			ShowFPS = true,
			ShowExecutor = true,
			ShowTime = true,
			ShowPing = true,
			ShowPlayers = true,
			ShowGap = true
		}

		local label = object:FloatingLabel("Info" .. id(), options)
		local myCons = { }

		label.Destroying:Once(function()
			object.Options.InfoLabel = nil
			for i, v in myCons do
				v:Disconnect()
			end
		end)

		local buffer = { }
		local ping = plr:GetNetworkPing()

		spawn(function()
			while wait(1) and not object.Closed do
				object.Options.First = false
				ping = plr:GetNetworkPing()
			end
		end)

		local cnt = 0
		myCons[#myCons + 1] = rs.RenderStepped:Connect(function(dt)
			local fps = 1 / dt
			if fps > 100000 then
				fps = 0
			end

			local ffps = max(round(fps), 1)
			while #buffer >= ffps do
				tremove(buffer, 1)
			end

			tinsert(buffer, fps)

			cnt = (cnt + 1) % 5
			if not label.Visible or cnt ~= 0 then return end

			local lines = { }
			local inserted = false
			if options.ShowExecutor then
				inserted = true
				tinsert(lines, executor .. " | " .. version)
			end

			if inserted and options.ShowGap then
				tinsert(lines, "")
			end

			local inserted2 = false
			if options.ShowFPS then
				inserted2 = true

				local estFps = 0
				for i, v in buffer do
					estFps += v
				end

				estFps = clamp(round((estFps / #buffer) * 10) / 10, 0, 2e9)

				local estFpsS = tostring(estFps)
				if not estFpsS:find("%.") then
					estFpsS ..= ".0"
				end

				tinsert(lines, "FPS: " .. paintRichText(estFpsS, estFps <= 120 and C3n(1):Lerp(C3n(0, 1, 1), estFps / 120) or C3n(0, 1, 1):Lerp(C3n(0.7, 0.3, 1), clamp((estFps - 120) / 120, 0, 2))))
			end

			if options.ShowPing then
				local pingS = round(ping * 1000)
				pingS = "Ping: " .. (pingS >= 0 and paintRichText(tostring(pingS) .. " ms", C3n(0, 1):Lerp(C3n(1), clamp(pingS / 1000, 0, 1))) or paintRichText("Disconnected", C3n(1)))

				if not inserted2 then
					inserted2 = true
					tinsert(lines, pingS)
				else
					lines[#lines] ..= " | " .. pingS
				end
			end

			if options.ShowPlayers then
				inserted2 = true
				tinsert(lines, "Players: " .. (#plrs:GetPlayers()) .. " / " .. plrs.MaxPlayers)
			end

			if options.ShowTime then
				inserted2 = true
				tinsert(lines, os.date("%H:%M:%S"))
			end

			if inserted and not inserted2 and options.ShowGap then
				lines[#lines] = nil
			end

			local lines = concat(lines, "\n")
			if #origOptions.ExtraInfoLabelText ~= 0 and origOptions.ExtraInfoLabelTextEnabled then
				lines ..= (lines ~= "" and "\n" or "") .. typeof(origOptions.ExtraInfoLabelText) == "table" and table.concat(origOptions.ExtraInfoLabelText, "\n") or options.ExtraInfoLabelText
			end

			if origOptions.InfoLabelExtra ~= "" then
				lines ..= (lines ~= "" and "\n" or "") .. (origOptions.InfoLabelExtraAntiRich and antiRich(origOptions.InfoLabelExtra) or origOptions.InfoLabelExtra)
			end

			label.Text = lines
		end)

		object.Options.InfoLabel = label
		for i, v in myCons do
			cons[#cons + 1] = v
		end

		spawn(function()
			gui.Enabled = false
			render()
			gui.Enabled = true

			while not object.Closed and wait(0.05) do
				object:RefreshUserProfile()
			end
		end)

		return object
	end,
	RefreshUserProfile = function(self)
		local window = self.Window
		local options = self.Options

		if not options.UserProfile then
			window.RealWindow.Contents.Display.PageButtons.UserProfile.Visible = false
			window.RealWindow.Contents.Display.PageButtons.List.Size = U2n(1, 0, 1, -5)

			return
		end

		window.RealWindow.Contents.Display.PageButtons.UserProfile.Visible = true
		window.RealWindow.Contents.Display.PageButtons.List.Size = U2n(1, 0, 1, -45)
		window.RealWindow.Contents.Display.PageButtons.UserProfile.User.Image = userIcon

		local text = plr.Name ~= plr.DisplayName and plr.DisplayName ~= "" and (plr.DisplayName:gsub("_", " ")) or "@" .. plr.Name
		if options.SubscriptionExpiry then
			if tonumber(options.SubscriptionExpiry) then
				text ..= "\n<font size=\"10\" transparency=\"0.25\">" .. formatTime(options.SubscriptionExpiry - tick()) .. "</font>"
			else
				text ..= "\n<font size=\"10\" transparency=\"0.25\">" .. tostring(options.SubscriptionExpiry) .. "</font>"
			end
		end

		window.RealWindow.Contents.Display.PageButtons.UserProfile.User.TextLabel.Text = text
	end,
	Refresh = function(self)
		local options = self.Options
		if self.Options.Closed then return end

		self.OnRefresh:Fire()

		if table.isfrozen(options.Theme) then
			options.Theme = tclone(options.Theme)
		end

		local title = translate(self, "Text")
		if #title == 0 then
			title = translate(self, "Title")

			if #title == 0 then
				title = "Window"
			end
		end

		local window = self.Window
		local realWindow = window.RealWindow
		local realWindowContents = realWindow.Contents
		local topbarZone = realWindowContents.TopbarZone
		local settingsOverlay = realWindowContents.SettingsOverlay
		local footer = realWindowContents.Footer
		local display = realWindowContents.Display
		local pageButtons = display.PageButtons

		realWindow.BackgroundColor3 = options.Theme.Back
		realWindow.Overlay.BackgroundColor3 = options.Theme.Back
		settingsOverlay.SettingsHub.BackgroundColor3 = options.Theme.Back
		settingsOverlay.SettingsHub.AntiCorner.BackgroundColor3 = options.Theme.Back

		realWindow.OutsideStroke.Color = options.Theme.Stroke
		realWindow.OutsideStroke.Enabled = options.OutsideStroke
		settingsOverlay.BackgroundColor3 = options.Theme.Stroke
		window.Shadow.ImageColor3 = options.Theme.Stroke
		footer.Label.TextStrokeColor3 = options.Theme.Stroke
		display.PagesDark.BackgroundColor3 = options.Theme.Stroke

		realWindow.InsideStroke.Color = options.Theme.Main
		realWindow.TopNeon.BackgroundColor3 = options.Theme.Main
		realWindow.Corner.Resize.BackgroundColor3 = options.Theme.Main

		settingsOverlay.SettingsHub.Separator.BackgroundColor3 = options.Theme.Text
		topbarZone.TitleZone.Title.TextColor3 = options.Theme.Text
		topbarZone.TitleZone.Icon.ImageColor3 = options.RecolorIcon and options.Theme.Text or C3n(1, 1, 1)
		topbarZone.Right.Settings.ImageLabel.ImageColor3 = options.Theme.Text
		topbarZone.Right.ToggleUI.ImageLabel.ImageColor3 = options.Theme.Text
		footer.Label.TextColor3 = options.Theme.Text
		footer.SeparatorTop.BackgroundColor3 = options.Theme.Text
		pageButtons.SeparatorTop.BackgroundColor3 = options.Theme.Text
		pageButtons.UserProfile.User.BackgroundColor3 = options.Theme.Text
		pageButtons.SeparatorLeft.BackgroundColor3 = options.Theme.Text
		pageButtons.Filler.BackgroundColor3 = options.Theme.Text
		pageButtons.UserProfile.User.TextLabel.TextColor3 = options.Theme.Text

		if options._OldVisible then
			if options.ShadowTransparency ~= options._OldShadowTransparency or options.BackgroundTransparency ~= options._OldBackgroundTransparency then
				options._OldShadowTransparency = options.ShadowTransparency
				options._OldBackgroundTransparency = options.BackgroundTransparency
				window.Shadow.ImageTransparency = 1 - ((1 - options.ShadowTransparency) * (1 - options.BackgroundTransparency))
			end
			if options.NeonType ~= options._OldNeonType or options.ShadowSize ~= options._OldShadowSize then
				options._OldNeonType = options.NeonType
				options._OldShadowSize = options.ShadowSize

				window.Shadow.Size = U2n(1, options.ShadowSize * 2, 1, options.ShadowSize * 2)
			end
		end

		setIcon(options.ImageEnabled and options.Image or "", backgrounds, self, realWindow.Contents.BackgroundImage, true)
		local button = self.MobileButton
		button.Visible = options.Flag ~= guid and (options.MobileButtonAlwaysVisible or device == "Mobile" or options.MobileButtonVisible and not options.Visible)
		safeReparent(button, options.Flag ~= guid and gui.MobileButtons or nil)
		button.CanvasGroup.TextLabel.Text = title:sub(1, 1):upper()
		setIcon(options.Icon or "", nil, self, button.CanvasGroup.ImageLabel)
		button.CanvasGroup.ImageLabel.Visible = true
		button.CanvasGroup.TextLabel.Visible = button.CanvasGroup.ImageLabel.Image == ""
		button.CanvasGroup.BackgroundTransparency = 1
		button.CanvasGroup.Size = U2s(1, 1)
		button.UIStroke.Enabled = not options.NoStrokes
		button.CanvasGroup.UIStroke.Enabled = options.MobileButtonNeon
		button.UICorner.CornerRadius = cornerState[options.RoundEverything]
		button.CanvasGroup.UICorner.CornerRadius = cornerState[options.RoundEverything]

		button.BackgroundColor3 = options.Theme.Back
		button.UIStroke.Color = options.Theme.Stroke
		button.CanvasGroup.TextLabel.TextColor3 = options.Theme.Text
		button.CanvasGroup.TextLabel.TextStrokeColor3 = options.Theme.Stroke
		button.CanvasGroup.UIStroke.Color = options.Theme.Main

		safeReparent(window, options.Flag ~= guid and gui.Holder.Windows or nil)
		window.SoundCache.Volume = options.Volume / 200
		window.Sounds.Notification.SoundId = options.NotificationSound
		window.Sounds.Click.SoundId = options.ClickSound
		window.Sounds.Hover.SoundId = options.HoverSound
		topbarZone.TitleZone.Title.Text = title:sub(1, 199999)
		setIcon(options.Icon or "", nil, self, topbarZone.TitleZone.Icon)
		footer.Label.Text = translate(self, "Footer")
		realWindow.Contents.BackgroundImage.ImageTransparency = options.ImageTransparency
		realWindow.Contents.BackgroundImage.ImageColor3 = options.ImageColor
		settingsOverlay.SettingsHub.Image.ImageTransparency = options.ImageTransparency
		settingsOverlay.SettingsHub.Image.ImageColor3 = options.ImageColor
		realWindow.BackgroundTransparency = options.BackgroundTransparency
		settingsOverlay.SettingsHub.BackgroundTransparency = 0
		setIcon(options.ImageEnabled and options.Image or "", backgrounds, self, settingsOverlay.SettingsHub.Image, true)
		realWindow.InsideStroke.Thickness = options.NeonThickness
		realWindow.UICorner.CornerRadius = Un(0, options.CornerRadius * 0.1)
		realWindow.Contents.BackgroundImage.UICorner.CornerRadius = realWindow.UICorner.CornerRadius
		realWindow.Corner.UICorner.CornerRadius = realWindow.UICorner.CornerRadius
		realWindow.Overlay.UICorner.CornerRadius = realWindow.UICorner.CornerRadius
		settingsOverlay.UICorner.CornerRadius = realWindow.UICorner.CornerRadius
		settingsOverlay.SettingsHub.UICorner.CornerRadius = realWindow.UICorner.CornerRadius
		settingsOverlay.SettingsHub.Image.UICorner.CornerRadius = realWindow.UICorner.CornerRadius
		window.Blur.Size = options.FullBlurSize and U2s(1, 1) or U2n(1, -12, 1, -12)

		if options.NeonType == "Stroke" then
			realWindowContents.Size = U2n(1, -options.NeonThickness * 2, 1, -options.NeonThickness * 2)
			realWindowContents.Position = U2s(0.5, 0.5)
			realWindowContents.AnchorPoint = V2n(0.5, 0.5)
			realWindow.AnchorPoint = V2n(0.5, 0.5)
			realWindow.Position = U2s(0.5, 0.5)
			realWindow.TopNeon.Visible = false
			realWindow.InsideStroke.Enabled = true
		else
			realWindowContents.Size = U2n(1, 0, 1, options.CornerRadius <= 0 and options.NeonType == "Top" and -options.NeonThickness or 0)
			realWindowContents.Position = U2n(0.5, 0, 0, options.CornerRadius <= 0 and options.NeonType == "Top" and options.NeonThickness or 0)
			realWindowContents.AnchorPoint = V2n(0.5, 0)
			realWindow.TopNeon.Size = U2n(1, 0, 0, options.NeonThickness)
			realWindow.AnchorPoint = V2n(0, 0)
			realWindow.Position = U2s(0, 0)
			realWindow.TopNeon.Visible = options.CornerRadius <= 0 and options.NeonType == "Top"
			realWindow.InsideStroke.Enabled = false
		end

		options.Language = options.Language:sub(1, 2):upper()
		self:RefreshUserProfile()

		local generatedString = tostring(options.NoStrokes) .. tostring(options.ModernToggles) .. tostring(options.RoundEverything) .. tostring(options.LargeModernToggles)
		if options._PrevLang ~= options.Language or options._LargeString ~= generatedString then
			options._PrevLang = options.Language
			options._LargeString = generatedString
			self:RefreshAll()
		end

		local tt = options.Tooltip
		if tt ~= options._PrevTooltip then
			options._PrevTooltip = tt
			tooltipObject.Options.Window = self
			tooltipObject.Options.Text = tt
			tooltipObject:Refresh()
		end

		window.Blur.Visible = not options.DisableBlurBackground and options.BlurBackground and options.Visible
		if options._OldVisible ~= options.Visible and not options.Debounce and options._Ready then
			options._OldVisible = options.Visible
			if options.Visible then
				self:Show()
			else
				self:Hide()
			end
		end

		return self
	end,
	FirstLaunch = ranTimes <= 1,
	LaunchTimes = round(ranTimes),
	RefreshAll = function(self)
		refreshEverything(self)
		self.ThemeChanged:Fire(self.Options.Theme)
	end,
	AddTab = function(...)
		local tab = newObject(tabFuncs, ...);
		(...).Objects[tab.Flag] = tab;
		(...).ChildAdded:Fire(tab)

		return tab
	end,
	Tab = function(self, ...)
		return self:AddTab(...)
	end,
	NewTab = function(self, ...)
		return self:AddTab(...)
	end,
	AddCustomTab = function(...)
		local tab = newObject(customTabFuncs, ...);
		(...).Objects[tab.Flag] = tab;
		(...).ChildAdded:Fire(tab)

		return tab
	end,
	CustomTab = function(self, ...)
		return self:AddCustomTab(...)
	end,
	NewCustomTab = function(self, ...)
		return self:AddCustomTab(...)
	end,
	AddHeader = function(...)
		local head = newObject(tabHeaderFuncs, ...);
		(...).Objects[head.Flag] = head;
		(...).ChildAdded:Fire(head)

		return head
	end,
	Header = function(self, ...)
		return self:AddHeader(...)
	end,
	NewHeader = function(self, ...)
		return self:AddHeader(...)
	end,
	AddTabHeader = function(self, ...)
		return self:AddHeader(...)
	end,
	TabHeader = function(self, ...)
		return self:AddHeader(...)
	end,
	NewTabHeader = function(self, ...)
		return self:AddHeader(...)
	end,
	AddSeparator = function(...)
		local separator = newObject(tabSeparatorFuncs, ...);
		(...).Objects[separator.Flag] = separator;
		(...).ChildAdded:Fire(separator)

		return separator
	end,
	Separator = function(self, ...)
		return self:AddSeparator(...)
	end,
	NewSeparator = function(self, ...)
		return self:AddSeparator(...)
	end,
	AddTabSeparator = function(self, ...)
		return self:AddSeparator(...)
	end,
	TabSeparator = function(self, ...)
		return self:AddSeparator(...)
	end,
	NewTabSeparator = function(self, ...)
		return self:AddSeparator(...)
	end,
	SetTab = function(self, tabOrTabName)
		if typeof(tabOrTabName) == "string" then
			local tab = self.Objects[tabOrTabName]
			if not tab then
				local f = string["for" .. "mat"] -- suspend the warning in Roblox Studio
				error(f("Tab '%s' not found!", tabOrTabName), 0)
			end

			return tab:SwitchTo()
		elseif typeof(tabOrTabName) == "table" or typeof(tabOrTabName) == "userdata" then
			if not tabOrTabName.SwitchTo then
				error("Tab not found!", 0)
			end

			return tabOrTabName:SwitchTo()
		end

		error("Tab not found!", 0)
	end,
	_Show = function(self)
		if self.Options.Debounce then return end
		self.Options.Debounce = true

		local window = self.Window.RealWindow
		local t = 1 / handleAnimationSpeed(self.Options.AnimationSpeed)

		window.Parent.Visible = true
		window.Overlay.Visible = true
		window.ClipsDescendants = true
		window.Overlay.BackgroundTransparency = 0

		tweenOnce(window.Parent, TIn(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = self.Options.Size })
		tweenOnce(window.Parent.Shadow, TIn(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 1 - ((1 - self.Options.ShadowTransparency) * (1 - self.Options.BackgroundTransparency)), Size = U2n(1, self.Options.ShadowSize * 2, 1, self.Options.ShadowSize * 2) })
		tweenOnce(window.Overlay, TIn(t * 2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 1 })

		wait(0.1 / handleAnimationSpeed(self.Options.AnimationSpeed))

		window.ClipsDescendants = false

		wait(t - 0.1)

		window.Overlay.Visible = false

		wait(0.1)
		self.Options.Debounce = false
	end,
	_Hide = function(self)
		if self.Options.Debounce then return end

		local kb = self.Options.Keybind
		local mb = device == "Mobile" or self.Options.MobileButtonAlwaysVisible or self.Options.MobileButtonVisible

		if not self.Options.Keybind and not mb and not self.Options.Closed then
			if not self.Options.ToggleKeyObject or not self.Options.ToggleKeyObject.ColorPickers[0] or not self.Options.ToggleKeyObject.ColorPickers[0].Value then
				self.Options.Visible = true
				return self:Notification({ Title = "Unable to hide the UI", Duration = 10, Text = "Please set the keybind first!" })
			else
				kb = Enum.KeyCode:FromValue(self.Options.ToggleKeyObject.ColorPickers[0].Value)
			end
		end

		self.Options.Debounce = true

		if self.IsDesktop and not self.Options.Closed then
			if not self.Options.First then
				self.Proxy:Notification({ Title = "UI hidden", Duration = 5, Text = (kb and "Press " .. kb.Name or "") .. (mb and (kb and " or" or "Press") .. " the floating button" or "") .. " to open UI" })
			end

			self.Options.First = false
		end

		local window = self.Window.RealWindow
		local t = 1 / handleAnimationSpeed(self.Options.AnimationSpeed)

		self.Options.Size = window.Parent.Size
		window.Parent.Visible = true
		window.Overlay.Visible = true
		window.ClipsDescendants = false
		window.Overlay.BackgroundTransparency = 1

		tweenOnce(window.Parent, TIn(t, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Size = U2s(0, 0) })
		tweenOnce(window.Parent.Shadow, TIn(t * 5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 1, Size = U2s(0, 0) })
		tweenOnce(window.Overlay, TIn(t / 1.5), { BackgroundTransparency = 0 })

		wait(t - 0.1)
		window.ClipsDescendants = true

		if t - 0.1 > 0 then
			wait(0.1 / handleAnimationSpeed(self.Options.AnimationSpeed))
		end

		window.Parent.Visible = false

		wait(0.1)
		self.Options.Debounce = false
	end,
	Close = function(self)
		if self.Options.Closed then return end
		self.Destroying:Fire()

		self.Options.Closed = true
		self.Options.Debounce = false
		self.MobileButton:Destroy()
		uiBlur:Unbind(self.BlurFrame)

		self:Hide()
		for i, v in self.Defaults do
			i:Set(v)
		end

		for i, v in self.Objects do
			if v.Class ~= "Tab" and v.Class ~= "Header" and v.Class ~= "Separator" then
				v:Destroy()
			end
		end

		for i, v in self._Connections do
			if v.Connected then
				delay(1, v.Disconnect, v)
			end
		end

		spawn(self.Options.OnClose, self)
	end,
	Show = function(self)
		if self.Options.Debounce then return end

		self.Options.Visible = true
		spawn(self._Show, self)
	end,
	Hide = function(self)
		if self.Options.Debounce then return end

		self.Options.Visible = false
		spawn(self._Hide, self)
	end,
	Toggle = function(self)
		if self.Options.Debounce then return end

		self.Options.Visible = not self.Options.Visible

		if not self.Options.Visible and not self.Options.Keybind and device ~= "Mobile" and not (self.Options.MobileButtonAlwaysVisible or self.Options.MobileButtonVisible) and not self.Options.Closed then
			if not self.Options.ToggleKeyObject or not self.Options.ToggleKeyObject.ColorPickers[0] or not self.Options.ToggleKeyObject.ColorPickers[0].Value then
				self.Options.Visible = true
				return self:Notification({ Title = "Unable to hide the UI", Duration = 10, Text = "Please set the keybind first!" })
			end
		end

		self:Refresh()
	end
}

tooltipObject = newObject({
	DefaultOptions = {
		Text = "",
		Window = false,
		CustomMousePosition = mouse,
		Dark = false
	},

	Init = function(self, options)
		local tooltip = getPlaceholder("Tooltip")

		local cd = true
		tooltip.TextLabelInvisible.Changed:Connect(function()
			if not cd then return end

			cd = false
			tooltip.TextLabel.Text = tooltip.TextLabelInvisible.Text
			tooltip.Size = U2o(tooltip.TextLabelInvisible.TextBounds.X + 14, tooltip.TextLabelInvisible.TextBounds.Y + 14)
			render()
			tooltip.TextLabel.Text = tooltip.TextLabelInvisible.Text
			tooltip.Size = U2o(tooltip.TextLabelInvisible.TextBounds.X + 14, tooltip.TextLabelInvisible.TextBounds.Y + 14)
			cd = true
			render()
			tooltip.TextLabel.Text = tooltip.TextLabelInvisible.Text
			tooltip.Size = U2o(tooltip.TextLabelInvisible.TextBounds.X + 14, tooltip.TextLabelInvisible.TextBounds.Y + 14)
		end)

		local object = addFunctions({
			Tooltip = tooltip,
			Options = options,
			Class = "Tooltip"
		}, self)

		rs.RenderStepped:Connect(function()
			object.Proxy:Refresh()
		end)

		return object
	end,

	Refresh = function(self)
		local options = self.Options
		local cap : string = options.Text
		local tt = self.Tooltip
		tt.Visible = #cap ~= 0
		tt.TextLabelInvisible.Text = cap:sub(0, 199999)
		safeReparent(tt, gui)

		options.CustomMousePosition = options.CustomMousePosition or mouse

		local safe = 25
		local tooltipSize = tt.AbsoluteSize
		local screenSize = gui.AbsoluteSize
		local mousePos = V2n(options.CustomMousePosition.X, options.CustomMousePosition.Y)
		local targetPos = mousePos + V2n(15, 50)

		tt.Position = U2o(clamp(targetPos.X, safe, screenSize.X - tooltipSize.X - safe), clamp(targetPos.Y, safe + tooltipSize.Y, screenSize.Y - tooltipSize.Y - safe))
		tt.TextLabelInvisible.Size = U2o(floor(gui.AbsoluteSize.X / 2.5), 10000)

		local theme = (options.Window or coreWindow)
		if theme then
			theme = theme.Theme
		end

		if not theme then return end

		tt.BackgroundColor3 = theme.Back:Lerp(theme.Stroke, options.Dark and 0.35 or 0)
		tt.OutsideStroke.Color = theme.Stroke
		tt.TextLabel.TextColor3 = theme.Text
	end
})

library = newObject({
	DefaultOptions = {
		Tooltip = "",

		Theme = {
			Back = C3R(20, 20, 20),
			Main = C3R(255, 0, 127),
			Stroke = C3R(0, 0, 0),
			Text = C3R(255, 255, 255)
		}
	},

	FirstLaunch = ranTimes <= 1,
	LaunchTimes = round(ranTimes),
	Init = function(self, options)
		coreWindow = newObject(windowFuncs, nil, { Visible = false, UnlockMouse = false, Text = guid, Flag = guid, MobileButtonVisible = false, MobileButtonAlwaysVisible = false })
		coreWindow.Window.Visible = false
		safeReparent(coreWindow.Window, nil)
		coreWindow.Window:GetPropertyChangedSignal("Parent"):Connect(function()
			safeReparent(coreWindow.Window, nil)
			safeReparent(coreWindow.MobileButton, nil)
		end)

		local object = addFunctions({
			_CoreWindow = coreWindow,
			Options = options,
			Languages = langs,
			Windows = { },
			Class = "Library",
			WindowAdded = event.new(),
			WindowRemoved = event.new(),
			EventClass = event,
			Icons = allIcons,
			Background = allBackgrounds,
			Example = require(script.Example), -- function
			Emulator = emulator,
			IsMobile = device == "Mobile",
			IsDesktop = device == "PC",
			Platform = platform,
			RealPlatform = realPlatform,
			Device = device,
			Executor = executor,
			ExecutorVersion = version,
			Version = config.Version,
			Name = config.Name,
			Author = config.Author,
			Config = config
		}, self)

		coreWindow.InfoLabel:Destroy()

		return object
	end,

	Refresh = function(self)
		local options = self.Options
		self._CoreWindow.Theme = options.Theme

		local tt = options.Tooltip

		if tt ~= "" then
			tooltipObject.Options.Window = self
			tooltipObject.Options.Text = tt
			tooltipObject:Refresh()

			options.Tooltip = ""
		end
	end,

	Window = function(self, ...)
		self:Refresh()

		local window = newObject(windowFuncs, nil, ...)
		tinsert(self.Windows, window)

		self.WindowAdded:Fire(window)
		window.Destroying:Once(function()
			tremove(self.Windows, tfind(self.Windows, window))
			self.WindowRemoved:Fire(window)
		end)

		repeat render() until window.Options.ExecutionTimes -- function

		window._Ready = true

		local ts = window.ThemeString
		if ts ~= "" then
			window:SetThemeString(ts)
		end

		return window
	end,

	Notification = function(self, ...)
		self:Refresh()
		return self._CoreWindow:Notification(...)
	end,
	Notify = function(self, ...)
		return self:Notification(...)
	end,

	DecodeShareString = function(self, str)
		local s, e = pcall(_decodeThingy, str)
		return s and e or false
	end,
	EncodeShareString = function(self, str)
		return encoder:Encode(je(str))
	end
})

global[key] = library

library.WindowRemoved:Connect(function()
	if #library.Windows == 0 then
		uiBlur.BlurSize = 1
	end
end)

return library
