FROM mcr.microsoft.com/powershell:7.0.3-windowsservercore-2004 as base
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module Configuration -RequiredVersion 1.3.1 -Repository PSGallery -Scope AllUsers -Verbose; \
    Install-Module PSSlack -RequiredVersion 1.0.6 -Repository PSGallery -Scope AllUsers -Verbose;

FROM base as src
ARG version
LABEL maintainer="devblackops"
LABEL description="PoshBot container for Windows Server Core"
LABEL vendor="poshbotio"
COPY ["/out/poshbot/$version", "C:/Program Files/PowerShell/Modules/PoshBot/"]
COPY ["/docker/docker_entrypoint.ps1", "c:/poshbot/docker_entrypoint.ps1"]
WORKDIR c:/poshbot/
RUN mkdir plugins
WORKDIR c:/poshbot/
VOLUME ["c:/poshbot_data"]
USER ContainerAdministrator
RUN setx PATH "%PATH%;%ProgramFiles%\\PowerShell"
USER ContainerUser
CMD ["pwsh.exe", "-f", "c:/poshbot/docker_entrypoint.ps1"]
