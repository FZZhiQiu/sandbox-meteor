package com.sandbox.radar;

import android.util.Log;
import com.sandbox.radar.ui.DashboardView;

public class SimulationController {
    private static final String TAG = "SimulationController";
    
    private DashboardView dashboardView;
    
    // 加载本地库
    static {
        try {
            System.loadLibrary("sandbox_radar"); // 加载libsandbox_radar.so
        } catch (UnsatisfiedLinkError e) {
            Log.e(TAG, "无法加载本地库: " + e.getMessage());
        }
    }
    
    public SimulationController(DashboardView dashboardView) {
        this.dashboardView = dashboardView;
        // 初始化本地模拟核心
        nativeInit();
    }
    
    // 本地方法声明
    private native void nativeInit();
    private native void nativeAddMoistureInjection(float x, float y, float z, float intensity, float lift_height);
    private native void nativeUpdate(float deltaTime);
    private native float nativeGetRainfall();
    private native int nativeGetResources();
    private native String nativeGetStatus();
    private native boolean nativeIsEmergency();
    
    // 更新降雨量显示
    public void updateRainfall() {
        if (dashboardView != null) {
            float rainfall = nativeGetRainfall();
            dashboardView.updateRainfall(rainfall);
            
            // 根据降雨量更新状态
            boolean isEmergency = nativeIsEmergency();
            String status = nativeGetStatus();
            dashboardView.updateStatus(status);
        }
    }
    
    // 更新资源显示
    public void updateResources() {
        if (dashboardView != null) {
            int resources = nativeGetResources();
            dashboardView.updateResources(resources);
        }
    }
    
    // 处理湿气注入添加
    public void addMoistureInjection(float intensity, float liftHeight) {
        Log.d(TAG, "湿气注入添加，强度: " + intensity + ", 抬升高度: " + liftHeight);
        
        // 添加湿气注入到模拟核心 (位置设为网格中心)
        nativeAddMoistureInjection(0.5f, 0.5f, 0.5f, intensity, liftHeight);
        
        // 更新UI
        updateRainfall();
        updateResources();
    }
    
    // 模拟时间步进更新
    public void update(float deltaTime) {
        // 更新模拟核心
        nativeUpdate(deltaTime);
        
        // 更新UI
        updateRainfall();
        updateResources();
    }
}