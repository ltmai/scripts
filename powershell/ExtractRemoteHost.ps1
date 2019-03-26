# this script reads the output of "netstat -abon" and finds all HTTP connections
# .\ExtractRemoteHost.ps1 .\netstat_20180917.txt output.txt 8992 80 

param (
    [String]$inputFile,
    [String]$outputFile,
    [Int]$processId,
    [Int]$portNumber
)

try
{
    $stream = [System.IO.StreamWriter] ( $outputFile )
    
    # filters out all lines containing that process Id and port number as whole word
    # converts Microsoft.PowerShell.Commands.MatchInfo to System.String
    # splits the lines removing empties ("TCP", "0.0.0.0:80", "0.0.0.0:0", "LISTENING", "1956")
    # write the remote host at index 2
    [System.IO.File]::ReadLines($inputFile) | Select-String -pattern $processid | Select-String -pattern "\b:$portNumber\b" | ForEach-Object {
        $line = $_.ToString()
        $remoteHost = ($line.split(" ", [System.StringsplitOptions]::RemoveEmptyEntries))[2]
        $stream.WriteLine( $remoteHost )
    }
}
finally
{
    $stream.close()
}
