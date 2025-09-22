# Stage 1: Base image
FROM node:lts-alpine AS base

ENV PUBLIC_URL="https://fresco-dept-respond-fresco.apps.cloudapps.unc.edu/" \
    POSTGRES_PRISMA_URL="postgres://user:resp0ndpass@172.30.169.111:5432/respond?schema=public" \
    POSTGRES_URL_NON_POOLING="postgres://user:resp0ndpass@172.30.169.111:5432/respond?schema=public" \
    POSTGRES_PASSWORD="resp0ndpass" \
    NODE_OPTIONS="--max-old-space-size=2048"

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

COPY --from=deps /app/node_modules ./node_modules
COPY --from=deps /app/prisma ./prisma
COPY . .

RUN corepack enable pnpm \
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
