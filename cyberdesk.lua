--// services
local WS = game:GetService("Workspace")
local PL = game:GetService("Players")
local PF = game:GetService("Players")
--// get player
local plr = PL.LocalPlayer
local Pmodel = workspace:FindFirstChild(plr.Name)
--// data
local Inlobby = true
local CandyRain = false
local targett = nil
local range = 50
local warns = 0

local function CreatePlayerPath(target)
  local path = PF:CreatePath({AgentCanJump = true, AgentCanClimb = true})
  local succes, error = pcall(function()
    path:ComputeAsync(Pmodel.HumanoidRootPart.Position, target.Character.HumanoidRootPart.Position)
  end)

  if not succes then
    return nil
  end

  return path
end

local function GetClosestPlayer()
  local magnitudes = {}
  local target = nil
  for i,player in pairs(PL:GetChildren()) do
    local dist = player:DistanceFromCharacter(Pmodel.HumanoidRootPart.Position) 

    if dist <= range then
      table.insert(magnitudes, {dist, player})
    end
  end
  table.sort(magnitudes, function(a,b)
    return a[1] < b[1]
  end)
  if #magnitudes > 0 then
    target = magnitudes[1][2]
  end
  return target
end

while task.wait(0.15) do
  if Pmodel.Humanoid.Health <= 0 then return end
  if Inlobby == true then
    Pmodel.Humanoid:MoveTo(WS.Portals:FindFirstChild("Arena Frame").Portal.Position)
    task.wait(0.5)
    Inlobby = false
  end
  if CandyRain == false then if WS:FindFirstChild("Candy Corn") then CandyRain = true end end
  if CandyRain == true then if not WS:FindFirstChild("Candy Corn") then CandyRain = false end
    for _,Obj in pairs(WS:GetChildren()) do
      if Obj.Name == "Candy Corn" then
        Pmodel.Humanoid:MoveTo(Obj.CFrame)
        Pmodel.Humanoid.MoveToFinished:Wait()
      end
    end
  end
  if CandyRain == false and targett == nil then 
    local p = GetClosestPlayer() 
    if PL:FindFirstChild(p.Name) then
      targett = p
    end
  end
  if CandyRain == false and targett ~= nil then
    if WS:FindFirstChild(targett).Humanoid.Health <= 0 or not WS:FindFirstChild(targett) then targett = "" return end
    path = CreatePlayerPath(targett)
    warns = 0
    if path and warns < 250 then
      waypoints = path:GetWaypoints()
      for i, waypoint in pairs(waypoints) do
        Pmodel.Humanoid:MoveTo(waypoint.Position)
        if waypoint.Action == Enum.PathWaypointAction.Jump then
          Pmodel.Humanoid.Jump = true
        end
        local hitbox = workspace:GetPartBoundsInBox(Pmodel.HumanoidRootPart.CFrame, Vector3.new(7.5,7.5,7.5))
        local istarget = false
        for i,v in pairs(hitbox) do
          if v.Parent.Name == targett.Name then
            istarget = true
            warns = -25
            
            local args = {
              [1] = 2587827953509,
              [2] = workspace:FindFirstChild(targett.Name),
              [3] = Vector3.new(-58,17,-43),
              [4] = 1.0390,
              [5] = PL:FindFirstChild(targett.Name).Character:FindFirstChild("Left Arm"),
              [6] = Vector3.new(0.44,-1.48,-0.9)
            }
            RST:FindFirstChild("Remote Events"):FindFirstChild("Punch"):FireServer(unpack(args))
            task.wait(0.05)
          end
        end
        if istarget == false then
          warns += 1
        end
      end
    elseif path and warns > 250 then
      targett = nil
      warns = 0
    end
  end
end

Pmodel.Humanoid.Died:Connect(function()
  Inlobby = true
end)
