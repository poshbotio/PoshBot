FROM mcr.microsoft.com/powershell:7.2.0-ubuntu-18.04-20211102 as base
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module Configuration -RequiredVersion 1.3.1 -Repository PSGallery -Scope AllUsers -Verbose; \
    Install-Module PSSlack -RequiredVersion 1.0.2 -Repository PSGallery -Scope AllUsers -Verbose;

FROM base as src
ARG version
LABEL maintainer="devblackops"
LABEL description="PoshBot container for Ubuntu 18.04"
LABEL vendor="poshbotio"
COPY ["/out/PoshBot/$version", "/opt/microsoft/powershell/7/Modules/PoshBot/"]
COPY ["/docker/docker_entrypoint.ps1", "/poshbot/docker_entrypoint.ps1"]
WORKDIR /poshbot/
VOLUME ["/poshbot_data"]
VOLUME ["/root/.local/share/powershell/Modules"]
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
CMD ["pwsh", "docker_entrypoint.ps1"]
