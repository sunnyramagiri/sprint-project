FROM node:20

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Expose application port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
