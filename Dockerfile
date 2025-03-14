# Use an official Octave image as the base
FROM mtmiller/octave:latest

# Install Node.js (since Octave base image does not have it)
RUN apt update && apt install -y nodejs npm

# Set working directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/readonly/

# Copy only package.json first to leverage Docker cache
COPY package*.json /app/

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . /app

# Copy all Octave script files to /app/readonly/
COPY octave/*.m /app/readonly/

# Copy pulseData.mat to /app/readonly/
COPY octave/pulseData.mat /app/readonly/pulseData.mat

# Ensure Octave finds the necessary files by setting the path
ENV OCTAVE_PATH "/app/readonly"

# Expose the correct port (10000)
EXPOSE 10000

# Start the Node.js server
CMD ["node", "server.js"]
