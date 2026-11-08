-- TDS Hardcore modifier capture
-- language: Lua, target: Roblox TDS, executor: Potassium
-- Run this while standing in the Hardcore intermission lobby, BEFORE the macro.
-- Click each modifier card by hand, then press start.  Every remote the client
-- sends is written to TDSModifierCapture.txt in the executor workspace.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local LOG = "TDSModifierCapture.txt"
local Lines = {}

local function log(Message)
	table.insert(Lines, Message)
	print(Message)
	if writefile then
		pcall(function()
			writefile(LOG, table.concat(Lines, "\n") .. "\n")
		end)
	end
end

local function encode(Value)
	local Kind = typeof(Value)
	if Kind == "string" or Kind == "number" or Kind == "boolean" then
		return tostring(Value)
	elseif Kind == "table" then
		local Ok, Json = pcall(HttpService.JSONEncode, HttpService, Value)
		return Ok and Json or "<unencodable table>"
	elseif Kind == "Instance" then
		return `<{Value.ClassName}:{Value:GetFullName()}>`
	else
		return `<{Kind}>`
	end
end

local function dumpAttributes(Instance, Indent)
	local Attributes = Instance:GetAttributes()
	for Name, Value in next, Attributes do
		log(`{Indent}  @{Name} = {encode(Value)}`)
	end
end

local function dumpState()
	local State = ReplicatedStorage:FindFirstChild("State")
	if not State then
		log("State: <missing>")
		return
	end
	log("--- ReplicatedStorage.State ---")
	for _, Child in ipairs(State:GetChildren()) do
		local Value = ""
		if Child:IsA("ValueBase") or Child:IsA("StringValue") then
			Value = ` = {encode(Child.Value)}`
		end
		log(`  {Child.ClassName} {Child.Name}{Value}`)
		dumpAttributes(Child, "  ")
	end
end

local function dumpRemotes()
	log("--- Remotes ---")
	for _, Child in ipairs(ReplicatedStorage:GetDescendants()) do
		if Child:IsA("RemoteFunction") or Child:IsA("RemoteEvent") or Child:IsA("UnreliableRemoteEvent") then
			log(`  {Child.ClassName} {Child:GetFullName()}`)
		end
	end
end

local function dumpLobby()
	local Found = false
	for _, Name in ipairs({ "HardcoreIntermissionLobby", "IntermissionLobby" }) do
		local Lobby = Workspace:FindFirstChild(Name)
		if not Lobby then
			continue
		end
		Found = true
		log(`--- Workspace.{Name} ---`)
		for _, Child in ipairs(Lobby:GetChildren()) do
			log(`  {Child.ClassName} {Child.Name}`)
		end
		for _, Object in ipairs(Lobby:GetDescendants()) do
			local Text = nil
			if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
				Text = tostring(Object.Text)
			end
			local Interesting = Object.Name:lower():find("mod", 1, true)
				or (Text and Text:lower():find("mod", 1, true))
				or Object:IsA("ClickDetector")
				or Object:IsA("ProximityPrompt")
			if Interesting then
				log(`  * {Object.ClassName} {Object:GetFullName()}{Text and ` text="{Text}"` or ""}`)
				dumpAttributes(Object, "    ")
			end
		end
	end
	if not Found then
		log("Lobby: <not in an intermission lobby>")
	end
end

local function dumpGui()
	log("--- PlayerGui ---")
	for _, Gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
		if not Gui:IsA("ScreenGui") then
			continue
		end
		local Hits = {}
		for _, Object in ipairs(Gui:GetDescendants()) do
			local Text = nil
			if Object:IsA("TextLabel") or Object:IsA("TextButton") or Object:IsA("TextBox") then
				Text = tostring(Object.Text)
			end
			local Interesting = Object.Name:lower():find("mod", 1, true)
				or (Text and Text:lower():find("mod", 1, true))
			if Interesting then
				table.insert(Hits, `{Object.ClassName}:{Object:GetFullName()}{Text and `="{Text}"` or ""}`)
			end
		end
		if #Hits > 0 then
			log(`  GUI {Gui.Name} (Enabled={tostring(Gui.Enabled)})`)
			for _, Hit in ipairs(Hits) do
				log(`    {Hit}`)
			end
		else
			log(`  GUI {Gui.Name} (Enabled={tostring(Gui.Enabled)}) -- no modifier matches`)
		end
	end
end

log("=== TDS MODIFIER CAPTURE ===")
dumpState()
dumpRemotes()
dumpLobby()
dumpGui()
log("--- live remote capture ---")
log("Click the modifier cards, then start the match.")
log("Run getgenv().TDSCaptureStop() when done.")

local Capturing = true
getgenv().TDSCaptureStop = function()
	Capturing = false
	log("capture stopped")
end

local Hooked = pcall(function()
	local OldNamecall
	OldNamecall = hookmetamethod(game, "__namecall", function(Self, ...)
		if Capturing then
			local Method = getnamecallmethod()
			if Method == "InvokeServer" or Method == "FireServer" then
				if typeof(Self) == "Instance"
					and (Self:IsA("RemoteFunction") or Self:IsA("RemoteEvent") or Self:IsA("UnreliableRemoteEvent")) then
					local Args = table.pack(...)
					local Parts = {}
					for Index = 1, Args.n do
						table.insert(Parts, encode(Args[Index]))
					end
					log(`>> {Self.Name} :: {Method}({table.concat(Parts, ", ")})`)
				end
			end
		end
		return OldNamecall(Self, ...)
	end)
end)

if not Hooked then
	log("[warn] hookmetamethod unavailable -- remote capture off, dump only")
end

-- Re-dump once the lobby actually loads, in case the script ran too early.
task.spawn(function()
	local Dumped = false
	while Capturing do
		if not Dumped and (Workspace:FindFirstChild("HardcoreIntermissionLobby")
			or Workspace:FindFirstChild("IntermissionLobby")) then
			Dumped = true
			log("--- lobby loaded, re-dumping ---")
			dumpLobby()
			dumpGui()
		end
		task.wait(1)
	end
end)
