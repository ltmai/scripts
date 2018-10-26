
param (
    [String]$inputFile,
    [String]$outputFile
)

Write-Output "Trimming trailing spaces in file"

$lines = [System.IO.File]::ReadAllLines( $inputFile )
$expression = "*PL/SQL*"

try
{
    $stream = [System.IO.StreamWriter] ( $outputFile )
    $lines  | Where-Object {$_ -NotLike $expression} | ForEach-Object{ $stream.WriteLine( $_.TrimEnd() ) }
}
finally
{
    $stream.close()
}
