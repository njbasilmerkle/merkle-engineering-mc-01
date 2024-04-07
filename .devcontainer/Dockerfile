# You can pick any Debian/Ubuntu-based image. 😊
ARG VARIANT="3.12-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/python:1-${VARIANT}

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
RUN echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list

# Install Terraform
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    terraform \
    direnv \
    && rm -rf /var/lib/apt/lists/*