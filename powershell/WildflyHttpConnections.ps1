
param (
    [Int]$portNumber=80
)

# Returns process by name and command line
# e.g. processName = java, cmdLine=standalone
function GetProcessId()
{
	param(
		[parameter(position=0)]
		[String]$processName,
		
		[parameter(position=1)]
		[String]$cmdLine
	)
	
	$query = "name like '%" + $processName + "%' AND commandline like '%" + $cmdLine + "%'"

    (Get-WmiObject Win32_Process -Filter  $query | Select-Object ProcessId).ProcessId
}

# Invokes ToString() on input object
filter CallToString()
{
    $_.ToString()
}

# splits input string into tokens removing empty entries:
# input  = "TCP  0.0.0.0:80  10.180.31.230:65334  LISTENING   8992"
# output = "10.180.31.230:65334"
filter SplitLineTake2nd()
{
    ($_.split(" ", [System.StringsplitOptions]::RemoveEmptyEntries))[2]
}

# splits input string into tokens and take first entry
# input  = "10.180.31.230:65334"
# output = "10.180.31.230"
filter SplitRemoteHostTakeAddress()
{
    ($_.split(":"))[0]
}

$processId = GetProcessId -processName "java" -cmdLine "standalone"

$inputFile = "netstat.txt"
$outputFile = $(Get-Date -format 'ou\tpu\t_yyyymmdd_hhmmss.\tx\t')

if (! $processId) 
{
    Write-Host "Process not found!"
    Exit
}

try
{
    netstat -abon > netstat.txt
    
    $stream = [System.IO.StreamWriter] ( $outputFile )
    
    [System.IO.File]::ReadLines($inputFile)             |   
    Select-String -pattern $processId                   |
    Select-String -pattern "\b:$portNumber\b"           |
    CallToString                                        |
    SplitLineTake2nd                                    |
    SplitRemoteHostTakeAddress                          |
    Sort-Object -Unique                                 |
    ForEach-Object {
        Write-Host $_
        $stream.WriteLine( $remoteAddress )
    } 
}
finally
{
    $stream.close()
}
