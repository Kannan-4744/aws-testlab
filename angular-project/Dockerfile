# Stage 1: Build Angular app
FROM node:18 AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Stage 2: Serve with nginx
FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

# 🔥 FIX HERE
COPY --from=build /app/dist/angular-project /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]