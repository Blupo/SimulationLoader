local t = require(script.Parent:FindFirstChild("t"))

---

local Utilities = {}

Utilities.StructureTypeChecks = {}

Utilities.StructureTypeChecks.SimulationData = t.interface({
	AutoTools = t.map(t.string, t.literal(true)),
	Aliases = t.map(t.string, t.literal(true)),

	Name = t.string,
	SimulationType = t.string,
	Attribution = t.string,
})

Utilities.StructureTypeChecks.Simulation = t.interface({
	SimulationData = Utilities.StructureTypeChecks.SimulationData,

	PreLoad = t.optional(t.callback),
	PostLoad = t.optional(t.callback),
	PreUnload = t.optional(t.callback),
	PostUnload = t.optional(t.callback),
})

Utilities.StructureTypeChecks.PhysicalSimulation = t.instanceOf("Folder", {
	LoadScripts = t.instanceOf("Folder", {
		PreLoad = t.optional(t.instanceOf("ModuleScript")),
		PostLoad = t.optional(t.instanceOf("ModuleScript")),
		PreUnload = t.optional(t.instanceOf("ModuleScript")),
		PostUnload = t.optional(t.instanceOf("ModuleScript")),
	}),

	SimulationData = t.instanceOf("Folder", {
		AutoTools = t.wrap(function(folder)
			return t.values(t.instanceOf("BoolValue"))(folder:GetChildren())
		end, t.instanceOf("Folder")),

		Aliases = t.wrap(function(folder)
			return t.values(t.instanceOf("BoolValue"))(folder:GetChildren())
		end, t.instanceOf("Folder")),

		Name = t.instanceOf("StringValue"),
		SimulationType = t.instanceOf("StringValue"),
		Attribution = t.instanceOf("StringValue"),
	}),

	Simulation = t.instanceOf("Model"),
})

---

--[[

	Transforms a PhysicalSimulation into a Simulation that can be used by the SimulationLoader

	@param PhysicalSimulation
	@return Simulation

--]]
Utilities.SimulationFromPhysicalSimulation = t.wrap(function(physicalSimulation)
	local simulation = {
		SimulationData = {
			AutoTools = {},
			Aliases = {}
		},
	}

	local loadScriptsFolder = physicalSimulation:FindFirstChild("LoadScripts")
	local simulationDataFolder = physicalSimulation:FindFirstChild("SimulationData")
	local simulationModel = physicalSimulation:FindFirstChild("Simulation")

	for _, autoToolValue in pairs(simulationDataFolder:FindFirstChild("AutoTools"):GetChildren()) do
		simulation.SimulationData.AutoTools[autoToolValue.Name] = true
	end

	simulation.SimulationData.Name = string.lower(simulationDataFolder:FindFirstChild("Name").Value)
	simulation.SimulationData.SimulationType = simulationDataFolder:FindFirstChild("SimulationType").Value
	simulation.SimulationData.Attribution = simulationDataFolder:FindFirstChild("Attribution").Value

	for _, aliasValue in ipairs(simulationDataFolder:FindFirstChild("Aliases"):GetChildren()) do
		simulation.SimulationData.Aliases[string.lower(aliasValue.Name)] = true
	end

	simulation.Simulation = simulationModel

	---

	local preLoadScript = loadScriptsFolder:FindFirstChild("PreLoad")
	local postLoadScript = loadScriptsFolder:FindFirstChild("PostLoad")
	local preUnloadScript = loadScriptsFolder:FindFirstChild("PreUnload")
	local postUnloadScript = loadScriptsFolder:FindFirstChild("PostUnload")

	simulation.PreLoad = preLoadScript and require(preLoadScript)
	simulation.PostLoad = postLoadScript and require(postLoadScript)
	simulation.PreUnload = preUnloadScript and require(preUnloadScript)
	simulation.PostUnload = postUnloadScript and require(postUnloadScript)

	return simulation
end, Utilities.StructureTypeChecks.PhysicalSimulation)

---

return Utilities