package com.sandbox.radar.ui;

import android.content.Context;
import android.util.AttributeSet;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.Button;
import android.widget.SeekBar;
import android.widget.TextView;
import android.graphics.Color;
import android.view.Gravity;

public class ToolbarView extends LinearLayout {
    private Button injectButton;
    private SeekBar intensitySeekBar;
    private SeekBar liftHeightSeekBar;
    private TextView intensityLabel;
    private TextView liftHeightLabel;
    private OnInjectionAddedListener listener;
    
    public interface OnInjectionAddedListener {
        void onInjectionAdded(float intensity, float liftHeight);
    }
    
    public ToolbarView(Context context) {
        super(context);
        init();
    }
    
    public ToolbarView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }
    
    private void init() {
        setOrientation(LinearLayout.VERTICAL);
        setBackgroundColor(Color.parseColor("#000000")); // 纯黑色背景
        setPadding(16, 16, 16, 16);
        
        // 添加湿气注入按钮
        injectButton = new Button(getContext());
        injectButton.setText("注入湿气");
        injectButton.setBackgroundColor(Color.parseColor("#FFFFFF")); // 纯白色按钮
        injectButton.setTextColor(Color.parseColor("#000000")); // 纯黑色文字
        injectButton.setOnClickListener(new OnClickListener() {
            @Override
            public void onClick(View v) {
                if (listener != null) {
                    float intensity = intensitySeekBar.getProgress() / 100.0f;
                    float liftHeight = liftHeightSeekBar.getProgress() / 10.0f; // 0-15 km
                    listener.onInjectionAdded(intensity, liftHeight);
                }
            }
        });
        
        // 强度滑条标签
        intensityLabel = new TextView(getContext());
        intensityLabel.setText("强度: 0.50 kg/s");
        intensityLabel.setTextColor(Color.WHITE); // 纯白色文字
        intensityLabel.setGravity(Gravity.CENTER);
        
        // 强度滑条
        intensitySeekBar = new SeekBar(getContext());
        intensitySeekBar.setMax(100);
        intensitySeekBar.setProgress(50); // 默认50%
        intensitySeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                intensityLabel.setText(String.format("强度: %.2f kg/s", progress / 100.0f));
            }
            
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}
            
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });
        
        // 抬升高度滑条标签
        liftHeightLabel = new TextView(getContext());
        liftHeightLabel.setText("抬升高度: 0.0 km");
        liftHeightLabel.setTextColor(Color.WHITE); // 纯白色文字
        liftHeightLabel.setGravity(Gravity.CENTER);
        
        // 抬升高度滑条
        liftHeightSeekBar = new SeekBar(getContext());
        liftHeightSeekBar.setMax(150); // 0-15 km，每0.1 km一个单位
        liftHeightSeekBar.setProgress(0); // 默认0 km
        liftHeightSeekBar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
            @Override
            public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
                liftHeightLabel.setText(String.format("抬升高度: %.1f km", progress / 10.0f));
            }
            
            @Override
            public void onStartTrackingTouch(SeekBar seekBar) {}
            
            @Override
            public void onStopTrackingTouch(SeekBar seekBar) {}
        });
        
        // 添加视图到布局
        LayoutParams params = new LayoutParams(
            LayoutParams.MATCH_PARENT,
            LayoutParams.WRAP_CONTENT
        );
        params.setMargins(0, 0, 0, 16);
        
        addView(injectButton, params);
        addView(intensityLabel, params);
        addView(intensitySeekBar, params);
        addView(liftHeightLabel, params);
        addView(liftHeightSeekBar, params);
    }
    
    public void setOnInjectionAddedListener(OnInjectionAddedListener listener) {
        this.listener = listener;
    }
}