--// services
local WS = game:GetService("Workspace")
local PL = game:GetService("Players")
--// get player
local plr = PL.LocalPlayer
local Pmodel = workspace:FindFirstChild(plr.Name)
--// data
local Inlobby = true
local CandyRain = false

while task.wait(0.1) do
  if Pmodel.Humanoid.Health <= 0 then return end
  if Inlobby == true then
    Pmodel.Humanoid:MoveTo(WS.Portals:FindFirstChild("Arena Frame").Portal.CFrame)
    Pmodel.Humanoid.MoveToFinished:Wait()
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
end

Pmodel.Humanoid.Died:Connect(function()
  Inlobby = true
end)
