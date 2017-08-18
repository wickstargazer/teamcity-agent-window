param([Parameter(Mandatory=$True, Position=0)] $Uri, [Parameter(Mandatory=$True, Position=1)] $OutDest)

# Avoid to continue if an error occurred
trap {
    Write-Error $_
    exit 1
}

# Download the SharpZipLib nuget package
# Add-Type -AssemblyName "System.IO.Compression"
# $httpWebRequest = [System.Net.HttpWebRequest]::Create("https://www.nuget.org/api/v2/package/SharpZipLib/0.86.0")
# $response = $httpWebRequest.GetResponseAsync().Result
# $stream = $response.GetResponseStream()

# Extract the DLL from the nuget package
# $zipArchive = New-Object System.IO.Compression.ZipArchive($stream)
# $entry = $zipArchive.GetEntry("lib/20/ICSharpCode.SharpZipLib.dll")
$sharpZipStream = [System.IO.File]::OpenRead("ICSharpCode.SharpZipLib.dll")
 $memoryStream = New-Object System.IO.MemoryStream
 $sharpZipStream.CopyTo($memoryStream)

# Release resources allocated to extract the lib
# $zipArchive.Dispose()
# $response.Dispose()
# $stream.Dispose()
# $sharpZipStream.Dispose()

# Load the assembly in memory
 [System.Reflection.Assembly]::Load($memoryStream.ToArray())

# Release the stream containing the lib
# $memoryStream.Dispose()
# Add-Type -AssemblyName "ICSharpCode.SharpZipLib"

# Install Java
$stream = [System.IO.File]::OpenRead("jre-8u144-windows-x64.tar.gz")
#$reader = [SharpCompress.Readers.ReaderFactory]::Open($stream)

 #While ($reader.MoveToNextEntry())
 #       {
 #           if (!$reader.Entry.IsDirectory)
 #           {
 #               $output = [System.IO.File]::OpenWrite($OutDest + "\" + $reader.Entry.Key )
 #               $reader.WriteEntryTo($output)
 #           }
 #           else
 #           {
 #              [System.IO.Directory]::CreateDirectory($OutDest + "\" + $reader.Entry.Key)
 #           }
 #       }

# Unzip the tar archive into the given destination
 $gzipStream = New-Object ICSharpCode.SharpZipLib.GZip.GZipInputStream($stream)
 $tarArchive = [ICSharpCode.SharpZipLib.Tar.TarArchive]::CreateInputTarArchive($gzipStream)
 $tarArchive.ExtractContents($OutDest)

# Release resources
 $tarArchive.Close()
 $tarArchive.Dispose()
 $gzipStream.Dispose()

$stream.Dispose()
# $reader.Dispose()

# $response.Dispose()