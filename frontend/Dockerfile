# Frontend Dockerfile
FROM node:18-alpine as build

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with proper permissions
RUN npm ci --prefer-offline --no-audit

# Copy application files
COPY . .

# Fix permissions for node_modules executables
RUN chmod -R +x node_modules/.bin

# Build arguments for API URLs
ARG REACT_APP_API_URL
ARG REACT_APP_SOCKET_URL

# Build the application
RUN npm run build

# Production stage
FROM node:18-alpine

WORKDIR /app

# Install serve to run the production build
RUN npm install -g serve

# Copy build files from build stage
COPY --from=build /app/build ./build

# Expose port
EXPOSE 3006

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3006 || exit 1

# Start application
CMD ["serve", "-s", "build", "-l", "3006"]
