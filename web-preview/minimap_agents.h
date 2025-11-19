#ifndef MINIMAP_AGENTS_H
#define MINIMAP_AGENTS_H

#include <cstdint>

// Agent 结构 (简化版，用于接口定义)
struct Agent {
    float x, y, z;        // 世界坐标
    int profession_id;    // 职业ID
    bool active;          // 是否活跃
    
    Agent() : x(0), y(0), z(0), profession_id(0), active(false) {}
    Agent(float _x, float _y, float _z, int _pid, bool _active) 
        : x(_x), y(_y), z(_z), profession_id(_pid), active(_active) {}
};

// AgentManager 模拟结构 (简化版，用于接口定义)
struct AgentManager {
    Agent* agents;        // 代理人数组
    int num_agents;       // 代理人数量
    static const int MAX_AGENTS = 4096;  // 最大代理人数量
    
    AgentManager() : agents(nullptr), num_agents(0) {}
    AgentManager(Agent* a, int n) : agents(a), num_agents(n) {}
};

// 核心函数：更新代理人 MiniMap 掩码
void agents_minimap(const AgentManager& am, uint8_t* out_mask);

#endif // MINIMAP_AGENTS_H