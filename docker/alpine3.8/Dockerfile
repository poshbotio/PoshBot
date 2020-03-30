FROM mcr.microsoft.com/powershell:6.2.3-alpine-3.8 as base
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module Configuration -RequiredVersion 1.3.1 -Repository PSGallery -Scope AllUsers -Verbose; \
    Install-Module PSSlack -RequiredVersion 1.0.2 -Repository PSGallery -Scope AllUsers -Verbose;

FROM base as src
ARG version
LABEL maintainer="devblackops"
LABEL description="PoshBot container for Ubuntu 18.04"
LABEL vendor="poshbotio"
COPY ["/out/poshbot/$version", "/opt/microsoft/powershell/6/Modules/PoshBot/"]
COPY ["/docker/docker_entrypoint.ps1", "/poshbot/docker_entrypoint.ps1"]
WORKDIR /poshbot/
VOLUME ["/poshbot_data"]
VOLUME ["/root/.local/share/powershell/Modules"]
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
CMD ["pwsh", "docker_entrypoint.ps1"]
