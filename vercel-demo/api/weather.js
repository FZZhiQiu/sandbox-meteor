// Vercel Serverless Function - 气象数据 API
export default function handler(req, res) {
  // 模拟实时气象数据
  const weatherData = {
    location: "气象沙盘模拟器",
    timestamp: new Date().toISOString(),
    current: {
      temperature: 20 + Math.random() * 15,
      humidity: 40 + Math.random() * 40,
      pressure: 1000 + Math.random() * 30,
      windSpeed: 5 + Math.random() * 20,
      windDirection: ["北", "东北", "东", "东南", "南", "西南", "西", "西北"][Math.floor(Math.random() * 8)],
      visibility: 5 + Math.random() * 10,
      uvIndex: Math.floor(Math.random() * 11)
    },
    forecast: Array.from({ length: 7 }, (_, i) => ({
      date: new Date(Date.now() + i * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      high: 20 + Math.random() * 15,
      low: 10 + Math.random() * 10,
      condition: ["晴", "多云", "阴", "小雨", "中雨"][Math.floor(Math.random() * 5)]
    }))
  };

  // 设置 CORS 头
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'GET') {
    res.status(200).json(weatherData);
  } else {
    res.setHeader('Allow', ['GET']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}