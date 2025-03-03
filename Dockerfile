# Use an official Octave image as the base
FROM octave/octave:latest

# Set working directory
WORKDIR /app

# Install Node.js and dependencies
RUN apt-get update && apt-get install -y nodejs npm

# Copy project files
COPY . .

# Install project dependencies
RUN npm install

# Expose the necessary port
EXPOSE 3001

# Start the Node.js server
CMD ["node", "server.js"]
