FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install dependencies for shared utilities first
COPY ../shared/package*.json ./shared/
RUN cd shared && npm ci --only=production

# Copy shared utilities
COPY ../shared ./shared/

# Install service-specific dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy service code
COPY . .

# Create logs directory
RUN mkdir -p logs && chown -R node:node logs

# Switch to non-root user for security
USER node

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health/live', (res) => { process.exit(res.statusCode === 200 ? 0 : 1); });"

# Start service
CMD ["node", "server-production.js"]
