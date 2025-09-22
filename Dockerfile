FROM node:lts-alpine AS base
WORKDIR /app

# Inject commit SHA at build time (from OpenShift BUILD_COMMIT)
ARG COMMIT_SHA=unknown
ENV COMMIT_SHA=$COMMIT_SHA

# ---------
# Install dependencies only when needed
FROM base AS deps

# Install libc6-compat for better compatibility and git for version info
RUN apk add --no-cache libc6-compat git

# Enable corepack early for better caching
RUN corepack enable

# Copy dependency files, Prisma schema, and postinstall script
COPY package.json pnpm-lock.yaml* postinstall.js ./
COPY prisma ./prisma

# Install pnpm and dependencies with cache mount for faster builds
RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    --mount=type=cache,target=/root/.cache/pnpm \
    corepack enable pnpm && pnpm i --frozen-lockfile --prefer-offline

# Copy remaining setup scripts
COPY migrate-and-start.sh setup-database.js initialize.js ./

# ---------
# Rebuild the source code only when needed
FROM base AS builder

# Install git for version info
RUN apk add --no-cache git

# Copy node_modules and Prisma files from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma

# Copy source code
COPY . .

# Set environment variables for build
ENV SKIP_ENV_VALIDATION=true
ENV NODE_ENV=production
# Set Node.js memory limit to prevent SIGKILL
ENV NODE_OPTIONS="--max-old-space-size=2048"

# Build your Next.js app
RUN corepack enable pnpm && pnpm run build

# ---------
# Production image
FROM base AS runner
WORKDIR /app

# Set production environment variables
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000

# Create user and group in a single layer
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy public assets
COPY --from=builder /app/public ./public

# Create .next directory with correct permissions
RUN mkdir .next && chown nextjs:nodejs .next

# Copy built application with correct permissions
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./ 
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Copy runtime scripts and database schema
COPY --from=builder --chown=nextjs:nodejs /app/initialize.js ./ 
COPY --from=builder --chown=nextjs:nodejs /app/setup-database.js ./ 
COPY --from=builder --chown=nextjs:nodejs /app/migrate-and-start.sh ./ 
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma

# Switch to non-root user
USER nextjs

EXPOSE 3000

CMD ["sh", "migrate-and-start.sh"]
