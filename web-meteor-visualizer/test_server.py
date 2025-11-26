#!/usr/bin/env python3
import http.server
import socketserver
import os

# 切换到项目目录
os.chdir('/data/data/com.termux/files/home/happy/web-meteor-visualizer')

PORT = 8000

Handler = http.server.SimpleHTTPRequestHandler
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Server running at http://localhost:{PORT}/")
    print(f"Serving from directory: {os.getcwd()}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nServer stopped.")