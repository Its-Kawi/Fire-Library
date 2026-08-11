--[[
	This is a quick version of FireLibrary's loader (only for exploit environments)
	Everything is pretty much the same as in the original library, but this one loads much faster (but update check comes AFTER the main loading cycle)
	Read the README.md for more info
]]--

---

local GITHUB =  "https://api.github.com/repos/Null-Cherry/"
local http = game:GetService("HttpService")
local sg = game:GetService("StarterGui")

local env = getfenv()
local function g(n)
	return env[n]
end

local request = g("request")

local function gHTTPG(url)
	return game:HttpGet(url)
end

local function httpGet(url)
	if request then
		local result = request({ Url = url, Method = "GET", Headers = { } })
		local success = result.Success or tostring(result.StatusCode):sub(1, 1) == "2"
		return success and result.Body or "", success
	else
		local s, e = pcall(gHTTPG, url)
		return s and e or "", s
	end
end

local function getLastCommitID()
	return http:JSONDecode(httpGet(GITHUB .. "/Fire-Library/commits?path=Files%2FLibrary%2Elua", true))[1].sha
end

local function fix(str)
	return (str:gsub("[\n\r\f\t\0 ]", ""))
end

local function loadError(message)
	message = message or "Error occured loading the library"
	sg:SetCore("SendNotification", {
		Title = "Fire Library error",
		Text = message,
		Duration = 5
	})

	error("FireLibrary : " .. message, 0)
end

local key = "FireLibrary"
local global = (g("getgenv") or function() return _G end)()

local fl = global[key]
if fl then
	return fl
end

local ext1 = ".txt"
local ext2 = ".lua"

local wf, rf, iF = g("writefile"), g("readfile"), g("isfile")
local success, error
local spawn = task.spawn

local function update()
	local contents = httpGet(GITHUB .. "Fire-Library/refs/heads/main/Files/Library.lua", true)
	local local1 = contents:find("local", 1, true)
	if not local1 then return false, "Invalid request return" end

	local localEnd = contents:find(";", local1, true)
	if not localEnd then return false, "Invalid request return" end

	local cont = "local parent = nil" .. contents:sub(localEnd + 1) .. "\nreturn require(obj:FindFirstChildOfClass(\"ModuleScript\"))"
	success, error = loadstring(cont)
	if not success then return false, "Library failed to load: " .. error end

	if wf and rf and iF then
		wf(key .. "/Library" .. ext2, cont)
	end

	spawn(function()
		local success, error = pcall(getLastCommitID)
		local current
		if success then
			current = fix(error)
		end
		
		if current and wf then
			wf(key .. "/Library" .. ext1, current)
		end
	end)

	return success
end

if wf and rf and iF and iF(key .. "/Library" .. ext1) and iF(key .. "/Library" .. ext2) then
	spawn(update)
	success, error = loadstring(rf(key .. "/Library" .. ext2))
	
	if success then
		success, error = pcall(success, key)
		if success then
			fl = error
			global[key] = fl

			return fl
		end
	end
end

fl = global[key]
if fl then
	return fl
end

local success, error = update()
if not success then return loadError(error) end

fl = global[key]
if fl then
	return fl
end

success, error = pcall(success, key)
if not success then return loadError("Library failed to load: " .. error) end

fl = global[key]
if fl then
	return fl
end

fl = error
global[key] = fl

return fl
