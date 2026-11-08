local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFunction = if not GameSpoof then ReplicatedStorage:WaitForChild("RemoteFunction") else SpoofEvent
local RemoteEvent = if not GameSpoof then ReplicatedStorage:WaitForChild("RemoteEvent") else SpoofEvent
--[[{
    ["TowerIndex"] = "",
    ["TypeIndex"] = "",
    ["Wave"] = number,
    ["Minute"] = number,
    ["Second"] = number,
}]]
return function(self, p1)
    local tableinfo = p1--ParametersPatch("Sell",...)
    local Tower = tableinfo["TowerIndex"]
    local Wave,Min,Sec,InWave = tableinfo["Wave"] or 0, tableinfo["Minute"] or 0, tableinfo["Second"] or 0, tableinfo["InBetween"] or false 
    if not CheckPlace() then
        return
    end
    local CompatRelease = BeginCompatAction(tableinfo)
    for i = 1, #Tower do
        SetActionInfo("Sell","Total")
    end
    task.spawn(function()
        if not TimeWaveWait(Wave, Min, Sec, InWave, tableinfo["Debug"]) then
            CompatRelease()
            return
        end
        for i,v in next, Tower do
            local SoldCheck
            repeat
                if not TowersCheckHandler(v) then
                    CompatRelease()
                    return
                end
                SoldCheck = RemoteFunction:InvokeServer("Troops","Sell",{
                    ["Troop"] = _G.TowersContained[v].Instance
                })
                task.wait()
            until SoldCheck or not _G.TowersContained[v].Instance:FindFirstChild("HumanoidRootPart")
            local TowerType = GetTypeIndex(tableinfo["TypeIndex"],v)
            SetActionInfo("Sell")
            ConsoleInfo((not SoldCheck and "Already " or "").."Sold Tower Index: "..v..", Type: \""..TowerType.."\", (Wave "..Wave..", Min: "..Min..", Sec: "..Sec..", InBetween: "..tostring(InWave)..")")
        end
        CompatRelease()
    end)
end
