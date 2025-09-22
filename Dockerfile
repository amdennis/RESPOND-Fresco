# Stage 1: Base image
FROM node:lts-alpine AS base

WORKDIR /app
RUN apk add --no-cache libc6-compat git bash
RUN corepack enable

# Stage 2: Install dependencies
FROM base AS deps
COPY package.json pnpm-lock.yaml* postinstall.js ./
COPY prisma ./prisma
RUN corepack enable pnpm \
    && pnpm install --frozen-lockfile --prefer-offline

# Stage 3: Build
FROM base AS builder
ARG COMMIT_SHA=unknown
ENV COMMIT_SHA=$COMMIT_SHA \
    NEXT_PUBLIC_COMMIT_SHA=$COMMIT_SHA

# Copy deps
COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma
COPY . .

# Run postinstall.js (with npx) and build
RUN corepack enable pnpm \
    && node postinstall.js \
    && pnpm run build

# Stage 4: Production image
FROM base AS runner
WORKDIR /app

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json

EXPOSE 3000
CMD ["node", "server.js"]

