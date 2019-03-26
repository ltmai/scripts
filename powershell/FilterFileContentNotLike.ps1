# Filter lines not like given expression.
# To invoke from command-line: 
# C:\> powershell -file ngrep "*PL/SQL*" filename.dat

param (
    [String]$expression,
    [String]$inputFile
)

$lines = [System.IO.File]::ReadAllLines( $inputFile )
$lines | Where-Object {$_ -NotLike $expression} | ForEach-Object { Write-Output "$_" }