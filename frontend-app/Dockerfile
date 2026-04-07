# STEP 1: Build Angular app
FROM node:18 AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# ✅ FIX HERE
RUN npm run build


# STEP 2: Serve using nginx
FROM nginx:alpine

COPY --from=build /app/dist/frontend-app /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]