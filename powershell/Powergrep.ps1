# powergrep.ps1 pattern wildcard

param (
    [String] $pattern,
    [String] $wildcard
)

Write-Host Pattern=$pattern
Write-Host Wildcard=$wildcard

$fileInfos = Get-ChildItem -File $wildcard

foreach ($fileInfo in $fileInfos) 
{
    Write-Host -ForegroundColor Green [$fileInfo]
    [System.IO.File]::ReadLines($fileInfo.Fullname) | Select-String -Pattern $pattern | ForEach-Object {
        # MatchInfo object
        Write-Host -ForegroundColor Green -NoNewline $_.LineNumber: 
        Write-Host $_.Line 
    }
}