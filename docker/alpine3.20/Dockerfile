FROM mcr.microsoft.com/powershell:7.5-alpine-3.20 as base
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Set-PSResourceRepository -Name PSGallery -Trusted; \
    Install-PSResource Configuration -Version 1.6.0 -Repository PSGallery -Scope AllUsers -Verbose;

FROM base as src
ARG version
LABEL maintainer="devblackops"
LABEL description="PoshBot container for Alpine 3.20"
LABEL vendor="poshbotio"
COPY ["/out/PoshBot/$version", "/opt/microsoft/powershell/7/Modules/PoshBot/"]
COPY ["/docker/docker_entrypoint.ps1", "/poshbot/docker_entrypoint.ps1"]
WORKDIR /poshbot/
VOLUME ["/poshbot_data"]
VOLUME ["/root/.local/share/powershell/Modules"]
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
CMD ["pwsh", "docker_entrypoint.ps1"]
