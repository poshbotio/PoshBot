
FROM microsoft/nanoserver

MAINTAINER devblackops

LABEL description="PoshBot container for Slack"
LABEL vendor="poshbotio"

COPY ["/out/poshbot", "C:/Program Files/WindowsPowerShell/Modules/PoshBot/"]
COPY ["docker_entrypoint.ps1", "c:/poshbot/docker_entrypoint.ps1"]

WORKDIR c:/poshbot/

VOLUME ["c:/poshbot_data"]

# configure shell default parameters
SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $VerbosePreference = 'Continue'; $ProgressPreference = 'SilentlyContinue';"]

RUN Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force; \
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted; \
    Install-Module Configuration -RequiredVersion 1.0.2 -Repository PSGallery; \
    Install-Module PSSlack -RequiredVersion 0.0.17 -Repository PSGallery;

CMD ["powershell.exe", ". c:/poshbot/docker_entrypoint.ps1"]
