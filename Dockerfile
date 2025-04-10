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
