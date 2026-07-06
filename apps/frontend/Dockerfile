# --- Stage 1 : build Angular ---
FROM node:24-alpine AS build
WORKDIR /app

# Couche qui change le moins souvent en premier (cache Docker)
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build -- --configuration production

# --- Stage 2 : servir avec nginx ---
FROM nginx:1.30-alpine
COPY --from=build /app/dist/frontend/browser /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80