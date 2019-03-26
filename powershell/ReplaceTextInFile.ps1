
param (
    [String]$inputFile,
    [String]$outputFile
)

Write-Output "Replace text in file"

$lines = [System.IO.File]::ReadAllLines( $inputFile )

try
{
    $stream = [System.IO.StreamWriter] ( $outputFile )
    $lines | ForEach-Object { 
        if ($_) {
            $stream.WriteLine( $_.Replace("`"LAM`".", "").Replace("`"", "") )
        }
        else {
            $stream.WriteLine( $_ ) 
        }
    }
}
finally
{
    $stream.close()
}
