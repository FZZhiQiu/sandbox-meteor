import 'dart:math' as math;

class MathUtils {
  // 线性插值
  static double lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }
  
  // 双线性插值
  static double bilinearInterpolation(
    double q00, double q01, double q10, double q11,
    double tx, double ty,
  ) {
    final a = lerp(q00, q10, tx);
    final b = lerp(q01, q11, tx);
    return lerp(a, b, ty);
  }
  
  // 三线性插值
  static double trilinearInterpolation(
    double c000, double c001, double c010, double c011,
    double c100, double c101, double c110, double c111,
    double tx, double ty, double tz,
  ) {
    final c00 = lerp(c000, c100, tx);
    final c01 = lerp(c001, c101, tx);
    final c10 = lerp(c010, c110, tx);
    final c11 = lerp(c011, c111, tx);
    
    final c0 = lerp(c00, c10, ty);
    final c1 = lerp(c01, c11, ty);
    
    return lerp(c0, c1, tz);
  }
  
  // 限制数值在指定范围内
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }
  
  // 计算两点间距离
  static double distance(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }
  
  // 计算三维距离
  static double distance3D(double x1, double y1, double z1, 
                           double x2, double y2, double z2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    final dz = z2 - z1;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }
  
  // 高斯函数
  static double gaussian(double x, double sigma) {
    return math.exp(-(x * x) / (2 * sigma * sigma));
  }
  
  // 二维高斯函数
  static double gaussian2D(double x, double y, double sigmaX, double sigmaY) {
    return math.exp(-(x * x) / (2 * sigmaX * sigmaX) 
                   - (y * y) / (2 * sigmaY * sigmaY));
  }
  
  // 梯度计算（中心差分）
  static double gradient(double left, double center, double right, double dx) {
    return (right - left) / (2 * dx);
  }
  
  // 拉普拉斯算子（五点差分格式）
  static double laplacian(double center, double left, double right, 
                         double top, double bottom, double dx) {
    return (left + right + top + bottom - 4 * center) / (dx * dx);
  }
  
  // 散度计算
  static double divergence(double dudx, double dvdy) {
    return dudx + dvdy;
  }
  
  // 涡度计算
  static double vorticity(double dudy, double dvdx) {
    return dvdx - dudy;
  }
  
  // 角度转弧度
  static double degToRad(double degrees) {
    return degrees * math.pi / 180.0;
  }
  
  // 弧度转角度
  static double radToDeg(double radians) {
    return radians * 180.0 / math.pi;
  }
  
  // 饱和水汽压（Magnus公式）
  static double saturationVaporPressure(double temperature) {
    // 温度单位：K，输出：Pa
    final tempCelsius = temperature - 273.15;
    if (tempCelsius >= 0) {
      return 610.78 * math.exp(17.27 * tempCelsius / (tempCelsius + 237.3));
    } else {
      return 610.78 * math.exp(21.875 * tempCelsius / (tempCelsius + 265.5));
    }
  }
  
  // 相对湿度
  static double relativeHumidity(double vaporPressure, double temperature) {
    final satPressure = saturationVaporPressure(temperature);
    return clamp(vaporPressure / satPressure * 100.0, 0.0, 100.0);
  }
  
  // 位温计算
  static double potentialTemperature(double temperature, double pressure) {
    final referencePressure = 100000.0; // 1000 hPa in Pa
    return temperature * math.pow(referencePressure / pressure, 0.286);
  }
  
  // 相当位温（简化版）
  static double equivalentPotentialTemperature(double temperature, double pressure, 
                                              double mixingRatio) {
    final theta = potentialTemperature(temperature, pressure);
    final lv = 2.501e6; // 潜热系数 J/kg
    final cp = 1004.0;  // 定压比热 J/(kg·K)
    return theta * math.exp(lv * mixingRatio / (cp * temperature));
  }
}