# JavaScript OS in Docker

This project creates a JavaScript-based OS-like environment running in Docker. It uses a minimal Linux container with a browser in kiosk mode to display a web application as if it were an operating system.

## Project Overview

- **Browser-based UI**: Full-screen Chromium browser runs your JavaScript application
- **Docker-based**: Works on both development workstations and Raspberry Pi
- **VNC access**: Remote access to the visual interface
- **Cross-platform**: Same codebase works on Windows, Mac, Linux, and Raspberry Pi

## Project Structure

```
js-os/
├── config/
│   ├── openbox-autostart      # Window manager configuration
│   └── supervisord.conf       # Process management configuration
├── public/                    # Your web application files
│   └── index.html             # Main entry point for your JavaScript OS
├── Dockerfile                 # Container definition
├── docker-compose.yml         # Container orchestration
├── package.json               # Node.js dependencies
├── server.js                  # Express server for the web app
└── README.md                  # This file
```

## Setup Instructions

### Prerequisites

- Docker and Docker Compose installed

### Installation

1. Create the project structure as shown above with these files:

#### Dockerfile
```dockerfile
# Dockerfile for JavaScript OS
FROM node:16-bullseye-slim
# Install X11, browser, and window manager
RUN apt-get update && apt-get install -y --no-install-recommends \
    xorg \
    openbox \
    chromium \
    unclutter \
    x11vnc \
    xvfb \
    supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
# Set up working directory
WORKDIR /app
# Copy package files and install dependencies
COPY package*.json ./
RUN npm install
# Copy application code
COPY . .
# Set up X11 configs
RUN mkdir -p /root/.config/openbox
COPY config/openbox-autostart /root/.config/openbox/autostart
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Expose ports for the web server and VNC
EXPOSE 8000 5900
# Start supervisord to manage all processes
CMD ["supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

#### docker-compose.yml
```yaml
version: '3'

services:
  js-os:
    build: .
    container_name: js-os
    ports:
      - "8000:8000"  # Web application
      - "5900:5900"  # VNC server for viewing the browser display
    volumes:
      - ./public:/app/public  # Mount your web app files for easy development
      - ./server.js:/app/server.js  # Mount server file for easy updates
    restart: unless-stopped
```

#### server.js
```javascript
const express = require('express');
const app = express();
const port = 8000;

// Serve static files
app.use(express.static('public'));

// Add a simple API endpoint
app.get('/api/status', (req, res) => {
  res.json({ status: 'running' });
});

// Start the server
app.listen(port, '0.0.0.0', () => {
  console.log(`JS-OS server running at http://0.0.0.0:${port}`);
});
```

#### package.json
```json
{
  "name": "js-os",
  "version": "1.0.0",
  "description": "JavaScript OS for Raspberry Pi",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2"
  }
}
```

#### config/openbox-autostart
```bash
#!/bin/bash

# Hide the cursor
unclutter &

# Set background color
xsetroot -solid "#000000" &

# Disable screen blanking and DPMS
xset s off -dpms &
```

#### config/supervisord.conf
```ini
[supervisord]
nodaemon=true
user=root

[program:xvfb]
command=Xvfb :1 -screen 0 1280x720x24
autorestart=true
priority=100

[program:x11vnc]
command=x11vnc -forever -display :1 -nopw -listen 0.0.0.0
autorestart=true
priority=200

[program:openbox]
command=/bin/bash -c "export DISPLAY=:1 && openbox-session"
autorestart=true
priority=300

[program:js-server]
command=node server.js
directory=/app
autorestart=true
priority=400
environment=DISPLAY=:1

[program:browser]
command=/bin/bash -c "sleep 5 && export DISPLAY=:1 && chromium --no-sandbox --disable-dev-shm-usage --kiosk --app=http://localhost:8000 --no-first-run --disable-infobars --noerrdialogs --disable-session-crashed-bubble --disable-pinch --overscroll-history-navigation=0"
autorestart=true
priority=500
```

#### public/index.html
Create a basic HTML file as a starting point:
```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>JavaScript OS</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      background-color: #1e1e2e;
      color: #ffffff;
      margin: 0;
      padding: 0;
      display: flex;
      justify-content: center;
      align-items: center;
      height: 100vh;
      text-align: center;
    }
    h1 {
      font-size: 3em;
    }
    p {
      font-size: 1.5em;
    }
  </style>
</head>
<body>
  <div>
    <h1>JavaScript OS</h1>
    <p>Your custom OS is running!</p>
    <p>Current time: <span id="time"></span></p>
  </div>

  <script>
    function updateTime() {
      document.getElementById('time').textContent = new Date().toLocaleTimeString();
    }
    
    // Update time every second
    setInterval(updateTime, 1000);
    updateTime();
  </script>
</body>
</html>
```

### Running the Application

1. Build and start the container:
```bash
docker-compose up -d
```

2. Access your JavaScript OS:
   - Web interface: http://localhost:8000
   - VNC interface: Connect with a VNC client to localhost:5900

### Stopping the Application

```bash
docker-compose down
```

### Rebuilding After Changes

If you make changes to the Dockerfile or files that aren't mounted as volumes:

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Troubleshooting

### Check Container Status
```bash
docker ps
```

### View Container Logs
```bash
docker logs js-os
```

### Access Container Shell
```bash
docker exec -it js-os bash
```

## For Raspberry Pi Deployment

For Raspberry Pi, you may need additional configuration for hardware access:

1. Edit docker-compose.yml to include:
```yaml
privileged: true
devices:
  - "/dev/gpiomem:/dev/gpiomem"
  - "/dev/i2c-1:/dev/i2c-1"
```

2. Install on Raspberry Pi OS:
```bash
# Install Docker and Docker Compose
curl -sSL https://get.docker.com | sh
sudo apt-get install -y docker-compose

# Clone your project and start it
git clone <your-repo>
cd <your-project-folder>
docker-compose up -d
```

## Customizing Your JavaScript OS

1. Modify files in the `public` directory to change the UI and functionality
2. Edit server.js to add backend APIs
3. To install additional Node.js packages:
   ```bash
   # Add to package.json, then rebuild
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

## Common Issues and Solutions

1. **Server won't start**: Check for JavaScript syntax errors in server.js
2. **VNC shows no content**: Verify the browser process is running properly
3. **Docker errors on Windows**: Ensure Docker Desktop is running properly
# car-js
