# Multi-stage build for smaller production image
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Production stage
FROM node:18-alpine AS production

# Create app user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S notifylight -u 1001

WORKDIR /app

# Copy built dependencies and source
COPY --from=builder --chown=notifylight:nodejs /app/node_modules ./node_modules
COPY --chown=notifylight:nodejs src ./src
COPY --chown=notifylight:nodejs package*.json ./

# Switch to non-root user
USER notifylight

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start server
CMD ["npm", "start"]