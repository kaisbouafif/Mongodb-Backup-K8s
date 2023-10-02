# Use the official Ubuntu 20.04 LTS image as the base image
FROM ubuntu:20.04



# Update the package repository and install MongoDB
RUN apt-get update && \
    apt-get install -y mongodb && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
# Install the MongoDB shell (mongo)
RUN apt-get update && \
    apt-get install -y mongodb-clients && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a directory for MongoDB data
VOLUME ["/data/db"]

# Install required tools (jq, python3, curl, bash)
RUN apt-get update && \
    apt-get install -y jq python3 curl bash && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK
RUN curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-360.0.0-linux-x86_64.tar.gz && \
    tar -xzf google-cloud-sdk-360.0.0-linux-x86_64.tar.gz && \
    google-cloud-sdk/install.sh --path-update=true --quiet && \
    rm -rf google-cloud-sdk-360.0.0-linux-x86_64.tar.gz

# Clean up
RUN apt-get remove -y curl && \
    apt-get autoremove -y && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*



# Set the PATH to include the Google Cloud SDK binaries
ENV PATH="${PATH}:/google-cloud-sdk/bin:/usr/bin"
# Copy your script to the Docker image
COPY script.sh /app/script.sh
COPY googlekey.json /app/googlekey.json

# Make your script executable
RUN chmod +x /app/script.sh


# Set the working directory
WORKDIR /app

# Start your script when the container runs
CMD ["/app/script.sh"]
