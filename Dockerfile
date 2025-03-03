# Use an official Octave image as the base
FROM mtmiller/octave:latest

# Set working directory
WORKDIR /app

# Install Node.js and dependencies
RUN apt-get update && apt-get install -y nodejs npm

# Copy project files
COPY . .
COPY octave/optimize_RC.m /app/optimize_RC.m
COPY octave/pulseData.mat /app/readonly/pulseData.mat
COPY octave/pulseModel.mat /app/readonly/pulseModel.mat

# Install project dependencies
RUN npm install

# Expose the necessary port
EXPOSE 3001

# Start the Node.js server
CMD ["node", "server.js"]
