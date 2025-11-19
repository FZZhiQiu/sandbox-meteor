#!/usr/bin/env python3
"""
Sandbox Meteor Web Preview Server
A simple HTTP server for the web preview page
"""

import http.server
import socketserver
import os
import sys
from pathlib import Path
import mimetypes

# Set additional mime types
mimetypes.add_type('application/wasm', '.wasm')

# Change to the web-preview directory
web_preview_dir = Path(__file__).parent
os.chdir(web_preview_dir)

PORT = 8080
DIRECTORY = "."

class CustomHTTPRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

    def guess_type(self, path):
        # Get the mime type
        mimetype, encoding = mimetypes.guess_type(path)
        if mimetype:
            return mimetype
        # Default fallback
        return 'application/octet-stream'

    def end_headers(self):
        # Add CORS headers to allow loading WASM files
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', '*')
        super().end_headers()

    def log_message(self, format, *args):
        # Custom logging that shows which files are being accessed
        print(f"[Web Preview Server] {format % args}")

def main():
    print(f"Starting Sandbox Meteor Web Preview Server")
    print(f"Directory: {web_preview_dir.absolute()}")
    print(f"Access the preview at: http://localhost:{PORT}")
    print("Press Ctrl+C to stop the server")
    print("-" * 50)
    
    try:
        with socketserver.TCPServer(("", PORT), CustomHTTPRequestHandler) as httpd:
            print(f"Server running at port {PORT}")
            httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down the server...")
        sys.exit(0)
    except Exception as e:
        print(f"Error starting server: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

