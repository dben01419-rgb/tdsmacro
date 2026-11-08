local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunction = if not GameSpoof then ReplicatedStorage:WaitForChild("RemoteFunction") else SpoofEvent
local RemoteEvent = if not GameSpoof then ReplicatedStorage:WaitForChild("RemoteEvent") else SpoofEvent
local TowerProps = {}

local PreviewHolder = ReplicatedStorage.PreviewHolder
local AssetsHologram = PreviewHolder.AssetsHologram
local AssetsError = PreviewHolder.AssetsError
local PreviewFolder = Workspace.PreviewFolder
local PreviewErrorFolder = Workspace.PreviewErrorFolder

function CheckPlace()
    return if not GameSpoof then (game.PlaceId == 5591597781) else if GameSpoof == "Ingame" then true else false
end

function StackPosition(Position,SkipCheck)
    local Position = if typeof(Position) == "Vector3" then Position else Vector3.new(0,0,0)
    local PositionY = Position.Y
    for i,v in ipairs(_G.TowersContained) do
        --if v.Position and v.Placed and (math.floor(v.Position.X) == math.floor(Position.X) and math.floor(v.Position.Z) == math.floor(Position.Z)) and (v.Position - Position).magnitude < 5 then (math.abs(v.Position.X - Position.X) < 1 and math.abs(v.Position.Z - Position.Z) < 1)
        if not (v.Position) then -- and v.Placed
            continue
        end
        if (v.Position * Vector3.new(1,0,1) - Position * Vector3.new(1,0,1)).magnitude < 1 and (v.Position - Position).magnitude < 5 then
            Position = Vector3.new(Position.X,v.Position.Y + 5, Position.Z)
        end
    end
    return Vector3.new(0,Position.Y - PositionY,0)
end

local PreviewParents = {
    [PreviewHolder] = true,
    [PreviewFolder] = true,
    [PreviewErrorFolder] = true,
}

function DebugTower(Object, Color) --Rework in Future
    if not Object then return end
    -- A preview hologram never gets a HumanoidRootPart -- only the server's
    -- placed instance does. Waiting on a hologram used to spin here forever and
    -- freeze the scheduler; waiting even a few seconds taxed every placement.
    if not (tonumber(Object.Name) and Object:FindFirstChild("HumanoidRootPart")) then
        if PreviewParents[Object.Parent] then return end
        local Deadline = os.clock() + 3
        while not (tonumber(Object.Name) and Object:FindFirstChild("HumanoidRootPart")) do
            if os.clock() > Deadline then
                ConsoleWarn(`DebugTower: "{Object.Name}" has no HumanoidRootPart, skipping tag`)
                return
            end
            task.wait()
        end
    end
    local Color = Color or Color3.new(1, 0, 0)
    local HumanoidRootPart = Object:FindFirstChild("HumanoidRootPart")
    if HumanoidRootPart:FindFirstChild("BillboardGui") then
        HumanoidRootPart:FindFirstChild("BillboardGui"):Destroy()
    end
    local GuiInstance = Instance.new("BillboardGui")
    GuiInstance.Parent = HumanoidRootPart
    GuiInstance.Adornee = HumanoidRootPart
    GuiInstance.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
    GuiInstance.Size = UDim2.new(0, 250, 0, 50)
    GuiInstance.AlwaysOnTop = true
    local Text = Instance.new("TextLabel")
    Text.Parent = GuiInstance
    Text.BackgroundTransparency = 1
    Text.Text = Object.Name
    Text.Font = "Legacy"
    Text.Size = UDim2.new(1, 0, 0, 70)
    Text.TextSize = 22
    Text.TextScaled = false
    Text.TextColor3 = Color
    Text.TextStrokeColor3 = Color3.new(0, 0, 0)
    Text.TextStrokeTransparency = 0.5
    return GuiInstance
end

StratXLibrary.AllowPlace = false

task.spawn(function()
        repeat
            task.wait()
        until CheckPlace()
        if not ReplicatedStorage.Assets:FindFirstChild("Troops") then
            repeat
                task.wait()
            until ReplicatedStorage.Assets:FindFirstChild("Troops")
        end
        local TroopsFolder = ReplicatedStorage.Assets:FindFirstChild("Troops")
        for i,v in next, GetTowersInfo() do
            if v.Equipped and not (TroopsFolder:FindFirstChild(i) and TroopsFolder:FindFirstChild(i).Skins:FindFirstChild(v.Skin)) then
                repeat 
                    task.wait(1)
                    if not (TroopsFolder:FindFirstChild(i) and TroopsFolder:FindFirstChild(i).Skins:FindFirstChild(v.Skin)) then
                        RemoteEvent:FireServer("Streaming", "SelectTower", i, v.Skin)
                    end
                until TroopsFolder:FindFirstChild(i) and TroopsFolder:FindFirstChild(i).Skins:FindFirstChild(v.Skin)
            end
        end
        StratXLibrary.AllowPlace = true
end)

function PreviewInitial()
    if not ReplicatedStorage.Assets:FindFirstChild("Troops") then
        repeat
            task.wait()
        until ReplicatedStorage.Assets:FindFirstChild("Troops")
    end
    local TroopsFolder = ReplicatedStorage.Assets:FindFirstChild("Troops")
    for i,v in next, GetTowersInfo() do
        if v.Equipped then
            -- The loadout can be applied after the streaming pass that raises
            -- AllowPlace, so a tower can appear here before its asset exists.
            -- Indexing it blindly used to throw and take the Place task with it.
            local Troop = TroopsFolder:FindFirstChild(i)
            local Skin = Troop and Troop:FindFirstChild("Skins") and Troop.Skins:FindFirstChild(v.Skin)
            if not Skin then
                for _ = 1, 15 do
                    Troop = Troop or TroopsFolder:FindFirstChild(i)
                    Skin = Troop and Troop:FindFirstChild("Skins") and Troop.Skins:FindFirstChild(v.Skin)
                    if Skin then break end
                    pcall(function()
                        RemoteEvent:FireServer("Streaming", "SelectTower", i, v.Skin)
                    end)
                    task.wait(1)
                end
            end
            if Skin then
                TowerProps[i] = v.Skin
                local Tower = Skin:Clone()
                Tower.Parent = AssetsHologram
                Tower.Name = i
                for i2,v2 in next, Tower:GetDescendants() do
                    if v2:IsA("BasePart") then
                        v2.Material = Enum.Material.ForceField
                        if v2.CanCollide then
                            v2.CanCollide = false
                        end
                    end
                end
                local Tower = Tower:Clone()
                for i2,v2 in next, Tower:GetDescendants() do
                    if v2:IsA("BasePart") then
                        v2.Color = Color3.new(1, 0, 0)
                    end
                end
                Tower.Parent = AssetsError
            else
                ConsoleWarn(`PreviewInitial: "{i}" skin "{tostring(v.Skin)}" is not streamed`)
            end
        end
    end
end

function AddFakeTower(Name,Type)
    local Type = Type or "Normal"
    if not TowerProps[Name] then
        pcall(PreviewInitial)
    end
    --local SkinName = SkinName or TowerProps[Name]
    local Folder = if Type == "Normal" then AssetsHologram else AssetsError
    local Tower = Folder:FindFirstChild(Name) --ReplicatedStorage.Assets.Troops[Name].Skins[SkinName]
    if not Tower then
        -- Refresh once, then wait. Returning nil here used to kill the caller.
        for _ = 1, 10 do
            pcall(PreviewInitial)
            Tower = Folder:FindFirstChild(Name)
            if Tower then break end
            task.wait(1)
        end
    end
    if Tower then
        Tower = Tower:Clone()
        Tower.Parent = PreviewHolder --if Type == "Normal" then PreviewFolder else PreviewErrorFolder
        if Tower:FindFirstChild("AnimationController") then
            task.spawn(function()
                for _ = 1, 20 do
                    task.wait(.7)
                    local Success = pcall(function()
                        Tower:FindFirstChild("AnimationController"):LoadAnimation(Tower.Animations.Idle["0"]):Play()
                    end)
                    if Success then return end
                end
            end)
        end
        return Tower
    end
    ConsoleWarn(`AddFakeTower: no {Type} hologram for "{Name}", placing without a preview`)
end

function TowerHeightOffset(Model)
    local Root = Model and Model.PrimaryPart
    local HeightOffset = Root and Root:FindFirstChild("HeightOffset")
    return HeightOffset and math.abs(HeightOffset.CFrame.Y) or 0
end

--[[if CheckPlace() then
    PreviewInitial()
end]]

--[[{
    ["TowerName"] = "",
    ["TypeIndex"] = ""
    ["Position"] = Vector3.new(),
    ["Rotation"] = CFrame.new(),
    Timer = {Wave,Min,Sec,InWave},

}]]

return function(self, p1)
    local tableinfo = p1--ParametersPatch("Place",...)
    local Tower = tableinfo["TowerName"]
    local Position = tableinfo["Position"] or Vector3.new(0,0,0)
    local Rotation = tableinfo["Rotation"] or CFrame.new(0,0,0)
    local Wave,Min,Sec,InWave = tableinfo["Wave"] or 0, tableinfo["Minute"] or 0, tableinfo["Second"] or 0, tableinfo["InBetween"] or false
    if not CheckPlace() then
        return
    end
    local CompatRelease = BeginCompatAction(tableinfo)
    prints(`Queue Place: {Tower} (Wave {Wave})`)
    SetActionInfo("Place","Total")
    _G.TowersContained.Index += 1
    local TempNum = _G.TowersContained.Index
    _G.TowersContained[TempNum] = {
        ["TowerName"] = Tower,
        ["Placed"] = false,
        ["TypeIndex"] = "Nil",
        ["Position"] = Position + StackPosition(Position),
        ["Rotation"] = Rotation,
        ["OldPosition"] = Position,
        ["PassedTimer"] = false,
        ["TopPathUpgrade"] = 0,
        ["BottomPathUpgrade"] = 0
    }

    local CurrentCount = StratXLibrary.CurrentCount
    local TowerTable = _G.TowersContained[TempNum]
    repeat task.wait() until StratXLibrary.AllowPlace
    prints(`Place Ready: {Tower} (Wave {Wave})`)

    local TowerModel = AddFakeTower(TowerTable.TowerName)
    local HeightOffset = TowerHeightOffset(TowerModel)
    --TowerModel.PrimaryPart.CFrame = CFrame.new(TowerTable.Position) + Vector3.new(0,math.abs(TowerModel.PrimaryPart.HeightOffset.CFrame.Y),0)
    if TowerModel then
        TowerModel:PivotTo(CFrame.new(TowerTable.Position + Vector3.new(0, HeightOffset, 0)) * TowerTable.Rotation)
        TowerModel.Name = TempNum
        DebugTower(TowerModel,Color3.fromRGB(255, 130, 0))
        TowerTable.TowerModel = TowerModel
        if UtilitiesTab.flags.TowersPreview then
            TowerModel.Parent = PreviewFolder
        end
    end

    task.spawn(function()
        if not (tableinfo.Compat or tableinfo.Wave == nil) and not TimeWaveWait(Wave, Min, Sec, InWave, tableinfo["Debug"]) then
            CompatRelease()
            print("Return")
            return
        end
        prints(`Place Sending: {Tower} (Wave {Wave})`)
        TowerTable.PassedTimer = true
        local PlaceCheck, ErrorModel
        task.delay(45, function()
            if typeof(PlaceCheck) ~= "Instance" then
                if (type(PlaceCheck) == "string" and PlaceCheck == "Game is over!") or CurrentCount ~= StratXLibrary.RestartCount then
                    return
                end
                ConsoleError("Tower Index: "..TempNum..", Type: \""..Tower.."\" Hasn't Been Placed In The Last 45 Seconds. Check Again Its Arguments Or Order.")
                ConsoleError(`Returned PlaceCheck Value: {PlaceCheck}`)
            end
        end)
        repeat
            if type(PlaceCheck) == "string" and PlaceCheck == "You cannot place here!" and not ErrorModel then
                ErrorModel = AddFakeTower(TowerTable.TowerName,"Error")
                if ErrorModel then
                    ErrorModel:PivotTo(CFrame.new(TowerTable.Position + Vector3.new(0, HeightOffset, 0)) * TowerTable.Rotation)
                    ErrorModel.Name = TempNum
                    DebugTower(ErrorModel,Color3.new(1, 0, 0))
                    TowerTable.ErrorModel = ErrorModel
                    if UtilitiesTab.flags.TowersPreview then
                        ErrorModel.Parent = PreviewErrorFolder
                    end
                end
                if TowerModel then
                    TowerModel.Parent = PreviewHolder
                end
            end
            if CurrentCount ~= StratXLibrary.RestartCount then
                CompatRelease()
                return
            end
            PlaceCheck = RemoteFunction:InvokeServer("Troops","Place",{
                ["Rotation"] = TowerTable.Rotation,
                ["Position"] = TowerTable.Position
            },Tower
            )
            task.wait()
        until typeof(PlaceCheck) == "Instance" --return instance
        PlaceCheck.Name = TempNum
        local TowerInfo = StratXLibrary.TowerInfo[Tower]
        TowerInfo[2] += 1
        PlaceCheck:SetAttribute("TypeIndex", Tower.." "..tostring(TowerInfo[2]))
        TowerInfo[1].Text = Tower.." : "..tostring(TowerInfo[2])
        TowerTable.Instance = PlaceCheck
        TowerTable.TypeIndex = PlaceCheck:GetAttribute("TypeIndex")
        TowerTable.Placed = true
        -- The server accepted the placement; release the source-order queue
        -- before optional preview/UI bookkeeping runs.
        CompatRelease()
        TowerTable.Target = "First"
        TowerTable.TopPathUpgrade = 0
        TowerTable.BottomPathUpgrade = 0
        if TowerModel then
            TowerModel.Parent = PreviewHolder
        end
        TowerTable.DebugTag = DebugTower(TowerTable.Instance,Color3.new(0.35, 0.7, 0.3))

        if TowerTable.DebugTag and not UtilitiesTab.flags.TowersPreview then
            TowerTable.DebugTag.Enabled = false
        end
        if ErrorModel then
            ErrorModel.Parent = PreviewHolder
        end
        if getgenv().Debug then
            task.spawn(DebugTower,TowerTable.Instance)
        end
        local TowerType = GetTypeIndex(tableinfo["TypeIndex"],TempNum)
        SetActionInfo("Place")
        local StackingCheck = (TowerTable.Position - TowerTable.OldPosition).magnitude > 1
        ConsoleInfo(`Placed {Tower} Index: {PlaceCheck.Name}, Type: \"{TowerType}\", (Wave {Wave}, Min: {Min}, Sec: {Sec}, InBetween: {InWave}, Time Error: {ReplicatedStorage.State.Timer.Time.Value - Min*60+Sec}) {if StackingCheck then ", Stacked Position" else ", Original Position"}`)
    end)
end
