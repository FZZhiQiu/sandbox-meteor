package com.sandbox.radar;

public class SimulationController {
    // 加载原生库
    static {
        System.loadLibrary("sandbox_radar");
    }

    // 原生方法声明
    public static native void nativeInit();
    public static native void nativeAddMoistureInjection(float x, float y, float z, float intensity, float lift_height);
    public static native void nativeUpdate(float delta_time);
    public static native float nativeGetRainfall();
    public static native int nativeGetResources();
    public static native String nativeGetStatus();
    public static native boolean nativeIsEmergency();
}