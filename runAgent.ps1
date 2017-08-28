# Avoid to continue if an error occurred
trap {
    Write-Error $_
    exit 1
}

$configFiles = Get-ChildItem $Env:BUILDAGENT/conf

if($configFiles.Length -lt 1)
{
    Copy-Item $Env:BUILDAGENT/conf.bak/* $Env:BUILDAGENT/conf
    $lines = (Get-Content "$Env:BUILDAGENT/conf/buildAgent.dist.properties").replace('http://localhost:8111/', "$Env:TEAMCITY_SERVER");
    $lines += 'MSBuildTools14.0_x86_Path=C\:\\Windows\\Microsoft.NET\\Framework\\v4.0.30319';
    $lines += 'MSBuildTools12.0_x86_Path=C\:\\Program Files (x86)\\MSBuild\\12.0\\Bin';
    $lines += 'SdkToolsPath=C\:\Program Files (x86)\\Microsoft SDKs\\Windows\\v10.0A\\bin\\NETFX 4.6 Tools';
    Set-Content $Env:BUILDAGENT/conf/buildAgent.dist.properties $lines;
    Rename-Item $Env:BUILDAGENT/conf/buildAgent.dist.properties $Env:BUILDAGENT/conf/buildAgent.properties;
}

& "$Env:BUILDAGENT/bin/agent.bat" @("start")

# Wait for the others java processes created by the batch script.
while ($true) {
    Wait-Process -Name "java"   
    Start-Sleep 2
}