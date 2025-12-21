# User Service Dockerfile
FROM node:18-alpine

# Set working directory
WORKDIR /app/services/user-service

# Install dependencies for shared utilities first
COPY services/shared/package*.json ../shared/
RUN cd ../shared && npm ci --only=production

# Copy shared utilities
COPY services/shared ../shared/

# Install service-specific dependencies
COPY services/user-service/package*.json ./
RUN npm ci --only=production

# Copy service code
COPY services/user-service .

# Create uploads directory for avatars
RUN mkdir -p uploads/avatars

# Expose port
EXPOSE 3004

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3004/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "server.js"]
