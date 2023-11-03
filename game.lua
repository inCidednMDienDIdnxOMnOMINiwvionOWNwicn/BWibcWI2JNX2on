--[[
    MainFile For SaladClient 0.1 

    Credits:
    Vape - Paths, some functions and noclickdelay;
    DevForum - Cape Animation

    ALL THE PARTS OF CODE THAT ARENT MINE WILL BE REWROTE ENTIRELY IN THE NEWER VERSIONS
]]


local library = loadstring(readfile("SC 0.1/library.lua"))()
library:SetToggleBind(Enum.KeyCode.F)

do 
local CombatTab = library:CreateTab("Combat Tab", 1, "rbxassetid://7485051715")
local BlatantTab = library:CreateTab("Blatant Tab", 2, "rbxassetid://10653372143")
local RenderTab = library:CreateTab("Render Tab", 3, "rbxassetid://2790679413")
local UtilityTab = library:CreateTab("Utility Tab", 4, "rbxassetid://2790176032")
local WorldTab = library:CreateTab("World Tab", 5, "rbxassetid://10507357657")

 function damnService(s) 
    return game:GetService(s) 
end

local P = damnService("Players")
local lplr = game.Players.LocalPlayer --me when i localplayer 2 times (yup i didnt even notice LMAO, anyways imma just keep 2, too lazy to replace every LP or lplr, cry about it)
local RS = damnService("ReplicatedStorage")
local WS = damnService("Workspace")
local LP = P.LocalPlayer
local kC = debug.getupvalue(require(LP.PlayerScripts.TS.knit).setup, 6) --vape path
local BlockBreaker = kC.Controllers.BlockBreakController.blockBreaker
local SCont = kC.Controllers.SprintController
local kbthing = debug.getupvalue(require(RS.TS.damage["knockback-util"]).KnockbackUtil.calculateKnockbackVelocity, 1)
local Client = require(RS.TS.remotes).default.Client
local CombatController = kC.Controllers.CombatController
local SwordController = kC.Controllers.SwordController
local BedwarsSwords = require(RS.TS.games.bedwars["bedwars-swords"]).BedwarsMelees
local CCs = require(game:GetService("ReplicatedStorage").TS.combat["combat-constant"]).CombatConstant --vape path
local Camera = game:GetService("Workspace").CurrentCamera
local QU = require(RS['rbxts_include']['node_modules']['@easy-games']['game-core'].out).GameQueryUtil --vape path  

local rangezomg = 21

local function GetInventory(plr)
    if not plr then 
        return {items = {}, armor = {}}
    end
 
    local suc, ret = pcall(function() 
        return require(game:GetService("ReplicatedStorage").TS.inventory["inventory-util"]).InventoryUtil.getInventory(plr)
    end)
 
    if not suc then 
        return {items = {}, armor = {}}
    end
    if plr.Character and plr.Character:FindFirstChild("InventoryFolder") then 
        local invFolder = plr.Character:FindFirstChild("InventoryFolder").Value
        if not invFolder then return ret end
        for i,v in next, ret do 
            for i2, v2 in next, v do 
                if typeof(v2) == 'table' and v2.itemType then
                    v2.instance = invFolder:FindFirstChild(v2.itemType)
                end
            end
            if typeof(v) == 'table' and v.itemType then
                v.instance = invFolder:FindFirstChild(v.itemType)
            end
        end
    end
 
    return ret
 end
 local function getSword()
    local highest, returning = -9e9, nil
    for i,v in next, GetInventory(LP).items do 
        local swords = table.find(BedwarsSwords, v.itemType)
        if not swords then continue end
        if swords > highest then 
            returning = v
            highest = swords
        end
    end
    return returning
 end
 local function getItemNear(itemName)
     for slot, item in next, GetInventory(LP).items do
         if item.itemType == itemName or item.itemType:find(itemName) then
             return item, slot
         end
     end
     return nil
 end
 local function switchItem(tool)
     if LP.Character.HandInvItem.Value ~= tool then
         game:GetService("ReplicatedStorage").rbxts_include.node_modules:FindFirstChild("@rbxts").net.out._NetManaged.SetInvItem:InvokeServer({
             hand = tool
         })
     end
 end

function IsAlive(lplr) --isalive guys!1
    lplr = LP
        if not lplr.Character then return false end        
        if not lplr.Character:FindFirstChild("Head") then return false end
        if not lplr.Character:FindFirstChild("Humanoid") then return false end
        if lplr.Character:FindFirstChild("Humanoid").Health < 0.11 then return false end
    return true
 end


 function alive(p) --omg hrp health check!1!11!1!1
    return p and p.Character and p.Character:FindFirstChild("Head") and p.Character:FindFirstChild("Humanoid") and p.Character:FindFirstChild("Humanoid").Health >= 0.11
end


 function hrpfind(char) --best hrp check ong ong
    return char and char:FindFirstChild("HumanoidRootPart")
end


--combat tab 
local Velocity = CombatTab:CreateToggle(
    "Velocity",
    function(callback) 
        if callback then 
            kbthing["kbDirectionStrength"] = 0
            kbthing["kbUpwardStrength"] = 0
        else
            kbthing["kbDirectionStrength"] = 100
            kbthing["kbUpwardStrength"] = 100
        end
    end
)


--creds vape for the noclickdelay toggle
local isclickingtoofast = SwordController.isClickingTooFast
local noclickfunc = SwordController.isClickingTooFast
local NoClickDelay = CombatTab:CreateToggle(
    "NoClickDelay", 
    function(callback)
        if callback then 
            notification("NoClickDelay", "This is Vape noclickdelay, all credits to xylex", 2)
            SwordController.isClickingTooFast = function(self) 
                self.lastSwing = tick()
                return false 
            end
        else 
            SwordController.isClickingTooFast = noclickfunc
        end
    end
)



-- added debugs because it didnt work and found out the coroutine was the problem, so i replaced it lel
--nullified debugs because it cant fucking exit the loop and im lazy so i leave it like dat
local rs = game:GetService("ReplicatedStorage")
--print(rs)
local Client = require(rs.TS.remotes).default.Client
--print(Client)
local nofallfr = false
local fuckuploop = nil
--warn("Initial NoFallState is:")
--print(nofallfr)

CombatTab:CreateToggle(
    "NoFall",
    function(callback) 
        --print("Toggle changed trololol:", callback)
		if callback then 
            nofallfr = true 
           -- warn("NoFallState after toggle is fakin on:")
           -- print(nofallfr)

            if fuckuploop then
              --  print("Trying to kill da loop")
                fuckuploop:Cancel()
            end

			fuckuploop = task.spawn(function()
              --  print("coroutine entered omg") --[fuck you]
				repeat 
					wait()
                  --  print("Loop check holy fak nofallfr is", nofallfr)
                   -- print("Sending ground hit")
					Client:Get("GroundHit"):SendToServer()
                   -- print("GroundHit Sent")
                until not nofallfr
              --  warn("Loop exited")
               -- print(nofallfr)
			end)
        else
            nofallfr = false
           -- warn("NoFallState after toggle is off holy am tired:")
           -- print(nofallfr)
        end
    end
)


local state = { shouldSprint = false }

CombatTab:CreateToggle(
    "Sprint",
    function(callback) 
        state.shouldSprint = callback

        if state.shouldSprint then 
            coroutine.wrap(function()
                while state.shouldSprint do
                    local character = game.Players.LocalPlayer.Character
                    while not character do
                        wait(0.5)
                        character = game.Players.LocalPlayer.Character
                    end
                    local humanoid = character:FindFirstChildOfClass("Humanoid")
                    while not humanoid do
                        wait(0.5)
                        humanoid = character:FindFirstChildOfClass("Humanoid")
                    end
                    if humanoid.Health > 0 then
                        SCont:startSprinting()
                    else
                        SCont:stopSprinting()
                    end
                    wait()
                end
                SCont:stopSprinting()
            end)()
        else
            SCont:stopSprinting()
        end
    end
)


--done

--blatant tab
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local highrangeongangmathhugemoment = math.huge
local SWORD_CHARACTER_DISTANCE = 14.4

--isnpc works just fine but the faking hit doesnt :sob:
local function isNPC(instance)
if instance then
    if instance:IsA("Model") and instance:FindFirstChild("RootPart") and (instance.Name == "DiamondGuardian" or instance.Name == "GolemBoss") then
        return true
    else 
        print("no insyance")
    end
    return false
end
end

local function getEntityRootPart(entity)
    if entity:IsA("Player") then
        return hrpfind(entity.Character)
    elseif isNPC(entity) then
        return entity:FindFirstChild("RootPart")
    end
end


local function findClosestPlayerOrNPC(range)
    local closestEntity = nil
    local shortestDistance = range or highrangeongangmathhugemoment
    local localHrp = getEntityRootPart(LP)

    for _, player in ipairs(P:GetPlayers()) do
        if player ~= LP and alive(player) then
            local targetHrp = getEntityRootPart(player)

            if targetHrp and localHrp then
                local distance = (targetHrp.Position - localHrp.Position).Magnitude
                if distance <= shortestDistance then
                    shortestDistance = distance
                    closestEntity = player
                end
            end
        end
    end

    for _, npc in ipairs(workspace:GetChildren()) do
        if isNPC(npc) then
            local targetHrp = getEntityRootPart(npc)

            if targetHrp and localHrp then
                local distance = (targetHrp.Position - localHrp.Position).Magnitude
                if distance <= shortestDistance then
                    shortestDistance = distance
                    closestEntity = npc
                end
            end
        end
    end

    return closestEntity
end

local anims = {
    ["saladclient"] = {
        {CFrame = CFrame.new(0.68, -0.7, 0.61) * CFrame.Angles(math.rad(-20), math.rad(45), math.rad(-85)), Time = 0.15},
        {CFrame = CFrame.new(0.695, -0.705, 0.595) * CFrame.Angles(math.rad(-60), math.rad(48), math.rad(-65)), Time = 0.3},
        {CFrame = CFrame.new(0.72, -0.72, 0.58) * CFrame.Angles(math.rad(-90), math.rad(52), math.rad(-40)), Time = 0.45},
        {CFrame = CFrame.new(0.150, -0.8, 0.1) * CFrame.Angles(math.rad(-45), math.rad(40), math.rad(-75)), Time = 0.6},
        {CFrame = CFrame.new(0.02, -0.8, 0.05) * CFrame.Angles(math.rad(-60), math.rad(60), math.rad(-95)), Time = 0.75}
    }
}

local origC0 = ReplicatedStorage.Assets.Viewmodel.RightHand.RightWrist.C0
local animationInProgress = false

local function playAnimationLoop()
    if animationInProgress then  
        return
    end
    animationInProgress = true

    while isKillAuraActive do
        if targetPlayer and not animating then
            local targetHrp = getEntityRootPart(targetPlayer)
            local selfHrp = getEntityRootPart(LP)            
            if not targetHrp or not selfHrp then 
                animationInProgress = false
                return 
            end
            
            local distance = (targetHrp.Position - selfHrp.Position).Magnitude
            if distance <= rangezomg then 
                animating = true
                for _, anim in pairs(anims["saladclient"]) do
                    local tweenInfo = TweenInfo.new(anim.Time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
                    local tween = TweenService:Create(Camera.Viewmodel.RightHand.RightWrist, tweenInfo, {C0 = origC0 * anim.CFrame})
                    local tweenFinished = false
                    tween.Completed:Connect(function() tweenFinished = true end)
                    tween:Play()
                    repeat wait() until tweenFinished
                end
                animating = false
            else
                TweenService:Create(Camera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {C0 = origC0}):Play()
                wait(0.1)  
            end
        else
            TweenService:Create(Camera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {C0 = origC0}):Play()
            wait(0.1)
        end
        wait(0.5)  
    end

    animationInProgress = false
end


local function killAuraLogic()
    targetPlayer = findClosestPlayerOrNPC(rangezomg)

    
    if targetPlayer then 
    print("Attempting to hit entity: " .. targetPlayer.Name)
    else 
        print("entity not found xd")
    end

    if isNPC(targetPlayer) then
        print(targetPlayer.Name .. " is an NPC.")
    elseif not targetPlayer then 
        print("no target found")
    else 
        print(targetPlayer.Name .. " is a Player.")
    end
    

    if targetPlayer then
        local targetHrp = getEntityRootPart(targetPlayer)
        local selfHrp = getEntityRootPart(LP)
        local sword = getSword()

        debug.setconstant(SwordController.swingSwordAtMouse, 23, 'raycast')
        debug.setupvalue(SwordController.swingSwordAtMouse, 4, QU)

        if not sword or not targetHrp or not selfHrp then
            print("Failed conditions for sword, targetHrp, or selfHrp.")
            return
        end
        

        if not animCoroutine then 
            animCoroutine = coroutine.wrap(playAnimationLoop)
            animCoroutine()
        end

        switchItem(sword.tool)
        local maaag = (targetHrp.Position - selfHrp.Position).Magnitude 
        local adjustedSelfPosition = maaag > 14.4 and (selfHrp.Position + (CFrame.lookAt(selfHrp.Position, targetHrp.Position).LookVector * 4)) or selfHrp.Position

        local args = {
            [1] = {
                ["chargedAttack"] = {["chargeRatio"] = 0},
                ["entityInstance"] = isNPC(targetPlayer) and targetPlayer or targetPlayer.Character,
                ["validate"] = {
                    ["selfPosition"] = {["value"] = adjustedSelfPosition},
                    ["targetPosition"] = {["value"] = targetHrp.Position + Vector3.new(0, 2, 0)},
                },
                ["weapon"] = sword.tool
            }
        }

        
        print("Arguments for SwordHit: ")
        print("Entity Instance: ", args[1]["entityInstance"])
        print("Self Position: ", args[1]["validate"]["selfPosition"]["value"])
        print("Target Position: ", args[1]["validate"]["targetPosition"]["value"])
        print("Weapon: ", args[1]["weapon"])

        print("Firing SwordHit event for entity: " .. (targetPlayer.Name or "Unknown Entity"))
        
        RS.rbxts_include.node_modules["@rbxts"].net.out._NetManaged.SwordHit:FireServer(unpack(args))
        print("SwordHit event fired")
    else
        TweenService:Create(Camera.Viewmodel.RightHand.RightWrist, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {C0 = origC0}):Play()
        animCoroutine = nil 
    end
end


BlatantTab:CreateToggle("Killaura", function(callback)
    if callback then
        isKillAuraActive = true
        CCs.RAYCAST_SWORD_CHARACTER_DISTANCE = rangezomg  --wont do shit lmaoooo
        
        animCoroutine = coroutine.wrap(playAnimationLoop)
        animCoroutine()
        
        local killauraConnection
        killauraConnection = RunService.RenderStepped:Connect(function(deltaTime)
            if isKillAuraActive then
                killAuraLogic()
            else
                if killauraConnection then
                    killauraConnection:Disconnect()
                end
            end
        end)

    else
        isKillAuraActive = false
        CCs.RAYCAST_SWORD_CHARACTER_DISTANCE = SWORD_CHARACTER_DISTANCE
    end
end)
--lazy code
BlatantTab:CreateToggle("Fly", function(callback)
    local hrp = lplr.Character.HumanoidRootPart
    local Force = hrp:FindFirstChild("Force")
    local uis = game:GetService("UserInputService")

    if callback then
        if not Force then
            Force = Instance.new("BodyVelocity")
            Force.Name = "Force"
            Force.Velocity = Vector3.new(0, 0, 0)
            Force.MaxForce = Vector3.new(0, 9e9, 0)
            Force.Parent = hrp
        end

            IBC = uis.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space then
                    Force.Velocity = Vector3.new(0, 50, 0)  
                elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
                    Force.Velocity = Vector3.new(0, -50, 0) 
                end
            end)
        
            IEC = uis.InputEnded:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
                    Force.Velocity = Vector3.new(0, 0, 0)
                end
            end)
    else
        if IBC then 
            IBC:Disconnect() 
            IBC = nil
        end
        
        if IEC then 
            IEC:Disconnect() 
            IEC = nil
        end

        if Force then 
            Force:Destroy() 
        end
    end
end)

local RunLoops = {RenderStepTable = {}, StepTable = {}, HeartTable = {}}
local RunService = game:GetService("RunService")
function RunLoops:BindToHeartbeat(name, func)
    if RunLoops.HeartTable[name] == nil then
        RunLoops.HeartTable[name] = RunService.Heartbeat:Connect(func)
    end
end
function RunLoops:UnbindFromHeartbeat(name)
    if RunLoops.HeartTable[name] then
        RunLoops.HeartTable[name]:Disconnect()
        RunLoops.HeartTable[name] = nil
    end
end
BlatantTab:CreateToggle("Speed", function(callback)
    if callback then
        RunLoops:BindToHeartbeat("Speed", function(delta)
            if IsAlive(LP) then
                local speedCFrame = LP.character.Humanoid.MoveDirection * 40 * delta
                LP.character.HumanoidRootPart.CFrame = LP.character.HumanoidRootPart.CFrame + speedCFrame
            end
        end)
    else
        RunLoops:UnbindFromHeartbeat("Speed")
    end
end)


--done 

--render tab
--my old target hud redesigned 
RenderTab:CreateToggle(
    "Target Hud",
    function(callback) 
        if callback then 
            local TweenService = game:GetService("TweenService")
            local function TweenObject(target, properties, time, easingStyle, direction, callback)
                local info = TweenInfo.new(time, easingStyle, direction)
                local tween = TweenService:Create(target, info, properties)
                tween:Play()
                
                if callback then
                    tween.Completed:Connect(callback)
                end
            end
            
            local previousTargetHP = 0  
            
            local Table = {
                ["_MainGui"] = Instance.new("ScreenGui");
                ["_MainFrame"] = Instance.new("Frame");
                ["_UIStroke"] = Instance.new("UIStroke");
                ["_UIGradient"] = Instance.new("UIGradient");
                ["_LocalScript"] = Instance.new("LocalScript");
                ["_UICorner"] = Instance.new("UICorner");
                ["_DropShadowHolder"] = Instance.new("Frame");
                ["_DropShadow"] = Instance.new("ImageLabel");
                ["_ImageLabel"] = Instance.new("ImageLabel");
                ["_Corner"] = Instance.new("UICorner");
                ["_Stroke"] = Instance.new("UIStroke");
                ["_HealthFrame"] = Instance.new("Frame");
                ["_UICorner1"] = Instance.new("UICorner");
                ["_HP"] = Instance.new("TextLabel");
                ["_User"] = Instance.new("TextLabel");
                ["_Win/Lose"] = Instance.new("TextLabel");
            }
            
            Table["_MainGui"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            Table["_MainGui"].Name = "MainGui"
            Table["_MainGui"].Parent = game:GetService("CoreGui")
			Table["_MainGui"].Enabled = false
            
            Table["_MainFrame"].BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Table["_MainFrame"].BackgroundTransparency = 0.8
            Table["_MainFrame"].BorderColor3 = Color3.fromRGB(0, 0, 0)
            Table["_MainFrame"].BorderSizePixel = 0
            Table["_MainFrame"].Position = UDim2.new(0.476450503, 0, 0.631067932, 0)
            Table["_MainFrame"].Size = UDim2.new(0, 0, 0, 0) 
            Table["_MainFrame"].Name = "MainFrame"
            Table["_MainFrame"].Parent = Table["_MainGui"]
            
            Table["_UIStroke"].Color = Color3.fromRGB(255, 255, 255)
            Table["_UIStroke"].Thickness = 1
            Table["_UIStroke"].Parent = Table["_MainFrame"]
            
            Table["_UIGradient"].Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, Color3.fromRGB(230,230,250)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(153,50,204))
            }
            Table["_UIGradient"].Parent = Table["_UIStroke"]
            
            Table["_UICorner"].Parent = Table["_MainFrame"]
            
            Table["_DropShadowHolder"].BackgroundTransparency = 1
            Table["_DropShadowHolder"].BorderSizePixel = 0
            Table["_DropShadowHolder"].Size = UDim2.new(1, 0, 1, 0)
            Table["_DropShadowHolder"].ZIndex = 0
            Table["_DropShadowHolder"].Name = "DropShadowHolder"
            Table["_DropShadowHolder"].Parent = Table["_MainFrame"]
            
            Table["_DropShadow"].Image = "rbxassetid://6014261993"
            Table["_DropShadow"].ImageColor3 = Color3.fromRGB(0, 0, 0)
            Table["_DropShadow"].ImageTransparency = 0.5
            Table["_DropShadow"].ScaleType = Enum.ScaleType.Slice
            Table["_DropShadow"].SliceCenter = Rect.new(49, 49, 450, 450)
            Table["_DropShadow"].AnchorPoint = Vector2.new(0.5, 0.5)
            Table["_DropShadow"].BackgroundTransparency = 1
            Table["_DropShadow"].BorderSizePixel = 0
            Table["_DropShadow"].Position = UDim2.new(0.5, 0, 0.5, 0)
            Table["_DropShadow"].Size = UDim2.new(1, 47, 1, 47)
            Table["_DropShadow"].ZIndex = 0
            Table["_DropShadow"].Name = "DropShadow"
            Table["_DropShadow"].Parent = Table["_DropShadowHolder"]
            
            Table["_ImageLabel"].Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            Table["_ImageLabel"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Table["_ImageLabel"].BackgroundTransparency = 1
            Table["_ImageLabel"].BorderColor3 = Color3.fromRGB(0, 0, 0)
            Table["_ImageLabel"].BorderSizePixel = 0
            Table["_ImageLabel"].Position = UDim2.new(0.0361842103, 0, 0.119999997, 0)
            Table["_ImageLabel"].Size = UDim2.new(0, 80, 0, 75)
            Table["_ImageLabel"].Parent = Table["_MainFrame"]
            
            Table["_Corner"].Name = "Corner"
            Table["_Corner"].Parent = Table["_ImageLabel"]
            
            Table["_Stroke"].Color = Color3.fromRGB(153,50,204)
            Table["_Stroke"].Thickness = 1
            Table["_Stroke"].Name = "Stroke"
            Table["_Stroke"].Parent = Table["_ImageLabel"]
            
            Table["_HealthFrame"].BackgroundColor3 = Color3.fromRGB(0, 157.0000058412552, 58.00000414252281)
            Table["_HealthFrame"].BorderColor3 = Color3.fromRGB(0, 0, 0)
            Table["_HealthFrame"].BorderSizePixel = 0
            Table["_HealthFrame"].Position = UDim2.new(0.335526317, 0, 0.699999988, 0)
            Table["_HealthFrame"].Size = UDim2.new(0, 187, 0, 17)
            Table["_HealthFrame"].Name = "HealthFrame"
            Table["_HealthFrame"].Parent = Table["_MainFrame"]
            
            Table["_UICorner1"].CornerRadius = UDim.new(0, 4)
            Table["_UICorner1"].Parent = Table["_HealthFrame"]
            
            Table["_HP"].Font = Enum.Font.SourceSans
            Table["_HP"].Text = "100 HP"
            Table["_HP"].TextColor3 = Color3.fromRGB(216,191,216)
            Table["_HP"].TextScaled = true
            Table["_HP"].TextSize = 14
            Table["_HP"].TextWrapped = true
            Table["_HP"].TextXAlignment = Enum.TextXAlignment.Left
            Table["_HP"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Table["_HP"].BackgroundTransparency = 1
            Table["_HP"].BorderColor3 = Color3.fromRGB(0, 0, 0)
            Table["_HP"].BorderSizePixel = 0
            Table["_HP"].Position = UDim2.new(0.335526317, 0, 0.379999995, 0)
            Table["_HP"].Size = UDim2.new(0, 84, 0, 24)
            Table["_HP"].Name = "HP"
            Table["_HP"].Parent = Table["_MainFrame"]
            
            Table["_User"].Font = Enum.Font.SourceSans
            Table["_User"].Text = "UserName"
            Table["_User"].TextColor3 = Color3.fromRGB(216,191,216)
            Table["_User"].TextScaled = true
            Table["_User"].TextSize = 14
            Table["_User"].TextWrapped = true
            Table["_User"].TextXAlignment = Enum.TextXAlignment.Left
            Table["_User"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Table["_User"].BackgroundTransparency = 1
            Table["_User"].BorderColor3 = Color3.fromRGB(0, 0, 0)
            Table["_User"].BorderSizePixel = 0
            Table["_User"].Position = UDim2.new(0.335526317, 0, 0.119999997, 0)
            Table["_User"].Size = UDim2.new(0, 195, 0, 24)
            Table["_User"].Name = "User"
            Table["_User"].Parent = Table["_MainFrame"]
            
            Table["_Win/Lose"].Font = Enum.Font.SourceSans
            Table["_Win/Lose"].Text = "Winning"
            Table["_Win/Lose"].TextColor3 = Color3.fromRGB(255, 255, 255)
            Table["_Win/Lose"].TextScaled = true
            Table["_Win/Lose"].TextSize = 14
            Table["_Win/Lose"].TextWrapped = true
            Table["_Win/Lose"].TextXAlignment = Enum.TextXAlignment.Left
            Table["_Win/Lose"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Table["_Win/Lose"].BackgroundTransparency = 1
            Table["_Win/Lose"].BorderColor3 = Color3.fromRGB(0, 0, 0)
            Table["_Win/Lose"].BorderSizePixel = 0
            Table["_Win/Lose"].Position = UDim2.new(0.611842096, 0, 0.360000014, 0)
            Table["_Win/Lose"].Size = UDim2.new(0, 103, 0, 26)
            Table["_Win/Lose"].Name = "Win/Lose"
            Table["_Win/Lose"].Parent = Table["_MainFrame"]
            
            local fake_module_scripts = {}
            
            local function MYASSISA_fake_script() 
            local script = Instance.new("LocalScript")
            script.Name = "LocalScript"
            script.Parent = Table["_UIStroke"]
            local req = require
            local require = function(obj)
                local fake = fake_module_scripts[obj]
                if fake then
                    return fake()
                end
                return req(obj)
            end
            
            local r = game:GetService("RunService")
            local g = script.Parent.UIGradient
            
            r.RenderStepped:Connect(function()
                g.Rotation += 2
            end)
            end
            
            coroutine.wrap(MYASSISA_fake_script)()
            local lplr = game.Players.LocalPlayer
            local character = lplr.Character or lplr.CharacterAdded:Wait()
            local rootPart = character:WaitForChild("HumanoidRootPart")
            local target = nil
            
            
            local function updateGUI(target)
            if not target or not target.Character or not target.Character:FindFirstChild("Humanoid") or not character or not character:FindFirstChild("Humanoid") then
                return
            end
            local healthChangeConnection


            local function updateTargetHealth()
                if target and target.Character and target.Character:FindFirstChild("Humanoid") then
                    updateGUI(target)
                end
            end

            
            Table["_User"].Text = target.Name
            local userId = target.UserId
            Table["_ImageLabel"].Image = "rbxthumb://type=AvatarHeadShot&w=420&h=420&id=" .. userId
            
            local lplrHP = character.Humanoid.Health
            local targetHP = target.Character.Humanoid.Health
            local targetMaxHP = target.Character.Humanoid.MaxHealth
            local targetHPPercentage = targetHP / targetMaxHP
            Table["_HP"].Text = tostring(math.floor(targetHP)) .. " HP"
            
            local targetHPPercentageChange = targetHPPercentage - (previousTargetHP / targetMaxHP)
            local tweenTime = math.abs(targetHPPercentageChange) * 1.5
            tweenTime = math.max(tweenTime, 0.2)  
            
            TweenObject(Table["_HealthFrame"], {Size = UDim2.new(0, 187 * targetHPPercentage, 0, 17)}, tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
            
            
            if targetHP < 20 then
                Table["_HealthFrame"].BackgroundColor3 = Color3.fromRGB(238,130,238) 
            elseif targetHP < 50 then
                Table["_HealthFrame"].BackgroundColor3 = Color3.fromRGB(153,50,204)
            else
                Table["_HealthFrame"].BackgroundColor3 = Color3.fromRGB(75,0,130) 
            end
            
            if lplrHP > targetHP then
                Table["_Win/Lose"].Text = "Winning"
                Table["_Win/Lose"].TextColor3 = Color3.fromRGB(255,0,255)
            elseif lplrHP == targetHP then
                Table["_Win/Lose"].Text = "Same HPS"
                Table["_Win/Lose"].TextColor3 = Color3.fromRGB(216,191,216)
            else
                Table["_Win/Lose"].Text = "Losing"
                Table["_Win/Lose"].TextColor3 = Color3.fromRGB(153,50,204)
            end
            previousTargetHP = targetHP
            end
            
            
            
            local function updateCharacterReferences()
            character = lplr.Character or lplr.CharacterAdded:Wait()
            rootPart = character:WaitForChild("HumanoidRootPart")
            Table["_MainGui"].Enabled = false  
            end
            
            local debounce = false
            local function checkPlayersWithinReach()
            if debounce then return end
            debounce = true
            
            local nearestPlayer = nil
            local shortestDistance = 18 
			local isAnimating = false
			local lastCheckTime = 0
            local cooldowncheck = 2  

            function showHUD()
                if isAnimating or isVisible then return end
                isAnimating = true
                target = nearestPlayer
                updateGUI(nearestPlayer)
                Table["_MainGui"].Enabled = true
                Table["_MainFrame"].Size = UDim2.new(0, 0, 0, 0)
            
                TweenObject(Table["_MainFrame"], {Size = UDim2.new(0, 304, 0, 100)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, function()
                    isAnimating = false
                end)
                isVisible = true
            end
            
			
            function hideHUD()
                if isAnimating or not isVisible then return end
                isAnimating = true
                target = nil
            
            
                TweenObject(Table["_MainFrame"], {Size = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In, function()
                    Table["_MainGui"].Enabled = false
                    isAnimating = false
                end)
                isVisible = false
            end
                

            
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= lplr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local distance = (rootPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
                    if distance < shortestDistance then
                        shortestDistance = distance
                        nearestPlayer = player
                    end
                end
            end

			local currentTime = tick()
			if currentTime - lastCheckTime < cooldowncheck then return end
			
            if nearestPlayer then
                if healthChangeConnection then
                    healthChangeConnection:Disconnect()
                end

                if nearestPlayer.Character and nearestPlayer.Character:FindFirstChild("Humanoid") then
                    healthChangeConnection = nearestPlayer.Character.Humanoid:GetPropertyChangedSignal("Health"):Connect(function()
                        updateGUI(nearestPlayer) 
                    end)
                end
                showHUD()
            else 
                if healthChangeConnection then
                    healthChangeConnection:Disconnect()
                    healthChangeConnection = nil
                end
                hideHUD()
            end
            
			
			lastCheckTime = currentTime			
				
			
            debounce = false
            end
            
            local heartbeatConnection
            
            local function startCheckingPlayers()
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
            end
            heartbeatConnection = game:GetService("RunService").Heartbeat:Connect(checkPlayersWithinReach)
            end
            
            local function stopCheckingPlayers()
            if heartbeatConnection then
                heartbeatConnection:Disconnect()
                heartbeatConnection = nil
            end
            end
            
            game.Players.PlayerRemoving:Connect(function(removedPlayer)
            if removedPlayer == target then
                target = nil
                Table["_MainGui"].Enabled = false 
            end
            end)
            
            lplr.CharacterAdded:Connect(function()
            stopCheckingPlayers()
            character = lplr.Character
            rootPart = character:WaitForChild("HumanoidRootPart")
            startCheckingPlayers()
            end)
            
            startCheckingPlayers()            
        else
	        local MainGui = game:GetService("CoreGui"):FindFirstChild("MainGui")
	          if MainGui then 
		        MainGui:Destroy()
	        end	
        end
    end
)

--shitty nametags
local PlayersService = game:GetService("Players")
local CustomTagName = "CustomNametag"
local KeepRunning = false
local HeartbeatConnection = nil
local PlayerTeamTracker = {}
local NametagsEnabledFor = {}

local function removeTagFromPlayers()
    for player, _ in pairs(NametagsEnabledFor) do
        local char = player.Character
        if char and char:FindFirstChild("Head") then
            local tag = char.Head:FindFirstChild(CustomTagName)
            if tag then
                tag:Destroy()
            end
        end
    end
end


local function getColorForTeamPlayer(player)
    local team = player.Team
    if team then
        return team.TeamColor.Color
    end
    return Color3.new(1, 1, 1)
end

local function updateHealthLabel(label, health)
    label.Text = "HP: " .. math.floor(health)
    if health < 30 then
        label.TextColor3 = Color3.new(1, 0, 0)
    elseif health < 70 then
        label.TextColor3 = Color3.new(1, 0.5, 0)
    else
        label.TextColor3 = Color3.new(0, 0.8, 0)
    end
end

local function createNameTag(playerName, teamColor)
    local frame = Instance.new("Frame")
    local textLabel = Instance.new("TextLabel")
    local healthLabel = Instance.new("TextLabel")

    frame.Size = UDim2.new(0, 150, 0, 30)
    frame.BackgroundTransparency = 0.7
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    frame.Parent = game.CoreGui
    frame.Name = "NameTagFrame"

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0, 0.7, 1)),
        ColorSequenceKeypoint.new(1, Color3.new(0.5, 0.1, 0.5))
    })
    gradient.Parent = frame

    textLabel.Size = UDim2.new(0.6, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = playerName
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.TextSize = 16
    textLabel.TextColor3 = teamColor
    textLabel.TextStrokeTransparency = 0
    textLabel.TextScaled = true
    textLabel.Parent = frame

    healthLabel.Size = UDim2.new(0.3, 0, 1, 0)
    healthLabel.Position = UDim2.new(0.7, 0, 0, 0)
    healthLabel.BackgroundTransparency = 1
    healthLabel.Font = Enum.Font.SourceSansBold
    healthLabel.TextSize = 14
    healthLabel.TextStrokeTransparency = 0.5
    healthLabel.Parent = frame
    healthLabel.TextScaled = true

    return frame, healthLabel
end

local function attachNameTagToCharacter(character)
    local player = PlayersService:GetPlayerFromCharacter(character)
    local teamColor = getColorForTeamPlayer(player)

    local head = character:WaitForChild("Head", 10)
    if not head then return end

    local existingTag = head:FindFirstChild(CustomTagName)
    if existingTag then
        existingTag:Destroy()
    end

    local billboardGui = Instance.new("BillboardGui")
    billboardGui.Size = UDim2.new(0, 130, 0, 25)
    billboardGui.Adornee = head
    billboardGui.StudsOffset = Vector3.new(0, 2, 0)
    billboardGui.Name = CustomTagName
    billboardGui.Parent = head
    billboardGui.ResetOnSpawn = false
    billboardGui.AlwaysOnTop = true

    local nameTag, healthLabel = createNameTag(character.Name, teamColor)
    nameTag.Parent = billboardGui

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        updateHealthLabel(healthLabel, humanoid.Health)
        humanoid.HealthChanged:Connect(function(health)
            updateHealthLabel(healthLabel, health)
        end)
    else
        healthLabel.Text = "HP: N/A"
    end
end

local function updateNameTagColor(character, color)
    local billboardGui = character.Head:FindFirstChildOfClass("BillboardGui")
    if billboardGui then
        billboardGui:Destroy()
    end
    attachNameTagToCharacter(character)

    local nameTagFrame = character.Head:FindFirstChildOfClass("BillboardGui"):FindFirstChildOfClass("Frame")
    if nameTagFrame then
        local nameTextLabel = nameTagFrame:FindFirstChildOfClass("TextLabel")
        if nameTextLabel then
            nameTextLabel.TextColor3 = color
            nameTextLabel.Text = nameTextLabel.Text .. " "
            wait()
            nameTextLabel.Text = nameTextLabel.Text:sub(1, -2)
        end
    end
end

local function setupCharacterNameTag(character)
    local head = character:WaitForChild("Head", 10)
    local humanoid = character:WaitForChild("Humanoid", 10)

    if head and humanoid then
        local existingBillboard = head:FindFirstChild(CustomTagName)
        if existingBillboard then
            existingBillboard:Destroy()
        end
        attachNameTagToCharacter(character)
    end
end

local function checkNameTagConsistency(player)
    coroutine.wrap(function()
        while KeepRunning do
            if not player.Character or not player.Character:FindFirstChild("Head") or not player.Character.Head:FindFirstChild(CustomTagName) then
                if player.Character and player.Character:FindFirstChild("Head") then
                    attachNameTagToCharacter(player.Character)
                end
            end
            wait(0.1)
        end
    end)()
end

local function checkPlayerTeamChanges()
    coroutine.wrap(function()
        while KeepRunning do
            for _, player in ipairs(PlayersService:GetPlayers()) do
                if PlayerTeamTracker[player] ~= player.Team then
                    if player.Team and player.Character then
                        attachNameTagToCharacter(player.Character)
                    end
                    PlayerTeamTracker[player] = player.Team
                end
            end
            wait(0.1)
        end
    end)()
end

local function validateNameTag(character)
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if head and humanoid and not head:FindFirstChild(CustomTagName) then
        attachNameTagToCharacter(character)
    end
end

local function validateAllPlayerNameTags()
    coroutine.wrap(function()
        while KeepRunning do
            for _, player in pairs(PlayersService:GetPlayers()) do
                if player.Character then
                    validateNameTag(player.Character)
                end
            end
            wait(0.1)
        end
    end)()
end

local function desiredNameTagState(player)
    return KeepRunning and not NametagsEnabledFor[player]
end

local function updateNametagState()
    for _, player in pairs(PlayersService:GetPlayers()) do
        local hasNametag = player.Character and player.Character:FindFirstChild("Head") and player.Character.Head:FindFirstChild(CustomTagName)

        if KeepRunning and not hasNametag then
            setupCharacterNameTag(player.Character)
            NametagsEnabledFor[player] = true
        elseif not KeepRunning then
            removeTagFromPlayers()
            NametagsEnabledFor = {}
        end

        if KeepRunning and NametagsEnabledFor[player] and PlayerTeamTracker[player] ~= player.Team then
            attachNameTagToCharacter(player.Character)
            PlayerTeamTracker[player] = player.Team
        end
    end
end


PlayersService.PlayerAdded:Connect(function(player)
    if player.Character then
        setupCharacterNameTag(player.Character)
    end
    player.CharacterAdded:Connect(setupCharacterNameTag)
    checkNameTagConsistency(player)
end)

RenderTab:CreateToggle("NameTags", function(callback)
    KeepRunning = callback

    if KeepRunning then
        if not HeartbeatConnection then
            HeartbeatConnection = game:GetService("RunService").Heartbeat:Connect(updateNametagState)
        end
    else
        removeTagFromPlayers()
        if HeartbeatConnection then
            HeartbeatConnection:Disconnect()
            HeartbeatConnection = nil
        end
        NametagsEnabledFor = {}
    end
end)


RenderTab:CreateToggle("Ambience", function(callback) 
    if callback then 
        game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=218955819"
		game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=218953419"
		game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=218954524"
		game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=218958493"
		game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=218957134"
		game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=218950090"
		game.Lighting.FogColor = Color3.new(11, 0, 70)
		game.Lighting.FogEnd = "200"
		game.Lighting.FogStart = "0"
		game.Lighting.Ambient = Color3.new(0.5, 0, 1)
        atmos = Instance.new("ColorCorrectionEffect")
        atmos.Name = "FunnyAtmposphere"
        atmos.TintColor = Color3.fromRGB(38, 0, 255)
        atmos.Parent = game:GetService("Lighting")
    else
    	game.Lighting.Sky.SkyboxBk = "http://www.roblox.com/asset/?id=7018684000"
		game.Lighting.Sky.SkyboxDn = "http://www.roblox.com/asset/?id=6334928194"
		game.Lighting.Sky.SkyboxFt = "http://www.roblox.com/asset/?id=7018684000"
		game.Lighting.Sky.SkyboxLf = "http://www.roblox.com/asset/?id=7018684000"
		game.Lighting.Sky.SkyboxRt = "http://www.roblox.com/asset/?id=7018684000"
		game.Lighting.Sky.SkyboxUp = "http://www.roblox.com/asset/?id=7018689553"
		game.Lighting.FogColor = Color3.new(1, 1, 1)
		game.Lighting.FogEnd = "10000"
		game.Lighting.FogStart = "0"
		game.Lighting.Ambient = Color3.new(0, 0, 0)
        atmos = game:GetService("Lighting"):FindFirstChild("FunnyAtmposphere")
        if atmos then 
            atmos:Destroy()
        else
            warn("atmosphere not found")
        end 
    end
end)

local capeVisible = true 

RenderTab:CreateToggle("Cape", function(callback)
    local player = game.Players.LocalPlayer
    local playerModel = workspace:FindFirstChild(player.Name)
    local capethingmain = playerModel and playerModel:FindFirstChild("SaladClient Cape")

    if callback then
        notification("Cape", "The cape animation is NOT mine, credits to the owner", 2)
        capeVisible = true
        if player and player.Character and player.Character:FindFirstChild("Humanoid") then
            local torso = player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("UpperTorso")
            
            if not capethingmain then
                capethingmain = Instance.new("Part", torso.Parent)
                capethingmain.Name = "SaladClient Cape"
                capethingmain.Anchored = false
                capethingmain.CanCollide = false
                capethingmain.TopSurface = 0
                capethingmain.BottomSurface = 0
                capethingmain.Color = Color3.fromRGB(0, 0, 0)
                capethingmain.FormFactor = "Custom"
                capethingmain.Size = Vector3.new(0.2,0.2,0.2)

                local meshforcape = Instance.new('BlockMesh', capethingmain)
                meshforcape.Scale = Vector3.new(9,16.7,0.5)
                
                local capeimg = Instance.new('Decal', capethingmain)
                capeimg.Face = 'Back'
                capeimg.Texture = 'rbxassetid://14927013080'

                local thingy = Instance.new("Motor", capethingmain)
                thingy.Part0 = capethingmain
                thingy.Part1 = torso
                thingy.MaxVelocity = 0.01
                thingy.C0 = CFrame.new(0,1.9,0) * CFrame.Angles(0,math.rad(90),0)
                thingy.C1 = CFrame.new(0,1,0.45) * CFrame.Angles(0,math.rad(90),0)
				local thingz = false
				function capeanimation()
					thingz = true 
					repeat 
						wait(1/44)
						local ang = 0.1
						local oldmag = torso.Velocity.magnitude
						local mv = 0.002
						if wave then
							ang = ang + ((torso.Velocity.magnitude/10) * 0.05) + 0.05
							wave = false
						else
							wave = true
						end
						ang = ang + math.min(torso.Velocity.magnitude/11,0.5)
						thingy.MaxVelocity = math.min((torso.Velocity.magnitude/111), 0.04) + mv
						thingy.DesiredAngle = -ang
						if thingy.CurrentAngle < -0.2 and thingy.DesiredAngle > -0.2 then
							thingy.MaxVelocity = 0.04
						end
						repeat 
							wait() 
						until thingy.CurrentAngle == thingy.DesiredAngle or math.abs(torso.Velocity.magnitude - oldmag) >= (torso.Velocity.magnitude/10) + 1
						if torso.Velocity.magnitude < 0.1 then
							wait(0.1)
						end
					until not thingz
				end
				
				coroutine.wrap(capeanimation)()  	
            else
                capethingmain.Transparency = 0
            end
        end
    else
        capeVisible = false
        if capethingmain then
			thingz = false
            capethingmain.Transparency = 1 
            capethingmain:Destroy()
		end
    end
end)

game.Players.LocalPlayer.CharacterAdded:Connect(function(character)
    --debugging lines here lol
    --print("character has respawned, recreating yesyes")
    wait(1) 
    --print("wait time passed, so for now all good")
    if capeVisible then
        --print("cape is visible yes")
        local torso = character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso")
        if not capethingmain then
            capethingmain = Instance.new("Part", torso.Parent)
            capethingmain.Name = "SaladClient Cape"
            capethingmain.Anchored = false
            capethingmain.CanCollide = false
            capethingmain.TopSurface = 0
            capethingmain.BottomSurface = 0
            capethingmain.Color = Color3.fromRGB(0, 0, 0)
            capethingmain.FormFactor = "Custom"
            capethingmain.Size = Vector3.new(0.2,0.2,0.2)

            local meshforcape = Instance.new('BlockMesh', capethingmain)
            meshforcape.Scale = Vector3.new(9,16.7,0.5)
            
            local capeimg = Instance.new('Decal', capethingmain)
            capeimg.Face = 'Back'
            capeimg.Texture = 'rbxassetid://14927013080'

            local thingy = Instance.new("Motor", capethingmain)
            thingy.Part0 = capethingmain
            thingy.Part1 = torso
            thingy.MaxVelocity = 0.01
            thingy.C0 = CFrame.new(0,1.9,0) * CFrame.Angles(0,math.rad(90),0)
            thingy.C1 = CFrame.new(0,1,0.45) * CFrame.Angles(0,math.rad(90),0)
            local thingz = false
            --actually this isnt mine, credits to the owner
            function capeanimation()
                thingz = true 
                repeat 
                    wait(1/44)
                    local ang = 0.1
                    local oldmag = torso.Velocity.magnitude
                    local mv = 0.002
                    if wave then
                        ang = ang + ((torso.Velocity.magnitude/10) * 0.05) + 0.05
                        wave = false
                    else
                        wave = true
                    end
                    ang = ang + math.min(torso.Velocity.magnitude/11,0.5)
                    thingy.MaxVelocity = math.min((torso.Velocity.magnitude/111), 0.04) + mv
                    thingy.DesiredAngle = -ang
                    if thingy.CurrentAngle < -0.2 and thingy.DesiredAngle > -0.2 then
                        thingy.MaxVelocity = 0.04
                    end
                    repeat 
                        wait() 
                    until thingy.CurrentAngle == thingy.DesiredAngle or math.abs(torso.Velocity.magnitude - oldmag) >= (torso.Velocity.magnitude/10) + 1
                    if torso.Velocity.magnitude < 0.1 then
                        wait(0.1)
                    end
                until not thingz
            end
            
            coroutine.wrap(capeanimation)()
            --print("cape is fully visible")
        end
    end
end)


RenderTab:CreateToggle("Logo", function(callback)
   if callback then 
   local Converted = {
	["_Logo"] = Instance.new("ScreenGui");
	["_Frame"] = Instance.new("Frame");
	["_Frame1"] = Instance.new("Frame");
	["_LocalScript"] = Instance.new("LocalScript");
	["_UIGradient"] = Instance.new("UIGradient");
	["_TextLabel"] = Instance.new("TextLabel");
	["_UIStroke"] = Instance.new("UIStroke");
	["_TextLabel1"] = Instance.new("TextLabel");
	["_counter_main"] = Instance.new("LocalScript");
	["_update_rate"] = Instance.new("NumberValue");
}


Converted["_Logo"].ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Converted["_Logo"].Name = "Logo"
Converted["_Logo"].Parent = game:GetService("CoreGui")

Converted["_Frame"].BackgroundColor3 = Color3.fromRGB(22.000000588595867, 22.000000588595867, 22.000000588595867)
Converted["_Frame"].BorderColor3 = Color3.fromRGB(0, 0, 0)
Converted["_Frame"].BorderSizePixel = 0
Converted["_Frame"].Position = UDim2.new(0, 14, 0, 49)
Converted["_Frame"].Size = UDim2.new(0.109266952, 0, 0.0303398054, 0)
Converted["_Frame"].Parent = Converted["_Logo"]

Converted["_Frame1"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Converted["_Frame1"].BorderColor3 = Color3.fromRGB(0, 0, 0)
Converted["_Frame1"].BorderSizePixel = 0
Converted["_Frame1"].Size = UDim2.new(1, 0, -0.0799999982, 0)
Converted["_Frame1"].Parent = Converted["_Frame"]

Converted["_UIGradient"].Parent = Converted["_Frame1"]

Converted["_TextLabel"].Font = Enum.Font.SciFi
Converted["_TextLabel"].Text = "SaladClient"
Converted["_TextLabel"].TextColor3 = Color3.fromRGB(255, 255, 255)
Converted["_TextLabel"].TextSize = 19
Converted["_TextLabel"].TextStrokeTransparency = 3
Converted["_TextLabel"].TextWrapped = true
Converted["_TextLabel"].TextXAlignment = Enum.TextXAlignment.Left
Converted["_TextLabel"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Converted["_TextLabel"].BackgroundTransparency = 1
Converted["_TextLabel"].BorderColor3 = Color3.fromRGB(0, 0, 0)
Converted["_TextLabel"].BorderSizePixel = 0
Converted["_TextLabel"].Position = UDim2.new(0.012, 0, 0.0699999982, 0)
Converted["_TextLabel"].Size = UDim2.new(0.589095712, 0, 0.920000017, 0)
Converted["_TextLabel"].Parent = Converted["_Frame"]
Converted["_TextLabel"].Name = "sc logo"

Converted["_UIStroke"].Color = Color3.fromRGB(34.00000177323818, 34.00000177323818, 34.00000177323818)
Converted["_UIStroke"].LineJoinMode = Enum.LineJoinMode.Miter
Converted["_UIStroke"].Thickness = 4
Converted["_UIStroke"].Parent = Converted["_Frame"]

Converted["_TextLabel1"].Font = Enum.Font.SciFi
Converted["_TextLabel1"].TextColor3 = Color3.fromRGB(255, 255, 255)
Converted["_TextLabel1"].TextSize = 19
Converted["_TextLabel1"].TextStrokeTransparency = 3
Converted["_TextLabel1"].BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Converted["_TextLabel1"].BackgroundTransparency = 1
Converted["_TextLabel1"].BorderColor3 = Color3.fromRGB(0, 0, 0)
Converted["_TextLabel1"].BorderSizePixel = 0
Converted["_TextLabel1"].Position = UDim2.new(0.68860755, 3, 0.0999999982, 2)
Converted["_TextLabel1"].Size = UDim2.new(0, 65, 0, 23)
Converted["_TextLabel1"].Parent = Converted["_Frame"]
Converted["_TextLabel1"].Name = "FPS"

Converted["_update_rate"].Value = 1
Converted["_update_rate"].Name = "update_rate"
Converted["_update_rate"].Parent = Converted["_TextLabel1"]

local fake_module_scripts = {}

local function RRKU_fake_script() 
    local script = Instance.new("LocalScript")
    script.Name = "LocalScript"
    script.Parent = Converted["_Frame1"]
    local req = require
    local require = function(obj)
        local fake = fake_module_scripts[obj]
        if fake then
            return fake()
        end
        return req(obj)
    end

	--this script isnt mine, credits to the owner.
	local button = script.Parent
	
	local gradient = button.UIGradient
	
	local ts = game:GetService("TweenService")
	
	local ti = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	
	local offset = {Offset = Vector2.new(1, 0)}
	
	local create = ts:Create(gradient, ti, offset)
	
	local startingPos = Vector2.new(-1, 0)
	
	local list = {} 
	
	local s, kpt = ColorSequence.new, ColorSequenceKeypoint.new
	
	local counter = 0
	
	local status = "down" 
	
	gradient.Offset = startingPos
	
	local function rainbowColors()
	
		local sat, val = 255, 255 
	
		for i = 1, 15 do 
	
			local hue = i * 17 
	
			table.insert(list, Color3.fromHSV(hue / 255, sat / 255, val / 255))
	
		end
	
	end
	
	rainbowColors()
	
	gradient.Color = s({
	
		kpt(0, list[#list]),
	
		kpt(0.5, list[#list - 1]),
	
		kpt(1, list[#list - 2])
	
	})
	
	counter = #list
	
	local function animate()
	
		create:Play()
	
		create.Completed:Wait() 
	
		gradient.Offset = startingPos 
	
		gradient.Rotation = 180
	
		if counter == #list - 1 and status == "down" then
	
			gradient.Color = s({
	
				kpt(0, gradient.Color.Keypoints[1].Value),
	
				kpt(0.5, list[#list]), 
	
				kpt(1, list[1]) 
	
			})
	
			counter = 1
	
			status = "up" 
	
		elseif counter == #list and status == "down" then 
	
			gradient.Color = s({
	
				kpt(0, gradient.Color.Keypoints[1].Value),
	
				kpt(0.5, list[1]),
	
				kpt(1, list[2])
	
			})
	
			counter = 2
	
			status = "up"
	
		elseif counter <= #list - 2 and status == "down" then 
	
			gradient.Color = s({
	
				kpt(0, gradient.Color.Keypoints[1].Value),
	
				kpt(0.5, list[counter + 1]), 
	
				kpt(1, list[counter + 2])
	
			})
	
			counter = counter + 2
	
			status = "up"
	
		end
	
		create:Play()
	
		create.Completed:Wait()
	
		gradient.Offset = startingPos
	
		gradient.Rotation = 0 
	
		if counter == #list - 1 and status == "up" then
	
			gradient.Color = s({ 
	
	
	
				kpt(0, list[1]), 
	
				kpt(0.5, list[#list]), 
	
				kpt(1, gradient.Color.Keypoints[3].Value)
	
			})
	
			counter = 1
	
			status = "down"
	
		elseif counter == #list and status == "up" then
	
			gradient.Color = s({
	
				kpt(0, list[2]),
	
				kpt(0.5, list[1]), 
	
				kpt(1, gradient.Color.Keypoints[3].Value)
	
			})
	
			counter = 2
	
			status = "down"
	
		elseif counter <= #list - 2 and status == "up" then
	
			gradient.Color = s({
	
				kpt(0, list[counter + 2]), 
	
				kpt(0.5, list[counter + 1]), 
	
				kpt(1, gradient.Color.Keypoints[3].Value) 	
	
			})
	
			counter = counter + 2
	
			status = "down"
	
		end
	
		animate()
	
	end
	
	animate()
end
local function FIPPZ_fake_script()
    local script = Instance.new("LocalScript")
    script.Name = "counter_main"
    script.Parent = Converted["_TextLabel1"]
    local req = require
    local require = function(obj)
        local fake = fake_module_scripts[obj]
        if fake then
            return fake()
        end
        return req(obj)
    end

	local services = {
		["run_service"] = game:GetService("RunService"),
	}
	
	local fps = script.Parent
	local update_rate = fps.update_rate.Value
	update_rate = (update_rate < 0.25 or update_rate > 2) and 1 or update_rate
	
	local frames_rendered = 0
	local last_update = tick() - update_rate
	local multiplier = 1 / update_rate
	services["run_service"].RenderStepped:Connect(
		function()
			if tick() - last_update >= update_rate then
				fps.Text = tostring(math.round(frames_rendered * multiplier)).. " FPS"
				frames_rendered = 0; last_update = tick()
			else
				frames_rendered += 1
			end
		end
	)
end

coroutine.wrap(RRKU_fake_script)()
coroutine.wrap(FIPPZ_fake_script)()
else
	local cg = game:GetService("CoreGui")
	if cg:FindFirstChild("Logo") then 
		local logo = cg.Logo
		if logo then 
			logo:Destroy()
		else
			print("not a valid member so not doing a single thing")
		end
	else
		print("not a valid member so not doing a single thing")
	end
end
end	
)
--done

--utility tab
--my old ass bypass lmfao
local RunService = game:GetService("RunService")

function getScytheDash() 
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local rbxts_include = ReplicatedStorage:WaitForChild("rbxts_include", 1)
    local node_modules = rbxts_include and rbxts_include:WaitForChild("node_modules", 1)
    return node_modules and node_modules["@rbxts"].net.out._NetManaged.ScytheDash
end

function dashtroll()
    local direction = LP.Character.HumanoidRootPart.CFrame.LookVector * 100000000
    local scytheDash = getScytheDash()

    if scytheDash then
        scytheDash:FireServer({ direction = direction })
    end
end

local connection
UtilityTab:CreateToggle(
    "Scythe Bypass",
    function(callback) 
        if callback then 
            if connection then 
                connection:Disconnect()
            end
            connection = RunService.RenderStepped:Connect(dashtroll)
        else
            if connection then
                connection:Disconnect()
                connection = nil
            end
        end
    end
)

--done 

--world tab
function touch(av)
	local pr = av.Parent
	if game.Players:GetPlayerFromCharacter(pr) then
		pr.HumanoidRootPart.CFrame = pr.HumanoidRootPart.CFrame + Vector3.new(0, 200, 0)
	end
end

WorldTab:CreateToggle(
	"AntiVoid",
	function(callback) 
		if callback then
			av = Instance.new("Part", workspace)
			av.Size = Vector3.new(1e9, 2, 1e12)
			av.Name = "Antivoid"
			av.Position = Vector3.new(0, 20, 0)
			av.Anchored = true
			av.BrickColor = BrickColor.new("Magenta")
			av.Transparency = 0.7
			av.FrontSurface = Enum.SurfaceType.Smooth
			av.BackSurface = Enum.SurfaceType.Smooth
			av.LeftSurface = Enum.SurfaceType.Smooth
			av.RightSurface = Enum.SurfaceType.Smooth
			av.TopSurface = Enum.SurfaceType.Smooth
			av.BottomSurface = Enum.SurfaceType.Smooth
			av.Touched:Connect(touch)
		else
			if av then
				av:Destroy()
				av = nil 
			end
		end
	end 
)



--done

end

warning("SaladClient 4.0", "Loaded game", 3, true) 

