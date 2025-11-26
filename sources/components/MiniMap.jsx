import React, { useState, useEffect, useRef } from 'react';
import { View, StyleSheet, PanResponder, Dimensions, TouchableOpacity } from 'react-native';
import { GLView } from 'expo-gl';
import { PinchGestureHandler, State } from 'react-native-gesture-handler';

const { width: screenWidth, height: screenHeight } = Dimensions.get('window');

const MiniMap = ({ style, onRegionSelect }) => {
  const [position, setPosition] = useState({ 
    x: screenWidth - 270, // Start at right bottom with margin
    y: screenHeight - 300 
  });
  
  const [isVisible, setIsVisible] = useState(true);
  const [mapData, setMapData] = useState(null);
  const [scale, setScale] = useState(1);
  const [lastScale, setLastScale] = useState(1);
  
  // 手势放大镜功能 - 双指外划跳转主摄像机
  const handleGestureEvent = (event) => {
    if (event.nativeEvent.state === State.BEGAN) {
      setLastScale(scale);
    } else if (event.nativeEvent.state === State.ACTIVE) {
      const newScale = lastScale * event.nativeEvent.scale;
      setScale(newScale);
      
      // 如果放大倍数超过阈值，触发主摄像机跳转
      if (newScale > 2.0 && onRegionSelect) {
        // 计算点击的经纬度坐标并通知主视图
        const centerX = position.x + 128; // MiniMap中心X
        const centerY = position.y + 128; // MiniMap中心Y
        
        // 触发主摄像机跳转到对应区域
        onRegionSelect(centerX, centerY, newScale);
      }
    } else if (event.nativeEvent.state === State.END) {
      // 重置缩放
      setScale(1);
      setLastScale(1);
    }
  };

  const panResponder = useRef(
    PanResponder.create({
      onStartShouldSetPanResponder: () => true,
      onMoveShouldSetPanResponder: () => true,
      onPanResponderMove: (evt, gestureState) => {
        const newX = position.x + gestureState.dx;
        const newY = position.y + gestureState.dy;
        
        // Boundary checks
        const boundedX = Math.max(10, Math.min(screenWidth - 266, newX));
        const boundedY = Math.max(10, Math.min(screenHeight - 266, newY));
        
        setPosition({ x: boundedX, y: boundedY });
      },
      onPanResponderRelease: () => {},
    })
  ).current;

  // 击中测试：将屏幕坐标转换为网格坐标
  const handleMapTouch = (event) => {
    const { locationX, locationY } = event.nativeEvent;
    // 将触摸坐标转换为相对于MiniMap的坐标
    const relativeX = locationX;
    const relativeY = locationY;
    
    // 转换为网格坐标 (假设MiniMap代表整个模拟区域)
    const gridX = (relativeX / 256) * 200; // 假设网格是200x200
    const gridY = (relativeY / 256) * 200;
    
    // 如果有回调函数，通知主视图跳转到该区域
    if (onRegionSelect) {
      onRegionSelect(gridX, gridY, 1.0); // 直接跳转，不放大
    }
  };

  // Function to handle GL context and render the minimap
  const onContextCreate = async (gl) => {
    const { drawingBufferWidth: width, drawingBufferHeight: height } = gl;
    
    // Initialize WebGL for minimap rendering
    const vertexShaderSource = `
      attribute vec2 a_position;
      attribute vec2 a_texCoord;
      varying vec2 v_texCoord;
      
      void main() {
        gl_Position = vec4(a_position, 0.0, 1.0);
        v_texCoord = a_texCoord;
      }
    `;
    
    const fragmentShaderSource = `
      precision mediump float;
      varying vec2 v_texCoord;
      uniform sampler2D u_texture;
      uniform float u_contrast;
      uniform float u_brightness;
      
      void main() {
        vec4 color = texture2D(u_texture, v_texCoord);
        gl_FragColor = color * u_contrast + u_brightness;
      }
    `;
    
    // Compile shaders and set up program (simplified - actual implementation would be more complex)
    // The actual texture would be provided by the native side via shared EGL texture
    
    // For now, render a simple test pattern
    const buffer = gl.createBuffer();
    gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
    
    // Define a quad (2 triangles) to fill the view
    const vertices = new Float32Array([
      -1, -1, 0, 0,  // Bottom-left
       1, -1, 1, 0,  // Bottom-right
      -1,  1, 0, 1,  // Top-left
       1,  1, 1, 1   // Top-right
    ]);
    
    gl.bufferData(gl.ARRAY_BUFFER, vertices, gl.STATIC_DRAW);
    
    gl.viewport(0, 0, width, height);
    gl.clearColor(0.1, 0.1, 0.1, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);
    
    // In a real implementation, we would bind the shared texture here
    // and render it with the appropriate shader
  };

  const toggleVisibility = () => {
    setIsVisible(!isVisible);
  };

  if (!isVisible) {
    return (
      <View
        style={[
          styles.floatingButton,
          { left: position.x, top: position.y }
        ]}
        {...panResponder.panHandlers}
        onTouchEnd={toggleVisibility}
      >
        <View style={styles.minimapIcon} />
      </View>
    );
  }

  return (
    <PinchGestureHandler onHandlerStateChange={handleGestureEvent} onGestureEvent={handleGestureEvent}>
      <View
        style={[
          styles.container,
          { 
            left: position.x, 
            top: position.y,
            transform: [{ scale: scale }]
          },
          style
        ]}
        {...panResponder.panHandlers}
        onTouchEnd={handleMapTouch}
      >
        <GLView
          style={styles.minimap}
          onContextCreate={onContextCreate}
        />
        <View style={styles.controls}>
          <View style={styles.toggleButton} onTouchEnd={toggleVisibility}>
            <View style={styles.minimizeIcon} />
          </View>
        </View>
      </View>
    </PinchGestureHandler>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    width: 256,
    height: 256,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    overflow: 'hidden',
    zIndex: 1000,
  },
  minimap: {
    flex: 1,
  },
  floatingButton: {
    position: 'absolute',
    width: 32,
    height: 32,
    backgroundColor: 'rgba(0, 0, 0, 0.7)',
    borderRadius: 16,
    justifyContent: 'center',
    alignItems: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.3)',
    zIndex: 1000,
  },
  minimapIcon: {
    width: 20,
    height: 20,
    backgroundColor: '#4A90E2',
    borderRadius: 2,
  },
  controls: {
    position: 'absolute',
    top: 4,
    right: 4,
  },
  toggleButton: {
    width: 20,
    height: 20,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    borderRadius: 10,
    justifyContent: 'center',
    alignItems: 'center',
  },
  minimizeIcon: {
    width: 10,
    height: 2,
    backgroundColor: 'white',
  },
});

export default MiniMap;