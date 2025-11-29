package com.meteorological;

/**
 * 气象计算器类
 */
public class WeatherCalculator {
    
    /**
     * 计算露点温度
     * @param temperature 温度 (摄氏度)
     * @param humidity 相对湿度 (%)
     * @return 露点温度 (摄氏度)
     */
    public static double calculateDewPoint(double temperature, double humidity) {
        double a = 17.27;
        double b = 237.7;
        double alpha = ((a * temperature) / (b + temperature)) + Math.log(humidity / 100.0);
        double dewPoint = (b * alpha) / (a - alpha);
        return dewPoint;
    }
    
    /**
     * 计算热指数
     * @param temperature 温度 (摄氏度)
     * @param humidity 相对湿度 (%)
     * @return 热指数 (摄氏度)
     */
    public static double calculateHeatIndex(double temperature, double humidity) {
        // 简化的热指数计算
        double fahrenheit = temperature * 9.0 / 5.0 + 32.0;
        double hi = 0.5 * (fahrenheit + 61.0 + ((fahrenheit - 68.0) * 1.2) + (humidity * 0.094));
        return (hi - 32.0) * 5.0 / 9.0;
    }
    
    public static void main(String[] args) {
        double temp = 25.0;
        double humidity = 65.0;
        
        double dewPoint = calculateDewPoint(temp, humidity);
        double heatIndex = calculateHeatIndex(temp, humidity);
        
        System.out.println("气象计算结果:");
        System.out.println("温度: " + temp + "°C");
        System.out.println("湿度: " + humidity + "%");
        System.out.println("露点: " + String.format("%.2f", dewPoint) + "°C");
        System.out.println("热指数: " + String.format("%.2f", heatIndex) + "°C");
    }
}