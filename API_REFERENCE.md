# Sandbox Meteor API Reference

## Core Classes

### MeteorCore
The main meteorological simulation class that orchestrates all physics processes.

#### Public Methods
- `MeteorCore()` - Constructor
- `~MeteorCore()` - Destructor
- `void Initialize()` - Initialize the simulation system
- `void Step()` - Execute one simulation step (3 seconds)
- `double GetSimTime() const` - Get current simulation time
- `Grid& GetGrid()` - Get reference to the simulation grid
- `UIInterface* GetUIInterface()` - Get UI interface for interaction

#### Key Features
- Manages all meteorological physics processes
- Coordinates microphysics, dynamics, and thermodynamics
- Handles data assimilation and radar simulation
- Interfaces with UI and external systems

### SimLoop
Simulation loop running at 3-second intervals.

#### Public Methods
- `SimLoop()` - Constructor
- `~SimLoop()` - Destructor
- `void Start()` - Start the simulation loop
- `void Stop()` - Stop the simulation loop
- `double GetSimTime() const` - Get current simulation time
- `void GetGridData(float* output_data) const` - Get current grid data
- `bool HasNewData() const` - Check for new simulation data

#### Key Features
- Runs physics simulation in separate thread
- Manages simulation timing (3 seconds per step)
- Provides thread-safe access to simulation data

### RenderLoop
Rendering loop running at 60 FPS.

#### Public Methods
- `RenderLoop(SimLoop* sim_loop)` - Constructor with simulation loop reference
- `~RenderLoop()` - Destructor
- `void Start()` - Start the rendering loop
- `void Stop()` - Stop the rendering loop
- `double GetFrameTime() const` - Get last frame time in ms
- `bool IsRendering() const` - Check if rendering is active

#### Key Features
- Runs rendering at 60 FPS in separate thread
- Performs interpolation between simulation steps
- Manages GPU resources and rendering pipeline

## Interpolation System

### FieldInterpolator
Handles interpolation of field data between simulation steps.

#### Public Methods
- `FieldInterpolator()` - Constructor
- `~FieldInterpolator()` - Destructor
- `void Interpolate(const float* start_data, const float* end_data, float* output_data, float t, int num_elements)` - Linear interpolation
- `void InterpolateField(const float* start_field, const float* end_field, float* output_field, float t, int num_points)` - Field-specific interpolation
- `float Lerp(float start, float end, float t)` - Linear interpolation helper

#### Key Features
- Smooth interpolation between simulation states
- GPU-accelerated implementation available
- Support for large field data interpolation

## Grid System

### Grid
Manages the 3D simulation grid.

#### Constants
- `static constexpr int NX` - Grid size in X direction
- `static constexpr int NY` - Grid size in Y direction
- `static constexpr int NZ` - Grid size in Z direction
- `static constexpr int NVARS` - Number of variables per grid point
- `static constexpr int DT` - Time step (3.0f seconds)

#### Field Indices
- `QVAPOR` - Water vapor mixing ratio
- `QCLOUD` - Cloud water mixing ratio
- `QRAIN` - Rain water mixing ratio
- `QICE` - Ice mixing ratio
- `QSNOW` - Snow mixing ratio
- `QGRAUP` - Graupel mixing ratio
- `QHAIL` - Hail mixing ratio
- `U_WIND` - U-component of wind (east-west)
- `V_WIND` - V-component of wind (north-south)
- `W_WIND` - W-component of wind (vertical)
- `TEMP` - Temperature
- `PRESSURE` - Pressure
- `DENSITY` - Air density

#### Public Methods
- `Grid()` - Constructor
- `~Grid()` - Destructor
- `void Initialize()` - Initialize grid with default values
- `float* GetField(int field_idx)` - Get pointer to specific field
- `const float* GetField(int field_idx) const` - Get const pointer to field
- `float GetCell(int field_idx, int x, int y, int z)` - Get value at grid point
- `void SetCell(int field_idx, int x, int y, int z, float value)` - Set value at grid point

## Agent System

### AgentManager
Manages autonomous agents that interact with the simulation.

#### Public Methods
- `AgentManager()` - Constructor
- `~AgentManager()` - Destructor
- `void Initialize(int max_agents)` - Initialize agent system
- `void AddAgent(const Agent& agent)` - Add new agent
- `void ProcessAgents(float dt)` - Process all agents
- `void UpdateAgentStates()` - Update agent states
- `std::vector<Agent>& GetAgents()` - Get reference to agents

### Agent
Base class for simulation agents.

#### Properties
- `position` - 3D position in grid space
- `velocity` - 3D velocity vector
- `type` - Agent type identifier
- `state` - Current state of the agent
- `task` - Current assigned task
- `energy` - Energy level for autonomous operation

## UI Interface

### UIInterface
Interface between simulation and UI components.

#### Public Methods
- `UIInterface()` - Constructor
- `~UIInterface()` - Destructor
- `void Initialize()` - Initialize the interface
- `void AddMoistureInjection(float x, float y, float z, float intensity, float lift_height)` - Add moisture injection
- `float GetRainfallAt(int x, int y) const` - Get rainfall at grid location
- `int GetAgentCount() const` - Get number of active agents
- `int GetResources() const` - Get available resources
- `void SetGrid(Grid* grid)` - Set grid reference
- `void SetMicro(Micro* micro)` - Set microphysics reference
- `void SetAgentManager(AgentManager* agent_manager)` - Set agent manager reference
- `void UpdateUIData()` - Update UI data
- `float GetCurrentRainfall() const` - Get current rainfall
- `int GetCurrentResources() const` - Get current resources
- `bool IsEmergency() const` - Check for emergency state
- `const char* GetStatus() const` - Get status string

## Storm Classification

### StormType Enum
Enumeration of different storm types.

#### Values
- `NONE` - No storm
- `WEAK` - Weak storm
- `MODERATE` - Moderate storm
- `STRONG` - Strong storm
- `SEVERE` - Severe storm
- `CUMULUS` - Cumulus cloud
- `THUNDERSTORM` - Thunderstorm
- `SUPERCELL` - Supercell thunderstorm
- `HAIL` - Hail-producing storm
- `TORNADO` - Tornado
- `STRATIFORM` - Stratiform precipitation
- `CONVECTIVE` - Convective storm
- `SQUALL` - Squall line
- `TYPHOON` - Typhoon
- `HURRICANE` - Hurricane
- `TOWERING_CU` - Towering cumulus
- `ORDINARY` - Ordinary thunderstorm
- `TOR_SUPERC` - Tornadic supercell
- `SUPERCCELL` - Supercell (alternative)
- `QLCS` - Quasi-linear convective system
- `LINE` - Linear storm system
- `MC` - Mesoscale convective system

## Radar Simulation

### Radar Simulator Components
The system includes multiple radar simulation components:

#### RadarSimulator
- Simulates basic radar returns
- Supports multiple elevation angles
- Implements beam broadening effects

#### VolumeRadar
- 3D volume radar simulation
- Multi-resolution capabilities
- GPU-accelerated processing

#### AdvancedRadar
- Advanced radar features
- Multiple scan strategies
- Enhanced resolution modes

## Configuration Parameters

### Global Constants
- `DT = 3.0f` - Simulation time step (3 seconds)
- `GRID_RESOLUTION = 0.01f` - Grid resolution (1 cm)
- `MAX_SIMULATION_TIME = 1000000` - Maximum simulation steps
- `TARGET_FPS = 60` - Target rendering frame rate

### Physical Constants
- Standard atmospheric values
- Microphysics parameters
- Radar system parameters
- Material properties for various particles