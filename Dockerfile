# Use an official Octave image as the base
FROM mtmiller/octave:latest

# Install Node.js (since Octave base image does not have it)
RUN apt update && apt install -y nodejs npm

# Set working directory
WORKDIR /app

# Create necessary directories
RUN mkdir -p /app/octave/ /app/readonly/

# Copy only package.json first to leverage Docker cache
COPY package*.json /app/

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . /app

# Copy Octave script files to the correct location
COPY octave/*.m /app/octave/

# Copy optimize_RC.m to /app/readonly/ so that Octave can find it
COPY octave/optimize_RC.m /app/readonly/optimize_RC.m

# Copy pulseData.mat from the octave folder
COPY octave/pulseData.mat /app/octave/pulseData.mat

# Ensure Octave finds the necessary files by setting the path
ENV OCTAVE_PATH "/app/octave"

# Expose the correct port (10000)
EXPOSE 10000

# Start the Node.js server
CMD ["node", "server.js"]
