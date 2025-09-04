FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
COPY tsconfig.json ./

RUN npm ci

COPY src/ ./src

RUN npm run build

FROM node:20-alpine

RUN addgroup -g 1001 -S nodejs && \
    adduser -u 1001 -S nodejs

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production && \
    npm cache clean --force

COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist

COPY --chown=nodejs:nodejs .env.example .env.example

USER nodejs

EXPOSE 3001

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
     CMD node -e "require('http').get('http://localhost:3001/health', (r) => { r.statusCode === 200 ? process.exit(0) : process.exit(1) })"

CMD [ "node", "dist/index.js" ]     