# SimulationLoader

SimulationLoader is a system for loading maps as discrete units called Simulations. It was originally created for [Crylox Legion](https://www.roblox.com/groups/1192846)'s [Zerion holo](https://www.roblox.com/games/3717455865).

Please read the [wiki](https://github.com/Blupo/SimulationLoader/wiki) for getting started with using SimulationLoader.

## API

### Data Structures

#### PhysicalSimulation
See [this page](https://github.com/Blupo/SimulationLoader/wiki/Creating-Physical-Simulations) for constructing physical simulations.

```
Root: Folder
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
```

#### SimulationData

```
SimulationData = {
    Name: string,
    SimulationType: string,
    Attribution: string,

    AutoTools: array<string>,
    Aliases: array<string>
}
```

- `Name`: The name of the simulation
- `SimulationType`: The type of simulation
- `Attribution`: An attribution text
- `AutoTools`: A list of tools that should be automatically given when a simulation is loaded and taken away when unloaded
- `Aliases`: A list of aliases that the simulation can be loaded with.

#### Simulation

```
Simulation = {
    SimulationData: SimulationData,

    PreLoad: function?,
    PostLoad: function?,
    PreUnload: function?,
    PostUnload: function?,

    Simulation: Model
}
```

- `SimulationData`: The `SimulationData` associated with the simulation
- `PreLoad`: A callback called before a simulation begins loading
- `PostLoad`: A callback called after a simulation has loaded
- `PreUnload`: A callback called beore a simulation begins unloading
- `PostUnload`: A callback called after a simulation has unloaded
- `Simulation`: A Model with the simulation content to be loaded

### Constructors

- `SimulationLoader.new(simulationContainer: Model): SimulationLoader`
  - Creates a new SimulationLoader.

### Callbacks

- `SimulationLoader.LoadAnimation(simulationCopy: Model, simulationContainer: Model, doneEvent: BindableEvent): nil`
  - Animation callback for loading simulations. The callback should fire the `doneEvent` when it's done.

- `SimulationLoader.UnloadAnimation(simulationCopy: Model, simulationContainer: Model, doneEvent: BindableEvent): nil`
  - Animation callback for unloading simulations. The callback should fire the `doneEvent` when complete.

### Events

- `SimulationLoader.SimulationLoading(simulationData: SimulationData)`
  - Fires when a simulation begins loading.
- `SimulationLoader.SimulationUnloading(simulationData: SimulationData)`
  - Fires when a simulation begins unloading.
- `SimulationLoader.SimulationLoaded(simulationData: SimulationData)`
  - Fires when a simulation has completed loading.
- `SimulationLoader.SimulationUnloaded(simulationData: SimulationData)`
  - Fires when a simulation has completed unloading.
- `SimulationLoader.SimulationAdded(simulationData: SimulationData)`
  - Fires when a simulation has been added to the loader.

### Functions

- `SimulationLoader.AddSimulation(newSimulation: Simulation): nil`
  - Add a simulation. Unless you're creating a simulation purely from Lua (and maybe some JSON), you should create a physical simulation and add that instead.
- `SimulationLoader.AddPhysicalSimulation(physicalSimulation: PhysicalSimulation): nil`
  - Add a [physical simulation](https://github.com/Blupo/SimulationLoader/wiki/Creating-Physical-Simulations).

- `SimulationLoader.Load(simulationName: string): nil`
  - Load a simulation. This internally uses `SimulationLoader.ResolveSimulationName` to find the simulation name so you don't need to do it before-hand.
- `SimulationLoader.Unload(): nil`
  - Unloads the currently-loaded simulation, if any.

- `SimulationLoader.ResolveSimulationName(simulationName: string): string?`
  - Returns the simulation name from the string provided. Checks simulation names using normalised case as well as aliases.
- `SimulationLoader.GetSimulationData(simulationName: string): SimulationData?`
  - Returns the simulation data for a given simulation name. Does not check aliases.
- `SimulationLoader.GetAllSimulationsData(): array<SimulationData>`
  - Returns the simulation data for *all* simulations.

### Properties

- `SimulationLoader.CurrentSimulation: string`
  - The name of the currently-running simulation, or an empty string if there is none.
- `SimulationLoader.SimulationContainer: Model`
  - The simulation container Model.
- `SimulationLoader.Simulations: array<Simulation>`
  - The list of simulations that the loader can use.
- `SimulationLoader.AliasMap: dictionary<string, string>`
  - A map of aliases and the simulation name they correlate to.

- `SimulationLoader.SimulationIsLoaded: boolean`
  - If a simulation is currently loaded.
- `SimulationLoader.IsWorking: boolean`
  - If a simulation is currently (un)loading a simulation.
