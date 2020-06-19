--[[

	SimulationLoader Reference

	Data Structures

		PhysicalSimulation: Folder = {
			LoadScripts: Folder
				PreLoad: ModuleScript?
				PostLoad: ModuleScript?
				PreUnload: ModuleScript?
				PostUnload: ModuleScript?
			SimulationData: Folder
				AutoTools: Folder<BoolValue>
				Aliases: Folder<BoolValue>

				Name: StringValue
				SimulationType: StringValue
				Attribution: StringValue
			Simulation: Model
		}

		SimulationData = {
			Name: string,
			SimulationType: string,
			Attribution: string,

			AutoTools: array<string>,
			Aliases: array<string>
		}

		Simulation = {
			SimulationData: SimulationData,

			PreLoad: function?,
			PostLoad: function?,
			PreUnload: function?,
			PostUnload: function?,

			Simulation: Model
		}

	SimulationLoader

		Callbacks

			SimulationLoader.LoadAnimation(simulationCopy: Model, simulationContainer: Model, doneEvent: BindableEvent): nil
			SimulationLoader.UnloadAnimation(simulationCopy: Model, simulationContainer: Model, doneEvent: BindableEvent): nil

		Events

			SimulationLoader.SimulationLoading(simulationData: SimulationData)
			SimulationLoader.SimulationUnloading(simulationData: SimulationData)
			SimulationLoader.SimulationLoaded(simulationData: SimulationData)
			SimulationLoader.SimulationUnloaded(simulationData: SimulationData)

			SimulationLoader.SimulationAdded(simulationData: SimulationData)

		Functions

			SimulationLoader.AddSimulation(newSimulation: Simulation): nil
			SimulationLoader.AddPhysicalSimulation(physicalSimulation: PhysicalSimulation): nil

			SimulationLoader.Load(simulationName: string): nil
			SimulationLoader.Unload(): nil

			SimulationLoader.ResolveSimulationName(simulationName: string): string?
			SimulationLoader.GetSimulationData(simulationName: string): SimulationData?
			SimulationLoader.GetAllSimulationsData(): array<SimulationData>

		Properties

			SimulationLoader.CurrentSimulation: string
			SimulationLoader.SimulationContainer: Model
			SimulationLoader.Simulations: array<Simulation>
			SimulationLoader.AliasMap: dictionary<string, string>

			SimulationLoader.SimulationIsLoaded: boolean
			SimulationLoader.IsWorking: boolean

--]]

local Utilities = require(script:FindFirstChild("Utilities"))

---

--[[

	type array<T> = {[number]: T}
	type dictionary<T, TT> = {[T]: TT}

	type SimulationData {
		Name: string
		SimulationType: string
		Attribution: string

		AutoTools: dictionary<string, boolean>
		Aliases: dictionary<string, boolean>
	}

	type Simulation {
		Data: SimulationData
		AutoTools: dictionary<string, boolean>

		PreLoad: function?
		PostLoad: function?
		PreUnload: function?
		PostUnload: function?

		Simulation: Model
	}

--]]

local SimulationLoader = {}

--[[

	Constructor for the SimulationLoader class

	@param Model The container in which simulations will be loaded into
	@return SimulationLoader

--]]
function SimulationLoader.new(simulationContainer)
	--[[
	-- in a world where type annotations can be published

	local self = {
		LoadAnimation: (Model|Folder, Model) -> () -> boolean,
		UnloadAnimation: (Model|Folder, Model) -> () -> boolean,

		CurrentSimulation: string = "",
		SimulationContainer: Model = simulationContainer,
		Simulations: array<Simulation> = {},
		AliasMap: dictionary<string, string> = {},

		SimulationIsLoaded: boolean = false,
		IsWorking: boolean = false,
	}

	--]]


	local self = {
		CurrentSimulation = "",
		SimulationContainer = simulationContainer,
		Simulations = {},
		AliasMap = {},
		LoadingAnimations = {},

		SimulationIsLoaded = false,
		IsWorking = false,
	}
	setmetatable(self, {__index = SimulationLoader})

	local simulationLoadingEvent = Instance.new("BindableEvent")
	local simulationUnloadingEvent = Instance.new("BindableEvent")

	local simulationLoadedEvent = Instance.new("BindableEvent")
	local simulationUnloadedEvent = Instance.new("BindableEvent")

	local simulationAddedEvent = Instance.new("BindableEvent")

	self.SimulationLoadingEvent = simulationLoadingEvent
	self.SimulationUnloadingEvent = simulationUnloadingEvent
	self.SimulationLoadedEvent = simulationLoadedEvent
	self.SimulationUnloadedEvent = simulationUnloadedEvent

	self.SimulationLoading = simulationLoadingEvent.Event
	self.SimulationUnloading = simulationUnloadingEvent.Event
	self.SimulationLoaded = simulationLoadedEvent.Event
	self.SimulationUnloaded = simulationUnloadedEvent.Event

	self.SimulationAddedEvent = simulationAddedEvent
	self.SimulationAdded = simulationAddedEvent.Event

	return self
end

--[[

	Adds a simulation to the simulation list

	@param Simulation

--]]
function SimulationLoader:AddSimulation(newSimulation)
	assert(Utilities.StructureTypeChecks.Simulation(newSimulation))

	local newSimulationName = newSimulation.SimulationData.Name

	-- Check if a simulation by that name already exists
	for simulationName in pairs(self.Simulations) do
		if (simulationName == newSimulationName) then
			warn("SIMULATIONLOADER: A simulation with the name " .. newSimulationName .. " already exists")
			return
		end
	end

	-- Check if the simulation's name matches any aliases
	for alias in pairs(self.AliasMap) do
		alias = string.lower(alias)

		if (alias == newSimulationName) then
			warn("SIMULATIONLOADER: The simulation name " .. newSimulationName .. " matches an existing alias")
			return
		end
	end

	-- Add the simulation and link aliases
	self.Simulations[newSimulationName] = newSimulation
    print("SIMULATIONLOADER: Successfully added simulation " .. newSimulationName)

	for _, alias in pairs(newSimulation.SimulationData.Aliases) do
		alias = string.lower(alias)

		self.AliasMap[alias] = newSimulationName
		print("SIMULATIONLOADER: Got alias " .. alias .. " for simulation " .. newSimulationName)
	end

	self.SimulationAddedEvent:Fire(newSimulation.SimulationData)
end

--[[

	Same as AddSimulation, except that it takes a PhysicalSimulation instead

	@param PhysicalSimulation : newSimulation

--]]
function SimulationLoader:AddPhysicalSimulation(newSimulation)
	local simulation = Utilities.SimulationFromPhysicalSimulation(newSimulation)

	-- Cannot use : here, need to use . and pass self
	SimulationLoader.AddSimulation(self, simulation)
end

--[[

	Attempts to find the corresponding simulation name give a string

	@param string
	@return string? The actual name of the simulation

--]]
function SimulationLoader:ResolveSimulationName(rawSimulationName)
	rawSimulationName = string.lower(rawSimulationName)

	-- First check if the name directly matches a simulation name
	for simulationName in pairs(self.Simulations) do
		if (rawSimulationName == simulationName) then
			return simulationName
		end
	end

	-- Now check if it matches any aliases
	for alias, simulationName in pairs(self.AliasMap) do
		if (rawSimulationName == alias) then
			return simulationName
		end
	end
end

--[[

	Loads a simulation

	@param string The name or an alias of the simulation

--]]
function SimulationLoader:Load(simulationName)
	if self.SimulationIsLoaded then return end
	if (not self.IsWorking) then self.IsWorking = true else return end

	simulationName = SimulationLoader.ResolveSimulationName(self, simulationName)
	if (not simulationName) then return end

	local simulation = self.Simulations[simulationName]
	if (not simulation) then self.IsWorking = false return end

	local simulationData = simulation.SimulationData
	local preLoad, postLoad = simulation.PreLoad, simulation.PostLoad

	self.SimulationLoadingEvent:Fire(simulationData)

	do
		local simulationCopy = simulation.Simulation:Clone()
		local simulationCopyDescendants = simulationCopy:GetDescendants()

		if preLoad then pcall(preLoad) end

		for _, descendant in ipairs(simulationCopyDescendants) do
			if descendant:IsA("BaseScript") then
				descendant.Disabled = true
			end
		end

		local loadAnimationCallback = self.LoadAnimation
		if loadAnimationCallback then
			local doneEvent = Instance.new("BindableEvent")

			loadAnimationCallback(simulationCopy, self.SimulationContainer, doneEvent)

			doneEvent.Event:Wait()
			doneEvent:Destroy()
		end

		-- otherwise just move the simulation to the container and be done
		simulationCopy.Parent = self.SimulationContainer

		for _, descendant in ipairs(simulationCopyDescendants) do
			if descendant:IsA("BaseScript") then
				descendant.Disabled = false
			end
		end

		if postLoad then pcall(postLoad, simulationCopy) end
	end

	self.SimulationLoadedEvent:Fire(simulationData)

	self.CurrentSimulation = simulationName
	self.SimulationIsLoaded = true
	self.IsWorking = false
end

--[[

	Unloads the currenty loaded simulation

--]]
function SimulationLoader:Unload()
	if (not self.SimulationIsLoaded) then return end
	if (not self.IsWorking) then self.IsWorking = true else return end

	local simulation = self.Simulations[self.CurrentSimulation]
	local simulationData = simulation.SimulationData
	local preUnload, postUnload = simulation.PreUnload, simulation.PostUnload

	self.SimulationUnloadingEvent:Fire(simulationData)

	-- unload
	do
		local simulationCopy = self.SimulationContainer:FindFirstChild("Simulation")
	--	local simulationCopyDescendants = simulationCopy:GetDescendants()

		if preUnload then pcall(preUnload, simulationCopy) end

		--[[
		-- is this necessary for unloading?
		for _, descendant in ipairs(simulationCopyDescendants) do
			if descendant:IsA("BaseScript") then
				descendant.Disabled = true
			end
		end
		--]]

		local unloadAnimationCallback = self.UnloadAnimation
		if unloadAnimationCallback then
			local doneEvent = Instance.new("BindableEvent")

			unloadAnimationCallback(simulationCopy, self.SimulationContainer, doneEvent)

			doneEvent.Event:Wait()
			doneEvent:Destroy()
		end

		-- otherwise just clear the simulation container and be done
		self.SimulationContainer:ClearAllChildren()

		if postUnload then pcall(postUnload) end
	end

	self.SimulationUnloadedEvent:Fire(simulationData)

	self.CurrentSimulation = ""
	self.SimulationIsLoaded = false
	self.IsWorking = false
end

--[[

	Returns the SimulationData for a particular Simulation

	@param string The name of the simulation, case in-sensitive
	@return SimulationData?

--]]
function SimulationLoader:GetSimulationData(simulationName)
	simulationName = string.lower(simulationName)

	local simulation = self.Simulations[simulationName]
	if (not simulation) then return end

	return simulation.SimulationData
end

--[[

	Returns the SimulationData for all simulations

	@return SimulationData

--]]
function SimulationLoader:GetAllSimulationsData()
	local simulationsData = {}

	for simulationName, simulation in pairs(self.Simulations) do
		simulationsData[simulationName] = simulation.SimulationData
	end

	return simulationsData
end

return SimulationLoader