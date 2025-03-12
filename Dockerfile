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

# Move Octave files to the correct location
COPY octave/optimize_RC.m /app/readonly/optimize_RC.m
COPY octave/pulseData.mat /app/readonly/pulseData.mat
COPY octave/pulseModel.mat /app/readonly/pulseModel.mat

# Expose the correct port (10000)
EXPOSE 10000

# Start the server
CMD ["node", "server.js"]
