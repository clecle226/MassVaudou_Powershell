Add-Type -AssemblyName System.IO.Compression.FileSystem
.\Helper.ps1

#[System.IO.Compression.ZipFile]::ExtractToDirectory( $ziparchive, $extractpath )

$ListProject = Get-ChildItem -Path ".\" | ?{ $_.PSIsContainer } | Select-Object
$ListProject = $ListProject.Name.Split([Environment]::NewLine)

If ($ListProject -notcontains "platform-tools")
{  
    "Téléchargement de platform-tools (SDK Android)"
    Invoke-WebRequest -Uri "https://dl.google.com/android/repository/platform-tools-latest-windows.zip" -OutFile ".\adb.zip"
    [System.IO.Compression.ZipFile]::ExtractToDirectory( ".\adb.zip", ".\" )
    Remove-Item –path ".\adb.zip"
    Clear-Host
}

$ListProject =  $ListProject | Where-Object { ($_-ne "platform-tools") -and ( $_-ne "logs") }
do{
    Write-Host "---------------Merci de choisir un projet pour l'enrollement-----------" -ForegroundColor Green
    $i = 1
    foreach ($item in $ListProject){
        "$i - $item"
        $i++
    }
    $id = Read-Host 'Projet'
    $i =1
    $Project = ""
    foreach ($item in $ListProject){
        if($i -eq [int]$id){
            $Project = $item
        }
        $i++
    }
}while ($Project -eq "")
#$Project

function ListDeviceWaitUnauthorized{
    $ListDevice = (.\platform-tools\adb.exe devices)
    $ListDevice = $ListDevice.Split([Environment]::NewLine)
    $ListDeviceToEnroll = @()
    $unauthorizedWait = $False
    foreach ($item in $ListDevice -match "^(.*) *(device|unauthorized)$")
    {
        $item -match "^(.*) *(device|unauthorized)$" | Out-Null
        $matches[1] = $matches[1].Trim()
        if ($matches[2] -eq "device")
        {
            $ListDeviceToEnroll = $ListDeviceToEnroll+ $matches[1]
        }
        if ($matches[2] -eq "unauthorized")
        {
            Write-Host ($matches[1]+" Non autoriser, merci d'autoriser ADB sur le telephone (Renvoie d'un appel de connection)") -ForegroundColor "Red"
            .\platform-tools\adb.exe -s $matches[1] reconnect offline | Out-Null
            $unauthorizedWait = $True
        }
    }
    if($unauthorizedWait)
    {

        Read-Host "Valider toutes les autorisations ADB avant de conitnuer"
        $ListDeviceToEnroll = ListDeviceWaitUnauthorized 
    }
    return $ListDeviceToEnroll 
}
$ListTerminaux = ListDeviceWaitUnauthorized

Write-Host "Voici la liste des terminaux detecté" -ForegroundColor Green
$ListTerminaux
Write-Host "Lancement du Script $Project" -ForegroundColor Green
Write-Host "Attente confirmation utilisateur" -ForegroundColor Magenta
Pause
$ListTerminaux | Where-Object{ 
    Start-Process powershell.exe -Argumentlist  "-File .\Launcher.ps1 -NameProject $Project -SerialNumber $_"
}
