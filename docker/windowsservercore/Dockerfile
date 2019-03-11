FROM microsoft/powershell:windowsservercore as base
SHELL ["pwsh", "-Command", "$ErrorActionPreference = 'Stop'; $VerbosePreference = 'Continue'; $ProgressPreference = 'SilentlyContinue';"]
RUN Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module Configuration -RequiredVersion 1.3.1 -Repository PSGallery -SkipPublisherCheck -Force; \
    Install-Module PSSlack -RequiredVersion 0.1.2 -Repository PSGallery -SkipPublisherCheck -Force ;

FROM base as src
LABEL maintainer="devblackops"
LABEL description="PoshBot container for Slack"
LABEL vendor="poshbotio"
COPY ["/out/poshbot", "C:/Program Files/PowerShell/Modules/PoshBot/"]
COPY ["/docker/docker_entrypoint.ps1", "c:/poshbot/docker_entrypoint.ps1"]
WORKDIR c:/poshbot/
RUN mkdir plugins
WORKDIR c:/poshbot/
VOLUME ["c:/poshbot_data"]
USER ContainerAdministrator
RUN setx PATH "%PATH%;%ProgramFiles%\\PowerShell"
USER ContainerUser
CMD ["pwsh.exe", "-f", "c:/poshbot/docker_entrypoint.ps1"]
