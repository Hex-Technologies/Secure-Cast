--!strict

-- ******************************* --
-- 			AX3NX / AXEN		   --
-- ******************************* --

---- Services ----

local RunService = game:GetService("RunService")
local QuickSetupUtility = require(Utility.QuickSetup)
local Players = game:GetService("Players")

---- Imports ----

local Utility = script.Utility

local Settings = require(script.Settings)

--> Ensure that a visuals and characters folder exists
local CharactersFolder: Folder;
do
	local Visuals = workspace:FindFirstChild(Settings.VisualsFolder)
	local Characters = workspace:FindFirstChild(Settings.CharactersFolder)
    if not Visuals then
        local Folder = Instance.new("Folder", workspace)
        Folder.Name = Settings.VisualsFolder
	end
	if not Characters then
		CharactersFolder = Instance.new("Folder", workspace)
		CharactersFolder.Name = Settings.CharactersFolder
	end
end

--> Optional quick setup
do
    if Settings.EnableQuickSetup and IS_SERVER then
        QuickSetupUtility.Run()
    end
end

local Dispatcher = require(script.Dispatcher)
local Simulation = require(script.Simulation)
local SnapshotsUtility = require(Utility.Snapshots)

---- Settings ----

local IS_SERVER = RunService:IsServer()

export type Settings = typeof(Settings)

---- Constants ----

local SecureCast = {
    Settings = Settings,
    Snapshots = SnapshotsUtility
}

---- Variables ----

local SimulationDispatcher;

---- Private Functions ----

---- Public Functions ----

function SecureCast.Initialize()
	assert(SimulationDispatcher == nil, "SecureCast.Initialize can only be called once per execution context!")
	
    Simulation.ImportDefentions()
    SimulationDispatcher = Dispatcher.new(Settings.Threads, script.Simulation, Simulation.Process)

	if IS_SERVER then
		local function AddCharacters(Player: Player)
			Player.CharacterAdded:Connect(function(Character)
				Character.Parent = CharactersFolder
			end)
		end
		Players.PlayerAdded:Connect(AddCharacters)
		for _,Player in pairs(Players:GetPlayers()) do
			AddCharacters(Player)
		end
        RunService.PostSimulation:Connect(function()
            SnapshotsUtility.CreatePlayersSnapshot(workspace:GetServerTimeNow())
        end)
    end
end

function SecureCast.Cast(Caster: Player, Type: string, Origin: Vector3, Direction: Vector3, Timestamp: number, PVInstance: PVInstance?, Modifier: Simulation.Modifier?)
    assert(SimulationDispatcher, "You must call SecureCast.Initialize before calling SecureCast.Cast!")
    SimulationDispatcher:Dispatch(Caster, Type, Origin, Direction, Timestamp, PVInstance, Modifier)
end

---- Initialization ----

---- Connections ----

return SecureCast