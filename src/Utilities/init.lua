local t = require(script.Parent:FindFirstChild("t"))

---

-- converts keys to array items
local function dictToArray(dict)
	local array = {}

	for key in pairs(dict) do
		array[#array + 1] = key
	end

	return array
end

local Utilities = {}

Utilities.StructureTypeChecks = {}

Utilities.StructureTypeChecks.SimulationData = t.interface({
	AutoTools = t.array(t.string),
	Aliases = t.array(t.string),

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

	Simulation = t.instanceOf("Model"),
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

	-- construct auto tools list
	do
		local uniqueAutoToolsMap = {}

		for _, autoToolValue in pairs(simulationDataFolder:FindFirstChild("AutoTools"):GetChildren()) do
			uniqueAutoToolsMap[autoToolValue.Name] = true
		end

		simulation.SimulationData.AutoTools = dictToArray(uniqueAutoToolsMap)
	end

	simulation.SimulationData.Name = string.lower(simulationDataFolder:FindFirstChild("Name").Value)
	simulation.SimulationData.SimulationType = simulationDataFolder:FindFirstChild("SimulationType").Value
	simulation.SimulationData.Attribution = simulationDataFolder:FindFirstChild("Attribution").Value

	-- construct alias list
	do
		local uniqueAliasMap = {}

		for _, aliasValue in ipairs(simulationDataFolder:FindFirstChild("Aliases"):GetChildren()) do
			uniqueAliasMap[string.lower(aliasValue.Name)] = true
		end

		simulation.SimulationData.Aliases = dictToArray(uniqueAliasMap)
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