#include "jni_interface.h"
#include "lib/meteor_core.h"
#include "lib/ui_interface.h"

#include <iostream>
#include <memory>

// 全局模拟核心实例
static std::unique_ptr<sandbox_radar::MeteorCore> g_meteor_core;

// JNI接口实现
JNIEXPORT void JNICALL Java_com_sandbox_radar_SimulationController_nativeInit(JNIEnv *env, jobject thiz) {
    // 初始化模拟核心
    g_meteor_core = std::make_unique<sandbox_radar::MeteorCore>();
    g_meteor_core->Initialize();
    
    std::cout << "MeteorCore initialized via JNI" << std::endl;
}

JNIEXPORT void JNICALL Java_com_sandbox_radar_SimulationController_nativeAddMoistureInjection(
    JNIEnv *env, jobject thiz, jfloat x, jfloat y, jfloat z, jfloat intensity, jfloat lift_height) {
    if (g_meteor_core) {
        // 通过UI接口添加湿气注入
        sandbox_radar::UIInterface* ui_interface = g_meteor_core->GetUIInterface();
        if (ui_interface) {
            ui_interface->AddMoistureInjection(x, y, z, intensity, lift_height);
        }
    }
}

JNIEXPORT void JNICALL Java_com_sandbox_radar_SimulationController_nativeUpdate(
    JNIEnv *env, jobject thiz, jfloat delta_time) {
    if (g_meteor_core) {
        // 运行一个模拟步骤
        g_meteor_core->Step();
    }
}

JNIEXPORT jfloat JNICALL Java_com_sandbox_radar_SimulationController_nativeGetRainfall(
    JNIEnv *env, jobject thiz) {
    if (g_meteor_core) {
        sandbox_radar::UIInterface* ui_interface = g_meteor_core->GetUIInterface();
        if (ui_interface) {
            return ui_interface->GetCurrentRainfall();
        }
    }
    return 0.0f;
}

JNIEXPORT jint JNICALL Java_com_sandbox_radar_SimulationController_nativeGetResources(
    JNIEnv *env, jobject thiz) {
    if (g_meteor_core) {
        sandbox_radar::UIInterface* ui_interface = g_meteor_core->GetUIInterface();
        if (ui_interface) {
            return ui_interface->GetResources();
        }
    }
    return 100;
}

JNIEXPORT jstring JNICALL Java_com_sandbox_radar_SimulationController_nativeGetStatus(
    JNIEnv *env, jobject thiz) {
    if (g_meteor_core) {
        sandbox_radar::UIInterface* ui_interface = g_meteor_core->GetUIInterface();
        if (ui_interface) {
            const char* status = ui_interface->GetStatus();
            return env->NewStringUTF(status);
        }
    }
    return env->NewStringUTF("未初始化");
}

JNIEXPORT jboolean JNICALL Java_com_sandbox_radar_SimulationController_nativeIsEmergency(
    JNIEnv *env, jobject thiz) {
    if (g_meteor_core) {
        sandbox_radar::UIInterface* ui_interface = g_meteor_core->GetUIInterface();
        if (ui_interface) {
            return ui_interface->IsEmergency();
        }
    }
    return JNI_FALSE;
}