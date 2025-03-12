# Use an official Octave image as the base
FROM mtmiller/octave:latest

# Set working directory
WORKDIR /app

# Copy all files, including optimize_RC.m
COPY . .
COPY octave/optimize_RC.m /app/optimize_RC.m
COPY octave/pulseData.mat /app/readonly/pulseData.mat
COPY octave/pulseModel.mat /app/readonly/pulseModel.mat

# Create the directory if it doesn’t exist and move optimize_RC.m
RUN mkdir -p /app/readonly/ && cp optimize_RC.m /app/readonly/

# Install dependencies if needed (example for Node.js)
RUN npm install

# Expose the required port
EXPOSE 3001

# Start the server
CMD ["node", "server.js"]

