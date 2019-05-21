param( [String]$SerialNumber, [String] $NameProject)

. .\Helper.ps1

Start-Transcript -path ".\logs\$NameProject - $SerialNumber.rtf" -Append

"IMEI de l'appareil: "
GetIMEI -SerialNumber $SerialNumber
$TimeMTP = [Diagnostics.Stopwatch]::StartNew()

& .\$NameProject\Master.ps1


Stop-Transcript
pause
