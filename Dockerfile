# HEIR-Integrated Outreach Scraper - Docker Configuration
# Multi-stage build for production optimization

# Stage 1: Base dependencies
FROM node:18-alpine AS base

# Install system dependencies
RUN apk add --no-cache \
    python3 \
    py3-pip \
    postgresql-client \
    curl \
    git

# Set working directory
WORKDIR /app

# Stage 2: Dependencies installation
FROM base AS deps

# Copy package files
COPY package*.json ./
COPY requirements.txt ./

# Install Node.js dependencies
RUN npm ci --only=production

# Install Python dependencies for testing
RUN pip3 install -r requirements.txt

# Stage 3: Development environment
FROM base AS development

# Copy all dependencies
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /usr/local/lib/python3.*/site-packages /usr/local/lib/python3.*/site-packages

# Copy application source
COPY . .

# Create necessary directories
RUN mkdir -p /app/.heir/logs \
    && mkdir -p /app/backups \
    && chmod +x /app/scripts/*.sh

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Expose ports
EXPOSE 3000

# Default environment
ENV NODE_ENV=development
ENV HEIR_VERSION=2.0.0
ENV ORBT_ENABLED=true

# Start command for development
CMD ["npm", "run", "dev"]

# Stage 4: Production build
FROM base AS production

# Create app user for security
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001

# Copy dependencies and app
COPY --from=deps --chown=nextjs:nodejs /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs . .

# Set permissions
RUN chmod +x /app/scripts/*.sh

# Create required directories with proper permissions
RUN mkdir -p /app/.heir/logs /app/backups \
    && chown -R nextjs:nodejs /app/.heir /app/backups

# Switch to non-root user
USER nextjs

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Expose ports
EXPOSE 3000

# Production environment
ENV NODE_ENV=production
ENV HEIR_VERSION=2.0.0
ENV ORBT_ENABLED=true
ENV DATABASE_GATEKEEPER_ENABLED=true
ENV API_GATEWAY_ENABLED=true

# Start production server
CMD ["node", "server.js"]
