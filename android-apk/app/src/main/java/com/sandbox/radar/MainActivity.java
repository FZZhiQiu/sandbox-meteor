package com.sandbox.radar;

import android.app.Activity;
import android.os.Bundle;
import android.widget.TextView;
import android.util.Log;
import android.widget.FrameLayout;
import android.view.ViewGroup;
import com.sandbox.radar.ui.ToolbarView;
import com.sandbox.radar.ui.DashboardView;

public class MainActivity extends Activity {
    private static final String TAG = "SandboxRadar";
    
    private ToolbarView toolbarView;
    private DashboardView dashboardView;
    private SimulationController simulationController;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // 创建主布局容器
        FrameLayout mainLayout = new FrameLayout(this);
        
        // 创建游戏视图（占位符）
        TextView gameView = new TextView(this);
        gameView.setText("Sandbox Radar Meteor Agent v3.2.0\n\n60 FPS Decoupled Simulation Running\n\nSim: 3s steps | Render: 60 Hz\n\n[3D Meteor Simulation View]");
        gameView.setBackgroundColor(android.graphics.Color.parseColor("#FF000000")); // 纯黑色背景
        gameView.setTextColor(android.graphics.Color.WHITE); // 纯白色文字
        gameView.setPadding(32, 32, 32, 32);
        
        FrameLayout.LayoutParams gameParams = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        );
        gameParams.setMargins(0, 120, 0, 80); // 为工具栏和仪表板留出空间
        
        mainLayout.addView(gameView, gameParams);
        
        // 创建并添加工具栏
        toolbarView = new ToolbarView(this);
        FrameLayout.LayoutParams toolbarParams = new FrameLayout.LayoutParams(
            300, // 宽度300dp
            ViewGroup.LayoutParams.WRAP_CONTENT
        );
        toolbarParams.setMargins(0, 20, 20, 0); // 右上角位置
        toolbarParams.gravity = FrameLayout.END | FrameLayout.TOP;
        
        mainLayout.addView(toolbarView, toolbarParams);
        
        // 创建并添加仪表板
        dashboardView = new DashboardView(this);
        FrameLayout.LayoutParams dashboardParams = new FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            100 // 高度100dp
        );
        dashboardParams.gravity = FrameLayout.BOTTOM;
        
        mainLayout.addView(dashboardView, dashboardParams);
        
        // 设置主布局
        setContentView(mainLayout);
        
        // 初始化模拟控制器
        simulationController = new SimulationController(dashboardView);
        
        // 设置工具栏事件监听器
        toolbarView.setOnInjectionAddedListener(new ToolbarView.OnInjectionAddedListener() {
            @Override
            public void onInjectionAdded(float intensity, float liftHeight) {
                simulationController.addMoistureInjection(intensity, liftHeight);
            }
        });
        
        // 更新仪表板初始数据
        simulationController.updateRainfall(0.0f);
        simulationController.updateResources(100);
        
        Log.i(TAG, "Sandbox Radar 60 FPS started successfully");
    }
}