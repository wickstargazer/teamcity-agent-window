FROM microsoft/windowsservercore

MAINTAINER Wick <wickyorama@gmail.com>

SHELL ["powershell","-Command", "$ErrorActionPreference = 'Stop';"]

ARG TEAMCITY_SERVER="<your server url>"
ENV TEAMCITY_AGENT_SERVER ${TEAMCITY_SERVER}
ENV BUILDAGENT "C:/buildAgent"
ENV INSTALL "C:/Install"
ENV SCRIPTS "C:/Scripts"
ENV TEAMCITY_SERVER "<your server url>"
ENV ChocolateyUseWindowsCompression 'false'



RUN mkdir c:\install_logs;
RUN Invoke-WebRequest http://download.microsoft.com/download/2/1/2/2122BA8F-7EA6-4784-9195-A8CFB7E7388E/StandaloneSDK/sdksetup.exe -OutFile "$env:TEMP\sdksetup.exe"; \
Start-Process -FilePath "$env:TEMP\sdksetup.exe" -ArgumentList /Quiet, /NoRestart, /Log, c:\install_logs\sdksetup.log -PassThru -Wait; \
rm "$env:TEMP\sdksetup.exe";

#firsty install build tools
RUN Invoke-WebRequest "https://download.microsoft.com/download/E/E/D/EEDF18A8-4AED-4CE0-BEBE-70A83094FC5A/BuildTools_Full.exe" -OutFile "$env:TEMP\BuildTools_Full.exe" -UseBasicParsing; \
Start-Process "$env:TEMP\BuildTools_Full.exe" /Quiet, /NoRestart, /Log, c:\install_logs\msbuildtool12setup.log -PassThru -Wait; \
rm "$env:TEMP\BuildTools_Full.exe";

RUN Invoke-WebRequest "https://download.microsoft.com/download/9/B/B/9BB1309E-1A8F-4A47-A6C5-ECF76672A3B3/BuildTools_Full.exe" -OutFile "$env:TEMP\BuildTools_Full_14.exe" -UseBasicParsing; \
 Start-Process "$env:TEMP\BuildTools_Full_14.exe" /Quiet, /NoRestart, /Log, c:\install_logs\msbuildtool14setup.log -PassThru -Wait; \
 rm "$env:TEMP\BuildTools_Full_14.exe";

RUN New-Item -Path $Env:INSTALL -Type directory 
RUN New-Item -Path $Env:SCRIPTS -Type directory 

RUN [Environment]::SetEnvironmentVariable('PATH', $Env:ALLUSERSPROFILE + '\chocolatey\bin;' +  $env:PATH, [EnvironmentVariableTarget]::Machine);
RUN [Environment]::SetEnvironmentVariable('PATH', 'C:\Program Files (x86)\Microsoft SDKs\Windows\v10.0A\bin\NETFX 4.6 Tools;' +  $env:PATH, [EnvironmentVariableTarget]::Machine);
RUN [Environment]::SetEnvironmentVariable('SdkToolsPath', 'C:\\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6 Tools', [EnvironmentVariableTarget]::Machine);
RUN [Environment]::SetEnvironmentVariable('MSBuildTools14.0_x86_Path', 'C:\\Program Files (x86)\\MSBuild\\14.0\\Bin', [EnvironmentVariableTarget]::Machine);
RUN [Environment]::SetEnvironmentVariable('MSBuildTools14.0_x64_Path', 'C:\\Program Files (x86)\\MSBuild\\14.0\\Bin\\amd64', [EnvironmentVariableTarget]::Machine);
#install ms-build
#first install chocolatey

RUN iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))";

#secondly install build tools dependencies
RUN Install-WindowsFeature NET-Framework-45-ASPNET ; \  
    Install-WindowsFeature Web-Asp-Net45;
RUN choco install dotnet4.6-targetpack --allow-empty-checksums -y;
RUN choco install nuget.commandline --allow-empty-checksums -y;
RUN choco install git.install -y --allow-empty-checksums -version 2.11.1;
RUN nuget install MSBuild.Microsoft.VisualStudio.Web.targets -Version 14.0.0.3; \
nuget install WebConfigTransformRunner -Version 1.0.0.1;

RUN cp -recurse 'C:\MSBuild.Microsoft.VisualStudio.Web.targets.14.0.0.3\tools\VSToolsPath\*' 'C:\Program Files (x86)\MSBuild\12.0\'
RUN mkdir 'C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0\'
RUN mkdir 'C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v12.0\'
RUN cp -recurse 'C:\Program Files (x86)\MSBuild\12.0\*' 'C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v12.0\'
RUN cp -recurse 'C:\Program Files (x86)\MSBuild\12.0\*' 'C:\Program Files (x86)\MSBuild\Microsoft\VisualStudio\v14.0\'
 
# Move to install directory
WORKDIR $INSTALL

# Downloads dependencies
# Prepare application for waiting for java processes when the agent is started.
COPY jre-8u144-windows-x64.tar.gz $INSTALL
COPY ICSharpCode.SharpZipLib.dll $INSTALL
COPY downloadJre.ps1 $INSTALL

RUN ./downloadJre.ps1 -Uri "http://download.oracle.com/otn-pub/java/jdk/8u144-b01/090f390dda5b47b9b721c7dfaa008135/jre-8u144-windows-x64.tar.gz" -OutDest "$Env:BUILDAGENT/jre"; \
    Invoke-WebRequest  "$Env:TEAMCITY_AGENT_SERVER/update/buildAgent.zip" -OutFile "buildAgent.zip"; \
    Expand-Archive buildAgent.zip -DestinationPath $Env:BUILDAGENT

# Post job for preparing the teamcity agent
    RUN New-Item $Env:BUILDAGENT/work -ItemType directory -Force | Out-Null; \
    Rename-Item $Env:BUILDAGENT/conf conf.bak;
RUN mkdir $Env:BUILDAGENT/conf;

VOLUME $BUILDAGENT/conf
VOLUME $BUILDAGENT/logs
VOLUME $BUILDAGENT/work

WORKDIR $BUILDAGENT

# Clean up
RUN Remove-Item $Env:INSTALL -Recurse -Force

EXPOSE 9090

COPY runAgent.ps1 $SCRIPTS
# Run the agent
CMD & "$Env:SCRIPTS/runAgent.ps1"
