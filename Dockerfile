# ----------------------
# Base image
# ----------------------
FROM node:lts-alpine AS base
WORKDIR /app

# Install necessary tools
RUN apk add --no-cache libc6-compat git bash

# Enable Corepack
RUN corepack enable

# Make app directory group-writable (for OpenShift random UID)
RUN mkdir -p /app && chmod -R g+rwX /app

# ----------------------
# Dependencies stage
# ----------------------
FROM base AS deps
WORKDIR /app

COPY package.json pnpm-lock.yaml* postinstall.js ./
COPY prisma ./prisma

RUN corepack enable pnpm \
    && pnpm install --frozen-lockfile --prefer-offline

# ----------------------
# Builder stage
# ----------------------
FROM base AS builder
WORKDIR /app

# Build-time ENV variables
ARG POSTGRES_PRISMA_URL
ARG POSTGRES_URL_NON_POOLING
ENV POSTGRES_PRISMA_URL=$POSTGRES_PRISMA_URL
ENV POSTGRES_URL_NON_POOLING=$POSTGRES_URL_NON_POOLING

COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma
COPY . .

# Ensure cache directories exist and are writable
RUN mkdir -p /app/.next/cache/fetch-cache /app/.cache \
    && chmod -R g+rwX /app/.next /app/.cache

# Run postinstall.js and build
RUN corepack enable pnpm \
    && node postinstall.js \
    && pnpm run build

# ----------------------
# Production stage
# ----------------------
FROM base AS prod
WORKDIR /app

ENV NODE_ENV=production

# Copy built artifacts
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/public ./public
COPY --from=builder /app/prisma ./prisma

# Ensure runtime cache directories are writable
RUN mkdir -p /app/.next/cache/fetch-cache /app/.cache \
    && chmod -R g+rwX /app/.next /app/.cache

EXPOSE 3000

CMD ["sh", "-c", "pnpm prisma migrate deploy && pnpm start"]


