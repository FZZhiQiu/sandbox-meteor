#include "minimap_agents.h"
#include <emscripten/bind.h>
#include <emscripten.h>

// 使用EMSCRIPTEN_BINDINGS导出C++函数到JavaScript
EMSCRIPTEN_BINDINGS(minimap_agents_module) {
    emscripten::function("agents_minimap", &agents_minimap);
    
    // 绑定Agent结构
    emscripten::value_object<Agent>("Agent")
        .field("x", &Agent::x)
        .field("y", &Agent::y)
        .field("profession_id", &Agent::profession_id)
        .field("active", &Agent::active);
    
    // 绑定AgentManager结构
    emscripten::value_object<AgentManager>("AgentManager")
        .field("agents", &AgentManager::agents)
        .field("num_agents", &AgentManager::num_agents);
    
    // 绑定数组访问
    emscripten::register_vector<Agent>("VectorAgent");
}

// C风格接口，用于JavaScript调用
extern "C" {
    // 初始化代理人管理器
    EMSCRIPTEN_KEEPALIVE
    AgentManager* create_agent_manager() {
        AgentManager* mgr = new AgentManager();
        mgr->num_agents = 0;
        return mgr;
    }
    
    EMSCRIPTEN_KEEPALIVE
    void destroy_agent_manager(AgentManager* mgr) {
        delete mgr;
    }
    
    // 获取代理人数量
    EMSCRIPTEN_KEEPALIVE
    int get_num_agents(AgentManager* mgr) {
        return mgr->num_agents;
    }
    
    // 设置代理人数据
    EMSCRIPTEN_KEEPALIVE
    void set_agent_data(AgentManager* mgr, float* x_coords, float* y_coords, int* profession_ids, int count) {
        mgr->num_agents = (count > 4096) ? 4096 : count;
        for (int i = 0; i < mgr->num_agents; i++) {
            mgr->agents[i].x = x_coords[i];
            mgr->agents[i].y = y_coords[i];
            mgr->agents[i].profession_id = profession_ids[i] % 256;  // 限制在0-255范围内
            mgr->agents[i].active = true;
        }
    }
    
    // 更新代理人MiniMap
    EMSCRIPTEN_KEEPALIVE
    void agents_minimap_wasm(AgentManager* mgr, uint8_t* out_agents) {
        agents_minimap(*mgr, out_agents);
    }
}