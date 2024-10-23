# Step 1: Use an official Node.js image as the base image
FROM node:20-alpine

# Step 2: Set the working directory inside the container
WORKDIR /app

# Step 3: Copy package.json and package-lock.json to the container
COPY package*.json ./

# Step 4: Install dependencies
RUN npm install

# Step 5: Copy the rest of the application files to the container
COPY . .

# Step 6: Build the application for production
RUN npm run build

# Step 7: Expose port 3000 (the default Nuxt.js port)
EXPOSE 3000

# Step 8: Start the application using the production build
CMD ["npm", "run", "dev"]
