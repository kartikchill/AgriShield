FROM node:20-alpine

WORKDIR /app

# Copy the package files from the frontend subfolder
COPY frontend/package*.json ./

# Install npm dependencies
RUN npm install

# Copy the rest of the frontend source code
COPY frontend/ ./

# Expose Vite's default port
EXPOSE 3000

# Start the Vite development server and expose to the network
CMD ["npm", "run", "dev", "--", "--host", "0.0.0.0"]
