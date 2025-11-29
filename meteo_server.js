#!/usr/bin/env node

// 气象数据模拟服务器
const http = require('http');

const port = 3000;

// 模拟气象数据
const weatherData = {
    temperature: 25.5,
    humidity: 65,
    pressure: 1013.25,
    windSpeed: 12.3,
    timestamp: new Date().toISOString()
};

const server = http.createServer((req, res) => {
    res.setHeader('Content-Type', 'application/json');
    res.setHeader('Access-Control-Allow-Origin', '*');
    
    if (req.url === '/weather') {
        // 更新时间戳
        weatherData.timestamp = new Date().toISOString();
        // 模拟数据变化
        weatherData.temperature += (Math.random() - 0.5) * 0.5;
        weatherData.humidity += (Math.random() - 0.5) * 2;
        
        res.writeHead(200);
        res.end(JSON.stringify(weatherData, null, 2));
    } else {
        res.writeHead(404);
        res.end(JSON.stringify({ error: 'Not Found' }));
    }
});

server.listen(port, () => {
    console.log(`气象数据服务器运行在 http://localhost:${port}`);
    console.log('API 端点: http://localhost:3000/weather');
});