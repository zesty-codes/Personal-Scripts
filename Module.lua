local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local Backpack = LocalPlayer:WaitForChild("Backpack")
local Skywars = {}
Skywars.__index = Skywars

function getMap()
    for i, v in next, workspace:GetChildren() do
        if v:FindFirstChild("Map") and v.Map:FindFirstChild("Ores") then
            return v.Map
        end
    end
end

function getOres()
    local map = getMap()

    if map then
        return map.Ores:GetChildren()
    end

    return {}
end

function Break(self, Block)
    if not self then return nil end
    if typeof(Block) == "Instance" then
        local Axe = Backpack:FindFirstChild("Axe") or localPlayer.Character and localPlayer.Character:FindFirstChild("Axe") or nil
        if Axe ~= nil then
            local Remote = Axe:FindFirstChild("RemoteEvent")
            if Remote ~= nil and (localPlayer.Character.HumanoidRootPart.Position - Block.Position).Magnitude < 15 then
                Remote:FireServer(Block)
                if not Block or not Block:GetFullName():find("Workspace") then
                    self.Events.Broke:Fire(Block)
                end
            end
        end
    end
end

function isPlayerInMatch(model)
    if model:GetPivot().Y > 125 then
        return false
    else
        return true
    end
end

function getAllPlayersInMatch()
    local plrs = {}
    
    for i, v in next, Players:GetPlayers() do
        if v ~= LocalPlayer and v.Character ~= nil and isPlayerInMatch(v.Character) then
            table.insert(plrs, v)
        end
    end

    return plrs
end

function Skywars.new()
    local self = {}
    local ended = false

    self.Events = {
        -- Match
        Start = Instance.new("BindableEvent", nil), -- Match start
        Ended = Instance.new("BindableEvent", nil), -- Match end
        -- Character
        Died = Instance.new("BindableEvent", nil), -- LocalPlayer died
        Respawned = Instance.new("BindableEvent", nil), -- LocalPlayer respawned
        -- Game controllers 
        Broke = Instance.new("BindableEvent", nil) -- Block was broken using self:Break(<BasePart> block)
    }

    self.lastDied = 0

    function self:Break(block)
        return Break(self, block)
    end;

    (localPlayer.Character or localPlayer.CharacterAdded:Wait()):WaitForChild("Humanoid").Died:Connect(function()
        self.Events.Died:Fire()
        self.lastDied = tick()
    end)

    LocalPlayer.CharacterAdded:Connect(function(v)
        self.Events.Respawned:Fire(v);
        (v:FindFirstChildOfClass("Humanoid") or v:WaitForChild("Humanoid")).Died:Connect(function()
            self.Events.Died:Fire()
            self.lastDied = tick()
        end)

        v:WaitForChild("HumanoidRootPart", 9e9):GetPropertyChangedSignal("CFrame"):Connect(function()
            if v.HumanoidRootPart.Position.Y < 140 and (tick() - self.lastDied) > 15 then
                self.Events.Start:Fire()
                ended = false
            end
        end)
    end)

    for i, v in next, game.Players:GetPlayers() do
        if isPlayerInMatch(v.Character) then
            v.Character:WaitForChild("Humanoid").Died:Connect(function()
                if ended then return nil end
                if #getAllPlayersInMatch() < 0 then
                    ended = true
                    self.Events.Ended:Fire()
                end
            end)
        end
    end

    return setmetatable(self, Skywars)
end

function Skywars:getMineableOres()
    local blocks = {}

    if isPlayerInMatch(localPlayer) and getMap() ~= nil then
        blocks = getOres()
    end

    return blocks
end

return Skywars
