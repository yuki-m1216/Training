FROM node:20-alpine AS base

RUN addgroup -g 1001 -S nodejs && \
    adduser -S nestjs -u 1001 && \
    apk add --no-cache dumb-init

FROM base AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM base AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

COPY --from=deps --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --chown=nestjs:nodejs package*.json ./

RUN echo "const http = require('http'); \
  const options = { host: 'localhost', port: 3000, path: '/health', timeout: 2000 }; \
  const request = http.request(options, (res) => { \
    process.exit(res.statusCode === 200 ? 0 : 1); \
  }); \
  request.on('error', () => process.exit(1)); \
  request.end();" > healthcheck.js

USER nestjs

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD node healthcheck.js

EXPOSE 3000

ENTRYPOINT [ "dumb-init", "--" ]
CMD [ "node", "dist/main.js" ]
