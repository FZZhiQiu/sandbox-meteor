#ifndef JNI_INTERFACE_H
#define JNI_INTERFACE_H

#include <jni.h>

// JNI 接口声明
extern "C" {
    // 初始化模拟核心
    JNIEXPORT void JNICALL Java_com_sandbox_radar_SimulationController_nativeInit(JNIEnv *env, jobject thiz);

    // 添加湿气注入干预
    JNIEXPORT void JNICALL Java_com_sandbox_radar_SimulationController_nativeAddMoistureInjection(
        JNIEnv *env, jobject thiz, jfloat x, jfloat y, jfloat z, jfloat intensity, jfloat lift_height);

    // 更新模拟
    JNIEXPORT void JNICALL Java_com_sandbox_radar_SimulationController_nativeUpdate(
        JNIEnv *env, jobject thiz, jfloat delta_time);

    // 获取降雨量
    JNIEXPORT jfloat JNICALL Java_com_sandbox_radar_SimulationController_nativeGetRainfall(
        JNIEnv *env, jobject thiz);

    // 获取资源
    JNIEXPORT jint JNICALL Java_com_sandbox_radar_SimulationController_nativeGetResources(
        JNIEnv *env, jobject thiz);

    // 获取状态
    JNIEXPORT jstring JNICALL Java_com_sandbox_radar_SimulationController_nativeGetStatus(
        JNIEnv *env, jobject thiz);

    // 检查是否为紧急状态
    JNIEXPORT jboolean JNICALL Java_com_sandbox_radar_SimulationController_nativeIsEmergency(
        JNIEnv *env, jobject thiz);
}

#endif // JNI_INTERFACE_H