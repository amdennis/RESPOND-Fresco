# --------- Base stage ---------
FROM node:lts-alpine AS base

WORKDIR /app

# Install basic tools
RUN apk add --no-cache libc6-compat git bash

# Enable corepack for pnpm
RUN corepack enable

# --------- Dependencies stage ---------
FROM base AS deps

# Copy package files and Prisma schema
COPY package.json pnpm-lock.yaml* postinstall.js ./
COPY prisma ./prisma

# Install dependencies with caching
RUN --mount=type=cache,target=/root/.local/share/pnpm/store \
    --mount=type=cache,target=/root/.cache/pnpm \
    corepack enable pnpm && pnpm install --frozen-lockfile --prefer-offline

# Copy runtime scripts
COPY migrate-and-start.sh setup-database.js initialize.js ./

# --------- Builder stage ---------
FROM base AS builder

WORKDIR /app

# Copy dependencies and Prisma from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma

# Copy source code
COPY . .

# Provide COMMIT_SHA as build arg
ARG COMMIT_SHA=unknown
ENV COMMIT_SHA=$COMMIT_SHA

# Production environment
ENV NODE_ENV=production
ENV SKIP_ENV_VALIDATION=true
ENV NODE_OPTIONS="--max-old-space-size=1024"

# Build Next.js app
RUN corepack enable pnpm && pnpm run build

# --------- Runner stage ---------
FROM node:lts-alpine AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs

# Copy built app
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/prisma ./prisma
COPY --from=builder --chown=nextjs:nodejs /app/initialize.js ./ 
COPY --from=builder --chown=nextjs:nodejs /app/setup-database.js ./ 
COPY --from=builder --chown=nextjs:nodejs /app/migrate-and-start.sh ./ 

# Switch to non-root user
USER nextjs

# Set environment
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000

EXPOSE 3000

CMD ["sh", "migrate-and-start.sh"]
