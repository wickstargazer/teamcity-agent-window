FROM microsoft/windowsservercore

MAINTAINER Wick <wickyorama@gmail.com>

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop';"]

ARG TEAMCITY_SERVER="<your server url>"
ENV BUILDAGENT "C:/buildAgent"
ENV INSTALL "C:/Install"
ENV SCRIPTS "C:/Scripts"
ENV TEAMCITY_SERVER ${TEAMCITY_SERVER}

RUN New-Item -Path $Env:INSTALL -Type directory 
RUN New-Item -Path $Env:SCRIPTS -Type directory 

# Prepare application for waiting for java processes when the agent is started.
COPY jre-8u144-windows-x64.tar.gz $INSTALL
COPY ICSharpCode.SharpZipLib.dll $INSTALL
COPY downloadJre.ps1 $INSTALL
COPY runAgent.ps1 $SCRIPTS

# Move to install directory
WORKDIR $INSTALL

# Downloads dependencies
RUN ./downloadJre.ps1 -Uri "http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jre-8u144-windows-x64.tar.gz" -OutDest "$Env:BUILDAGENT/jre"; \
    Invoke-WebRequest "$Env:TEAMCITY_SERVER/update/buildAgent.zip" -OutFile "buildAgent.zip"; \
    Expand-Archive buildAgent.zip -DestinationPath $Env:BUILDAGENT



# Post job for preparing the teamcity agent
    RUN New-Item $Env:BUILDAGENT/work -ItemType directory -Force | Out-Null; \
    $lines = (Get-Content $Env:BUILDAGENT/conf/buildAgent.dist.properties).replace('http://localhost:8111/', "$Env:TEAMCITY_SERVER"); \
    Set-Content $Env:BUILDAGENT/conf/buildAgent.dist.properties $lines; \
    Rename-Item $Env:BUILDAGENT/conf/buildAgent.dist.properties $Env:BUILDAGENT/conf/buildAgent.properties; \
    Rename-Item $Env:BUILDAGENT/conf conf.bak; \
    New-Item $Env:BUILDAGENT/conf -ItemType directory -Force | Out-Null;

VOLUME $BUILDAGENT/conf
VOLUME $BUILDAGENT/logs

WORKDIR $BUILDAGENT

# Clean up
RUN Remove-Item $Env:INSTALL -Recurse -Force

EXPOSE 9090

# Run the agent
CMD & "$Env:SCRIPTS/runAgent.ps1"