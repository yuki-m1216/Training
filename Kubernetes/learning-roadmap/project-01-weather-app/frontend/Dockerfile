FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

RUN npm run build

FROM nginx:alpine-slim

RUN addgroup -g 1001 -S nginx-group && \
    adduser -u 1001 -S nginx-group -G nginx-group

COPY --from=builder /app/nginx.conf /etc/nginx/nginx.conf

COPY --from=builder --chown=nginx-user:nginx-group /app/dist /usr/share/nginx/html

RUN mkdir -p /var/cache/nginx /var/log/nginx && \
    chown -R nginx-user:nginx-group /var/cache/nginx /var/log/nginx && \
    touch /var/run/nginx.pid && \
    chown nginx-user:nginx-group /var/run/nginx.pid

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \ 
    CMD wget --no-verbose --tries=1 --spider http://localhost:80 || exit 1

USER nginx-user

CMD ["nginx", "-g", "daemon off;"]