# ---------------------
# Base image
# ---------------------
FROM node:lts-alpine AS base

# Set environment variables (can be overridden in OpenShift)
ENV PUBLIC_URL="" \
    POSTGRES_PRISMA_URL="" \
    POSTGRES_URL_NON_POOLING="" \
    POSTGRES_PASSWORD="" \
    NODE_OPTIONS="--max-old-space-size=2048"

# Work directory
WORKDIR /app

# Install required system packages
RUN apk add --no-cache libc6-compat git bash

# Enable corepack (pnpm comes with it)
RUN corepack enable

# ---------------------
# Dependencies stage
# ---------------------
FROM base AS deps

WORKDIR /app

COPY package.json pnpm-lock.yaml* postinstall.js ./
COPY prisma ./prisma

RUN corepack enable pnpm \
    && pnpm install --frozen-lockfile --prefer-offline

# ---------------------
# Build stage
# ---------------------
FROM base AS builder

WORKDIR /app

# Inject commit SHA from OpenShift BuildConfig
ARG COMMIT_SHA=unknown
ENV COMMIT_SHA=$COMMIT_SHA \
    NEXT_PUBLIC_COMMIT_SHA=$COMMIT_SHA

# Copy node_modules and prisma from deps stage
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma

# Copy rest of the app
COPY . .

# Run postinstall before building Next.js
RUN node postinstall.js \
    && pnpm run build

# ---------------------
# Runner stage
# ---------------------
FROM base AS runner

WORKDIR /app

# Copy built output from builder
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma

# Expose port (OpenShift will override if needed)
EXPOSE 3000

# Run Next.js app
CMD ["pnpm", "start"]

