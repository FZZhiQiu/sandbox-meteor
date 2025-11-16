package com.sandbox.radar.ui;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.graphics.Color;
import android.view.Gravity;

public class DashboardView extends LinearLayout {
    private TextView rainfallLabel;
    private TextView resourceLabel;
    private TextView statusLabel;
    
    public DashboardView(Context context) {
        super(context);
        init();
    }
    
    public DashboardView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }
    
    private void init() {
        setOrientation(LinearLayout.HORIZONTAL);
        setBackgroundColor(Color.parseColor("#000000")); // 纯黑色背景
        setPadding(16, 16, 16, 16);
        
        // 降雨量标签
        rainfallLabel = new TextView(getContext());
        rainfallLabel.setText("降雨量: 0.00 mm/h");
        rainfallLabel.setTextColor(Color.WHITE); // 纯白色文字
        rainfallLabel.setGravity(Gravity.CENTER);
        
        // 资源标签
        resourceLabel = new TextView(getContext());
        resourceLabel.setText("资源: 100");
        resourceLabel.setTextColor(Color.WHITE); // 纯白色文字
        resourceLabel.setGravity(Gravity.CENTER);
        
        // 状态标签
        statusLabel = new TextView(getContext());
        statusLabel.setText("状态: 正常");
        statusLabel.setTextColor(Color.WHITE); // 纯白色文字
        statusLabel.setGravity(Gravity.CENTER);
        
        // 添加视图到布局
        LayoutParams params = new LayoutParams(
            0,
            LayoutParams.WRAP_CONTENT,
            1.0f
        );
        params.setMargins(8, 0, 8, 0);
        
        addView(rainfallLabel, params);
        addView(resourceLabel, params);
        addView(statusLabel, params);
    }
    
    public void updateRainfall(float rainfall) {
        rainfallLabel.setText(String.format("降雨量: %.2f mm/h", rainfall));
    }
    
    public void updateResources(int resources) {
        resourceLabel.setText(String.format("资源: %d", resources));
    }
    
    public void updateStatus(String status) {
        statusLabel.setText(String.format("状态: %s", status));
    }
}