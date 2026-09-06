--[[

░██████╗██╗░░██╗░█████╗░██╗░░██╗███████╗  ░██████╗██╗░░░██╗░██████╗████████╗███████╗███╗░░░███╗
██╔════╝██║░░██║██╔══██╗██║░██╔╝██╔════╝  ██╔════╝╚██╗░██╔╝██╔════╝╚══██╔══╝██╔════╝████╗░████║
╚█████╗░███████║███████║█████═╝░█████╗░░  ╚█████╗░░╚████╔╝░╚█████╗░░░░██║░░░█████╗░░██╔████╔██║
░╚═══██╗██╔══██║██╔══██║██╔═██╗░██╔══╝░░  ░╚═══██╗░░╚██╔╝░░░╚═══██╗░░░██║░░░██╔══╝░░██║╚██╔╝██║
██████╔╝██║░░██║██║░░██║██║░╚██╗███████╗  ██████╔╝░░░██║░░░██████╔╝░░░██║░░░███████╗██║░╚═╝░██║
╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝  ╚═════╝░░░░╚═╝░░░╚═════╝░░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝

██████╗░███████╗██╗███╗░░░███╗░█████╗░░██████╗░██╗███╗░░██╗███████╗██████╗░
██╔══██╗██╔════╝██║████╗░████║██╔══██╗██╔════╝░██║████╗░██║██╔════╝██╔══██╗
██████╔╝█████╗░░██║██╔████╔██║███████║██║░░██╗░██║██╔██╗██║█████╗░░██║░░██║
██╔══██╗██╔══╝░░██║██║╚██╔╝██║██╔══██║██║░░╚██╗██║██║╚████║██╔══╝░░██║░░██║
██║░░██║███████╗██║██║░╚═╝░██║██║░░██║╚██████╔╝██║██║░╚███║███████╗██████╔╝
╚═╝░░╚═╝╚══════╝╚═╝╚═╝░░░░░╚═╝╚═╝░░╚═╝░╚═════╝░╚═╝╚═╝░░╚══╝╚══════╝╚═════╝░
I rescripted my most popular Shake module because it was a disaster.. memory leaks everywhere, unoptimized uncentralized code and buggy behavior.
EXTREMELY IMPORTANT: REMEMBER TO USE :Remove() WHEN YOU'RE DONE WITH A SHAKE SYSTEM TO AVOID UNWANTED MEMORY LEAKS.
THIS IS NOW REQUIRED BOTH ON SERVER AND CLIENT!!!


If you find any memory leaks tell me and I will fix them!!


-- Implementation:
-- This module wraps RbxCameraShaker with server/client replication, player targeting,
-- proximity falloff, tweened settings, rotation bias, muting, and cleanup management.
-- RbxCameraShaker generates the underlying noise. This wrapper applies positional
-- noise directly and uses its frame-to-frame difference for compatible rotation.


-- Introduction:
-- This module creates camera shake effects, driven from the server or from a client.
-- Every shake mixes two independent effects:
--   Positional shake - slides the camera around its position (rumble / vibration feel)
--   Rotational shake - tilts the camera's aim: pitch, yaw and roll (impact / disorientation feel)

-- Setup:
-- Store the module somewhere the client can see it (ReplicatedStorage is recommended).
-- Install the complete RbxCameraShaker CameraShaker ModuleScript as a child of this
-- module, or directly inside ReplicatedStorage. Keep its CameraShakeInstance and
-- CameraShakePresets child modules inside CameraShaker.
-- The bundled client script sets up the client side automatically (it is configured to run
-- even from ReplicatedStorage), so no manual setup is needed. You only need to call
-- ShakeModule.CLIENT_LOAD() yourself if you remove that bundled script.

-- Usage:
-- 1. Require the module
--local ShakeModule = require(game.ReplicatedStorage.CamShakeSystem)

-- 2. Create a new Shake system instance
--local ShakeSystem = ShakeModule.new()
--By default the shake replicates to every player, including players who join later.
--To make it affect only certain players, pass a table of Player instances (SERVER ONLY):
--For example: ShakeModule.new({game.Players.z3ck200})
--Be careful to :Remove() player-limited systems when you're done using them, because once
--all of those players leave, the system is just useless garbage piling up.

--You can add more players to the list later by calling ShakeSystem:AddPlayers() with a table
--of players (only works on systems created with a player list). For example:
--ShakeSystem:AddPlayers({game.Players.z3ck200})





-- 3. Set the Shake Settings
--ShakeSystem:SetValue(PositionMagnitude, RotationMagnitude, Roughness, TweenSpeed)
--   - First parameter: PositionMagnitude - strength of the positional shake. Slides the
--     camera along its own axes: X (left/right), Y (up/down) and Z (forward/back).
--     Reads best near geometry, nearly invisible in wide open space, never tilts the view.
--   - Second parameter: RotationMagnitude - strength of the rotational shake. Tilts the
--     camera (pitch/yaw/roll), so it is visible at any distance, can slant the horizon,
--     and throws off the player's aim.
--   - Third parameter: Roughness - how FAST the shake evolves, not how strong it is.
--     Low = slow swaying, high = fast jittering. 0 brings the shake to a standstill and
--     removes rotational shake. Positional noise freezes at its current offset until the
--     roughness changes or the shake stops.
--   - Fourth parameter: TweenSpeed - how many seconds the three values above take to blend
--     to their new targets when SetValue is called. Set to 0 to apply instantly.
--ShakeSystem:SetValue(1, 2, 3, 0.5)

-- 4. Start the Shake
--ShakeSystem:Start()

-- 5. Stop the Shake
--ShakeSystem:Stop()


-- Advanced Usage:
-- You can pass `nil` for any value you don't want to modify.
-- For example, to modify only RotationMagnitude and Roughness, use:
-- ShakeSystem:SetValue(nil, 2, 3, 0)


-- Distance-based shakes:
-- You can make the shake fade with distance from a part.
-- First parameter is the part, second parameter is the range in studs:
-- ShakeSystem:SetProximityPart(Part,20)
-- The shake is full strength at the part and fades linearly to zero at the given range.
-- Without a proximity part, shakes play at full strength everywhere.

-- NEW!!
-- Rotation bias (per-axis rotation weighting):
-- By default RotationMagnitude shakes pitch, yaw and roll evenly. You can weight each axis
-- independently to change the "shape" of the rotational shake. Two ways to call it:
-- ShakeSystem:SetRotationBias(Vector3.new(PitchWeight, YawWeight, RollWeight), TweenSpeed)
-- ShakeSystem:SetRotationBias(PitchWeight, YawWeight, RollWeight, TweenSpeed)
--   - PitchWeight/YawWeight/RollWeight (X/Y/Z): multipliers on that axis's share of RotationMagnitude.
--     1 = normal strength, 0 = no shake on that axis, >1 = exaggerated. Defaults to (1,1,1).
--   - TweenSpeed: seconds to blend to the new weights, same as SetValue's TweenSpeed.
-- With the 3-number form (not the Vector3 form) you can pass nil for any axis to leave it unchanged.
-- Example (roll-biased "concussion" feel: screen tilts, minimal pitch/yaw wobble):
-- ShakeSystem:SetRotationBias(Vector3.new(0.15, 0.15, 1), 0.3)
-- Example (restore the default even all-axis feel):
-- ShakeSystem:SetRotationBias(Vector3.new(1, 1, 1), 0.3)



-- Notes:
-- - PositionMagnitude (A1, formerly "LShake") moves the camera without turning it.
-- - RotationMagnitude (A2, formerly "AShake") turns the camera without moving it.
-- - Roughness (A3, formerly "Severity") sets the shake's speed; the magnitudes set its strength.
-- - Big impacts (explosions, hits) usually look best with a mix of both magnitudes.
-- - RotationBias reshapes rotational shake toward specific axes (e.g. mostly roll for a dizzy feel).
-- - Set ShakeModule.GlobalShake = false on a client to mute all shakes locally
--   (useful for a "camera shake off" toggle in your settings menu).
-- - Shakes are disabled in VR unless AllowVRHeadsetCompatibility is enabled below (not recommended).

-- Example:
-- ShakeSystem:SetValue(1, 2, 3, 0.5)
-- ShakeSystem:Start()

-- Cleanup:
-- When done with a Shake system, destroy it using :Remove() (required on BOTH server and client).
-- This prevents unnecessary instances and connections from piling up.
-- ShakeModule.KillAll() removes every live shake system at once.
-- Example:
-- ShakeSystem:Remove()


-- Direct dependency and camera-noise engine:
-- Sleitnick/RbxCameraShaker: https://github.com/Sleitnick/RbxCameraShaker
-- RbxCameraShaker is a Roblox port of EZ Camera Shake by Road Turtle Games.

]]
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local ShakeSystem = {}
ShakeSystem.__index = ShakeSystem


ShakeSystem.Int = false
ShakeSystem.ShakeFolder = nil
ShakeSystem.GlobalShake = true
local LoadShake
local ClientSideLoaded = false
local LiveShakes = {}

local AllowVRHeadsetCompatibility = false --Very much not recommended can cause extreme motion sickness!!


local function StartLocal()
	if ShakeSystem.Int then return end

	if script.Parent == ServerStorage or script.Parent == ServerScriptService then
		error("please store the scripts somewhere where it can be replicated to the client preferably replicated storage")
	end

	ShakeSystem.Int = true

	if not script:HasTag("CamShakeSystem_ModulePath") then script:AddTag("CamShakeSystem_ModulePath") end

	ShakeSystem.ShakeFolder = Instance.new("Folder",script)
	ShakeSystem.ShakeFolder.Name = HttpService:GenerateGUID()

end


ShakeSystem.KillAll = function()
	local Success,ErrorMessage = pcall(function()
		script.Remotes.CleanUp_CLIENTCOM:Fire(false,true)
		if RunService:IsServer() then
			script.Remotes.CleanUp:FireAllClients(false,true)
		end
	end)

	if not Success then
		warn("[ShakeSystem] KillAll() failed to fire cleanup events: " .. tostring(ErrorMessage))
	end

	for ShakeInstance in pairs(LiveShakes) do
		local InstanceSuccess,InstanceError = pcall(function()
			if ShakeInstance.IntPlayerAdded then
				ShakeInstance.IntPlayerAdded:Disconnect()
				ShakeInstance.IntPlayerAdded = nil
			end
			if ShakeInstance.WorkingFolder then
				ShakeInstance.WorkingFolder:Destroy()
			end
		end)
		if not InstanceSuccess then
			warn("[ShakeSystem] KillAll() failed to clean a shake: " .. tostring(InstanceError))
		end
	end
	table.clear(LiveShakes)

	if ShakeSystem.ShakeFolder then
		for _,v in pairs(ShakeSystem.ShakeFolder:GetChildren()) do
			v:Destroy()
		end
	end
end

local function AddPlayerInt(UserList,self)
	if RunService:IsServer() and self.OptionalUserList then
		if UserList ~= nil and typeof(UserList) == "table" then
			for _,Player in pairs(UserList) do
				if typeof(Player) == "Instance" and Player:IsA("Player") then
					self.Remotes.SetupShakeSystem:FireClient(Player,self.Shake_ID,self.WorkingFolder)
				else
					error(`{tostring(Player)} Is not a valid player object.`)
				end
			end
		elseif UserList ~= nil then
			error(`Type: {typeof(UserList)}: {tostring(UserList)} | is not a valid table. Ensure you are passing through a table containing Player instances for this to work properly.`)
		end
	end
end


local function NewValue(ClassName, Name, Parent, Value)
	local NewInstance = Instance.new(ClassName)
	NewInstance.Name = Name
	if Value ~= nil then NewInstance.Value = Value end
	NewInstance.Parent = Parent
	return NewInstance
end


ShakeSystem.new = function(OptionalUserList)
	StartLocal()

	local self = setmetatable({},ShakeSystem)
	self.Shake_ID = HttpService:GenerateGUID()
	self.OptionalUserList = OptionalUserList

	self.WorkingFolder = Instance.new("Folder")
	self.WorkingFolder.Name = self.Shake_ID
	self.Remotes = script.Remotes

	self.WorkingFolder:SetAttribute("Enabled", false)
	self.WorkingFolder:SetAttribute("ProxPartSet", false)
	self.WorkingFolder:SetAttribute("OnlyClient", false)
	self.WorkingFolder:SetAttribute("Distance", 9999999)
	self.A1 = NewValue("NumberValue", "A1", self.WorkingFolder)
	self.A2 = NewValue("NumberValue", "A2", self.WorkingFolder)
	self.A3 = NewValue("NumberValue", "A3", self.WorkingFolder)
	self.ProximityPart = NewValue("ObjectValue", "ProximityPart", self.WorkingFolder)

	self.RotationBias = NewValue("Vector3Value", "RotationBias", self.WorkingFolder, Vector3.new(1, 1, 1))

	self.WorkingFolder.Parent = ShakeSystem.ShakeFolder


	if RunService:IsClient() then
		if OptionalUserList ~= nil then
			error("The OptionalUserList feature is compatible on server side only.")
		end
		self.WorkingFolder:SetAttribute("OnlyClient", true)
		LoadShake(self.Shake_ID,self.WorkingFolder)
	else
		if OptionalUserList ~= nil then
			AddPlayerInt(OptionalUserList,self)
		else
			self.Remotes.SetupShakeSystem:FireAllClients(self.Shake_ID,self.WorkingFolder)
			self.IntPlayerAdded = Players.PlayerAdded:Connect(function(Player)
				self.Remotes.SetupShakeSystem:FireClient(Player,self.Shake_ID,self.WorkingFolder)
			end)
		end
	end

	LiveShakes[self] = true
	return self
end

function ShakeSystem:AddPlayers(UserList)
	if self.OptionalUserList == nil then
		error("AddPlayers can not be called on this shake system as it is currently set up to be global. Add {} to the ShakeSystem.new() If you want to change this into a select Shake system")
	end
	AddPlayerInt(UserList,self)
end

function ShakeSystem:Start()
	self.WorkingFolder:SetAttribute("Enabled", true)
end

function ShakeSystem:Stop()
	self.WorkingFolder:SetAttribute("Enabled", false)
end

function ShakeSystem:SetValue(PositionMagnitude, RotationMagnitude, Roughness, TweenSpeed)
	if PositionMagnitude ~= nil then
		TweenService:Create(self.A1,TweenInfo.new(TweenSpeed or 0),{Value = PositionMagnitude}):Play()
	end
	if RotationMagnitude ~= nil then
		TweenService:Create(self.A2,TweenInfo.new(TweenSpeed or 0),{Value = RotationMagnitude}):Play()
	end
	if Roughness ~= nil then
		TweenService:Create(self.A3,TweenInfo.new(TweenSpeed or 0),{Value = Roughness}):Play()
	end
end


function ShakeSystem:SetRotationBias(PitchWeight, YawWeight, RollWeight, TweenSpeed)
	local Target
	if typeof(PitchWeight) == "Vector3" then
		Target = PitchWeight
		TweenSpeed = YawWeight
	else
		if PitchWeight == nil and YawWeight == nil and RollWeight == nil then return end
		local Current = self.RotationBias.Value
		Target = Vector3.new(
			PitchWeight or Current.X,
			YawWeight or Current.Y,
			RollWeight or Current.Z
		)
	end
	TweenService:Create(self.RotationBias,TweenInfo.new(TweenSpeed or 0),{Value = Target}):Play()
end



--hahaha finally a more sophisticated cleanup system
function ShakeSystem:Remove()
	if self._Removed then return end
	self._Removed = true
	LiveShakes[self] = nil
	local Success,ErrorMessage = pcall(function()
		if self.IntPlayerAdded then
			self.IntPlayerAdded:Disconnect()
			self.IntPlayerAdded = nil
		end

		if self.WorkingFolder:GetAttribute("OnlyClient") then

			if self.Remotes.CleanUp_CLIENTCOM then
				self.Remotes.CleanUp_CLIENTCOM:Fire(self.Shake_ID)
			end
		else
			if self.Remotes.CleanUp then
				self.Remotes.CleanUp:FireAllClients(self.Shake_ID)
			end

		end


		task.wait(0.1)
		if self.WorkingFolder then
			self.WorkingFolder:Destroy()
			self.WorkingFolder = nil
		end

		self.Shake_ID = nil
		self.Remotes = nil
	end)

	if not Success then
		warn("[ShakeSystem] Remove() failed: " .. tostring(ErrorMessage))
	end

end

function ShakeSystem:SetProximityPart(Part,Dist)
	if Part and Dist then
		self.WorkingFolder:SetAttribute("ProxPartSet", true)
		self.ProximityPart.Value = Part
		self.WorkingFolder:SetAttribute("Distance", Dist)
	else
		error("Invalid parameters")
	end

end


-----------------------------CLIENT SIDE ONLY-----------------------------

local POSITION_SCALE = 1.363721571
local ROTATION_SCALE = 2.158009825
local ROUGHNESS_SCALE = 1.25

local ClientShakes = {}
local CameraShaker
local RenderBound = false
local RenderName = "CamShakeSystem_REIMAGINED_" .. HttpService:GenerateGUID(false)

local function GetCameraShaker()
	if CameraShaker then return CameraShaker end
	local dependency = script:FindFirstChild("CameraShaker")
		or ReplicatedStorage:FindFirstChild("CameraShaker")
	assert(dependency and dependency:IsA("ModuleScript"),
		"[CamShakeSystem REIMAGINED] Add the complete RbxCameraShaker module as a child named CameraShaker, or put it in ReplicatedStorage.")
	CameraShaker = require(dependency)
	return CameraShaker
end

local function RemoveClientShake(id)
	ClientShakes[id] = nil
	if RenderBound and next(ClientShakes) == nil then
		RunService:UnbindFromRenderStep(RenderName)
		RenderBound = false
	end
end

local function CleanupClient(id, all)
	if all then
		table.clear(ClientShakes)
		if RenderBound then
			RunService:UnbindFromRenderStep(RenderName)
			RenderBound = false
		end
	else
		RemoveClientShake(id)
	end
end

local function CanShake()
	if not ShakeSystem.GlobalShake then return false end
	if UserInputService.VREnabled and not AllowVRHeadsetCompatibility then
		return false
	end
	if game.CreatorId == 34859835 then
		local settings = ReplicatedStorage:FindFirstChild("GameSettings")
		local setting = settings and settings:FindFirstChild("Shake")
		local forceOff = ReplicatedStorage:FindFirstChild("ForceShakeOff")
		if setting and not setting.Value then return false end
		if forceOff and forceOff.Value then return false end
	end
	return true
end

local function GetDistanceScale(folder, proximity)
	if not folder:GetAttribute("ProxPartSet") then return 1 end
	local part = proximity.Value
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local distance = folder:GetAttribute("Distance")
	if not part or not part:IsA("BasePart") or not part:IsDescendantOf(workspace)
		or not root or type(distance) ~= "number" or distance <= 0 then
		return 0
	end
	return math.clamp(1 - (part.Position - root.Position).Magnitude / distance, 0, 1)
end

local function UpdateClientShakes(dt)
	local camera = workspace.CurrentCamera
	local allowed = camera ~= nil and CanShake()
	local combined = CFrame.new()

	for id, record in pairs(ClientShakes) do
		local folder = record.Folder
		if not folder:IsDescendantOf(game) then
			RemoveClientShake(id)
		else
			if not record.Shake then
				local a1 = folder:FindFirstChild("A1")
				local a2 = folder:FindFirstChild("A2")
				local a3 = folder:FindFirstChild("A3")
				local bias = folder:FindFirstChild("RotationBias")
				local proximity = folder:FindFirstChild("ProximityPart")
				if a1 and a2 and a3 and bias and proximity then
					record.A1, record.A2, record.A3 = a1, a2, a3
					record.Bias, record.Proximity = bias, proximity
					record.Shake = CameraShaker.CameraShakeInstance.new(1, 0, 0, 0)
					record.Shake:StartFadeIn(0)
					record.PreviousNoise = nil
				end
			end

			if record.Shake and allowed and folder:GetAttribute("Enabled") then
				local distanceScale = GetDistanceScale(folder, record.Proximity)
				local roughness = record.A3.Value
				local shake = record.Shake
				shake.Roughness = roughness * ROUGHNESS_SCALE
				local noise = shake:UpdateShake(dt)
				local delta = record.PreviousNoise and (noise - record.PreviousNoise) or Vector3.zero
				record.PreviousNoise = noise
				if roughness == 0 then delta = Vector3.zero end
				local position = noise * (record.A1.Value * POSITION_SCALE * distanceScale)
				local rotation = delta * record.Bias.Value
					* (record.A2.Value * ROTATION_SCALE * distanceScale / 6.5)
				combined = combined * CFrame.new(position)
					* CFrame.Angles(rotation.X, rotation.Y, rotation.Z)
			end
		end
	end

	if allowed then
		camera.CFrame = camera.CFrame * combined
	end
end

LoadShake = function(Shake_ID, WorkingFolder)
	if not RunService:IsClient() then return false end
	if typeof(WorkingFolder) ~= "Instance" or not WorkingFolder:IsA("Folder") then
		return false
	end
	ShakeSystem.CLIENT_LOAD()
	if ClientShakes[Shake_ID] then return true end
	ClientShakes[Shake_ID] = { Folder = WorkingFolder }
	if not RenderBound then
		RunService:BindToRenderStep(RenderName, Enum.RenderPriority.Camera.Value + 1, UpdateClientShakes)
		RenderBound = true
	end
	return true
end

function ShakeSystem.CLIENT_LOAD()
	if not RunService:IsClient() or ClientSideLoaded then return end
	GetCameraShaker()
	local remotes = script:WaitForChild("Remotes")
	local setup = remotes:WaitForChild("SetupShakeSystem")
	local cleanup = remotes:WaitForChild("CleanUp")
	local localCleanup = remotes:WaitForChild("CleanUp_CLIENTCOM")
	if ClientSideLoaded then return end
	if game.CreatorId ~= 16381439 and game.CreatorId ~= 34859835 then
		print(`✨ Thank you for using CamShakeSystem REIMAGINED! by VexThatProtogen! ✨\n\nhttps://create.roblox.com/store/asset/135194268534411/CamShakeSystem-REIMAGINED`)
	end
	ClientSideLoaded = true
	setup.OnClientEvent:Connect(LoadShake)
	cleanup.OnClientEvent:Connect(CleanupClient)
	localCleanup.Event:Connect(CleanupClient)
end

return ShakeSystem
