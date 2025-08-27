FROM node:22-slim AS base

FROM base AS deps
WORKDIR /app

COPY package.json package-lock.json* ./

RUN npm ci --only=production

FROM base AS build-deps
WORKDIR /app

COPY package.json package-lock.json* ./

RUN npm ci

FROM build-deps AS builder
WORKDIR /app

COPY . .

RUN npm run build

FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

COPY --from=deps /app/node_modules ./node_modules

COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/package.json ./

USER nestjs

EXPOSE 3001

CMD [ "node", "dist/src/main" ]
