
FROM mcr.microsoft.com/powershell:ubuntu-16.04 as base
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module Configuration -RequiredVersion 1.3.1 -Repository PSGallery -Verbose:$false; \
    Install-Module PSSlack -RequiredVersion 0.1.2 -Repository PSGallery -Verbose:$false;

FROM base as src
LABEL maintainer="devblackops"
LABEL description="PoshBot container for Ubuntu 16.04"
LABEL vendor="poshbotio"
COPY ["/out/poshbot", "/opt/microsoft/powershell/6/Modules/PoshBot/"]
COPY ["/docker/docker_entrypoint.ps1", "/poshbot/docker_entrypoint.ps1"]
WORKDIR /poshbot/
VOLUME ["/poshbot_data"]
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
CMD ["pwsh", "docker_entrypoint.ps1"]
