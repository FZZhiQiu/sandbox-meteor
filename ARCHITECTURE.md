# 系统架构图

```mermaid
graph TB
    subgraph "客户端层"
        A[Android App] 
        B[Web Visualizer]
        C[Desktop Client]
    end
    
    subgraph "接口层"
        D[JNI Interface]
        E[Web API]
        F[Native Interface]
    end
    
    subgraph "核心引擎层"
        G[MeteorCore主模块]
        H[SimLoop - 3s周期]
        I[RenderLoop - 60FPS]
        J[FieldInterpolator]
        K[AgentInterpolator]
        L[AudioInterpolator]
    end
    
    subgraph "物理模拟层"
        M[Microphysics Module]
        N[Dynamics Module]
        O[Radiation Module]
        P[Electrification Module]
    end
    
    subgraph "AI增强层"
        Q[AI Nowcast]
        R[GPU Acceleration]
        S[Storyline Mode]
        T[Counterfactual Analysis]
    end
    
    subgraph "渲染层"
        U[Volume Renderer]
        V[3D Visualization]
        W[WebGL Engine]
    end
    
    A --> D
    B --> E
    C --> F
    
    D --> G
    E --> G
    F --> G
    
    G --> H
    G --> I
    H --> J
    H --> K
    H --> L
    I --> J
    I --> K
    I --> L
    
    G --> M
    G --> N
    G --> O
    G --> P
    
    G --> Q
    G --> R
    G --> S
    G --> T
    
    I --> U
    U --> V
    V --> W
```

# 类图

```mermaid
classDiagram
    class MeteorCore {
        +Initialize()
        +Step()
        +GetGrid()
        +GetSimTime()
    }
    
    class SimLoop {
        -MeteorCore* meteor_core
        -std::thread sim_thread
        -std::atomic<bool> running
        +Start()
        +Stop()
        +GetSimTime()
        +GetGridData()
        +HasNewData()
    }
    
    class RenderLoop {
        -SimLoop* sim_loop
        -std::thread render_thread
        -std::atomic<bool> running
        -FieldInterpolator field_interpolator
        +Start()
        +Stop()
        +GetFrameTime()
        +IsRendering()
    }
    
    class FieldInterpolator {
        +Interpolate()
        +InterpolateField()
        +Lerp()
    }
    
    class AgentInterpolator {
        +InterpolateAgents()
        +InterpolateStates()
        +Lerp()
    }
    
    class AudioInterpolator {
        +InterpolateAudioParams()
        +InterpolateAudioPositions()
        +Lerp()
    }
    
    class SimulationController {
        +nativeInit()
        +nativeAddMoistureInjection()
        +nativeUpdate()
        +nativeGetRainfall()
        +nativeGetResources()
        +nativeGetStatus()
        +nativeIsEmergency()
    }
    
    MeteorCore ||--|| SimLoop : uses
    SimLoop ||--|| RenderLoop : communicates_with
    SimLoop ||--|| FieldInterpolator : uses
    SimLoop ||--|| AgentInterpolator : uses
    SimLoop ||--|| AudioInterpolator : uses
    RenderLoop ||--|| FieldInterpolator : uses
    RenderLoop ||--|| AgentInterpolator : uses
    RenderLoop ||--|| AudioInterpolator : uses
    SimulationController ||--|| MeteorCore : jni_interface
```

# C++ 调用链图

```mermaid
sequenceDiagram
    participant App as Android App
    participant JNI as JNI Interface
    participant Core as MeteorCore
    participant Sim as SimLoop
    participant Render as RenderLoop
    participant Interp as Interpolator
    
    App->>JNI: nativeInit()
    JNI->>Core: Initialize()
    Core->>Sim: Start()
    Core->>Render: Start()
    
    loop Simulation Cycle
        Sim->>Core: Step()
        Core->>Interp: Interpolate fields
        Sim->>Sim: Wait 3s
    end
    
    loop Render Cycle
        Render->>Interp: Interpolate for frame time
        Render->>App: Render frame (60 FPS)
    end
    
    App->>JNI: nativeGetRainfall()
    JNI->>Core: GetRainfall()
    Core->>App: Return value
```

# 渲染管线图

```mermaid
graph LR
    A[SimLoop Data] --> B[FieldInterpolator]
    B --> C[Interpolated Grid Data]
    C --> D[VolumeRenderer]
    D --> E[3D Volume Mesh]
    E --> F[WebGL/Shaders]
    F --> G[Screen Output]
    
    H[RenderLoop] --> I[Timing Control]
    I --> D
    I --> E
    I --> F
    
    J[User Input] --> K[Interaction Handler]
    K --> B
    K --> D
```

# 模拟循环图

```mermaid
flowchart TD
    Start([开始]) --> Init{初始化}
    Init --> SimStart[启动SimLoop]
    Init --> RenderStart[启动RenderLoop]
    
    SimStart --> SimWait[等待3秒]
    SimWait --> SimStep[执行模拟步骤]
    SimStep --> UpdateGrid[更新网格数据]
    UpdateGrid --> SimWait
    
    RenderStart --> RenderFrame[渲染一帧]
    RenderFrame --> GetInterpData[获取插值数据]
    GetInterpData --> InterpData[插值计算]
    InterpData --> RenderToScreen[渲染到屏幕]
    RenderToScreen --> CheckRunning{仍在运行?}
    CheckRunning -->|是| RenderFrame
    CheckRunning -->|否| End([结束])
    
    SimStep -.-> GetInterpData
    UpdateGrid -.-> InterpData
```