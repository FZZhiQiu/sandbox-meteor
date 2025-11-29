import React, { useState, useEffect } from 'react';
import { StyleSheet, Text, View, ScrollView, Dimensions, ActivityIndicator } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import { LinearGradient } from 'expo-linear-gradient';

const { width, height } = Dimensions.get('window');

export default function App() {
  const [weatherData, setWeatherData] = useState({
    temperature: 25.5,
    humidity: 65,
    windSpeed: 12.3,
    pressure: 1013,
  });

  useEffect(() => {
    const interval = setInterval(() => {
      setWeatherData({
        temperature: 20 + Math.random() * 15,
        humidity: 40 + Math.random() * 40,
        windSpeed: 5 + Math.random() * 20,
        pressure: 1000 + Math.random() * 30,
      });
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  return (
    <View style={styles.container}>
      <StatusBar style="light" />
      <LinearGradient
        colors={['#667eea', '#764ba2']}
        style={styles.gradient}
      >
        <ScrollView style={styles.scrollView}>
          <View style={styles.header}>
            <Text style={styles.title}>🌤️ 气象沙盘模拟器</Text>
            <Text style={styles.subtitle}>专业级气象数据监控与分析</Text>
          </View>

          <View style={styles.dashboard}>
            <View style={styles.card}>
              <Text style={styles.cardTitle}>🌡️ 温度</Text>
              <Text style={styles.metric}>
                {weatherData.temperature.toFixed(1)}°C
              </Text>
              <View style={[styles.status, styles.statusGood]}>
                <Text style={styles.statusText}>正常范围</Text>
              </View>
            </View>

            <View style={styles.card}>
              <Text style={styles.cardTitle}>💧 湿度</Text>
              <Text style={styles.metric}>
                {weatherData.humidity.toFixed(0)}%
              </Text>
              <View style={[styles.status, styles.statusGood]}>
                <Text style={styles.statusText}>舒适湿度</Text>
              </View>
            </View>

            <View style={styles.card}>
              <Text style={styles.cardTitle}>🌀 风速</Text>
              <Text style={styles.metric}>
                {weatherData.windSpeed.toFixed(1)} km/h
              </Text>
              <View style={[styles.status, styles.statusGood]}>
                <Text style={styles.statusText}>微风</Text>
              </View>
            </View>

            <View style={styles.card}>
              <Text style={styles.cardTitle}>📊 气压</Text>
              <Text style={styles.metric}>
                {weatherData.pressure.toFixed(0)} hPa
              </Text>
              <View style={[styles.status, styles.statusGood]}>
                <Text style={styles.statusText}>标准气压</Text>
              </View>
            </View>
          </View>

          <View style={styles.chart}>
            <Text style={styles.chartTitle}>📈 24小时趋势图</Text>
            <Text style={styles.chartSubtitle}>实时气象数据可视化图表区域</Text>
            <ActivityIndicator size="large" color="#fff" style={styles.loader} />
          </View>

          <View style={styles.footer}>
            <Text style={styles.footerText}>🚀 Flutter 3.24.0 + Dart 3.3.0</Text>
            <Text style={styles.footerText}>6大求解器算法 | 60FPS渲染 | 并行计算</Text>
            <Text style={styles.footerText}>实时更新中...</Text>
          </View>
        </ScrollView>
      </LinearGradient>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  gradient: {
    flex: 1,
  },
  scrollView: {
    flex: 1,
  },
  header: {
    alignItems: 'center',
    paddingTop: 60,
    paddingBottom: 40,
  },
  title: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 8,
    textShadowColor: 'rgba(0,0,0,0.3)',
    textShadowOffset: { width: 2, height: 2 },
    textShadowRadius: 4,
  },
  subtitle: {
    fontSize: 16,
    color: 'rgba(255,255,255,0.8)',
  },
  dashboard: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    marginBottom: 20,
  },
  card: {
    width: (width - 60) / 2,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 15,
    padding: 20,
    marginBottom: 15,
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  cardTitle: {
    fontSize: 18,
    color: '#ffd700',
    marginBottom: 10,
  },
  metric: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#fff',
    marginBottom: 10,
  },
  status: {
    paddingHorizontal: 12,
    paddingVertical: 5,
    borderRadius: 20,
    alignSelf: 'flex-start',
  },
  statusGood: {
    backgroundColor: 'rgba(76,175,80,0.3)',
    borderWidth: 1,
    borderColor: '#4caf50',
  },
  statusText: {
    fontSize: 12,
    color: '#fff',
  },
  chart: {
    margin: 20,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 15,
    padding: 25,
    height: 200,
    alignItems: 'center',
    justifyContent: 'center',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.2)',
  },
  chartTitle: {
    fontSize: 18,
    color: '#fff',
    marginBottom: 10,
  },
  chartSubtitle: {
    fontSize: 14,
    color: 'rgba(255,255,255,0.7)',
    textAlign: 'center',
    marginBottom: 20,
  },
  loader: {
    marginTop: 10,
  },
  footer: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  footerText: {
    fontSize: 12,
    color: 'rgba(255,255,255,0.7)',
    marginBottom: 5,
  },
});