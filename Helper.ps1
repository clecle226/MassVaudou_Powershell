function AdbDevice {
    .\platform-tools\adb.exe devices
   }
function ADBGetProperty{
    param( [String]$SerialNumber, [String]$Property)
    return SendCommandShell -SerialNumber $SerialNumber -Command "getprop $Property"
}
function GetIMEI{param( [String]$SerialNumber)
    $rawResult = SendCommandShell -SerialNumber $SerialNumber -Command "service call iphonesubinfo 1"
    $result =($rawResult | select-string -pattern "'(.*?)'" -AllMatches).Matches.Value
    $tradParcell = $result -join ""
    $tradParcell = $tradParcell.Replace(".","")
    $tradParcell = $tradParcell.Replace("'","")
    return $tradParcell
}

function CallADB{param( [String]$SerialNumber, [String]$Command)
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo.FileName = (Convert-Path -Path ".")+"\platform-tools\adb.exe"
    #$p.StartInfo.WorkingDirectory = Convert-Path -Path "."
    $p.StartInfo.RedirectStandardOutput = $true
    $p.StartInfo.RedirectStandardError = $true
    $p.StartInfo.UseShellExecute = $false
    $p.StartInfo.Arguments = "-s $SerialNumber $Command"
    $p.StartInfo.WorkingDirectory = (Convert-Path -Path ".")

    $p.Start() | Out-Null

    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    while($stderr -match "error: device '.*' not found")
    {
        Write-Host "Attente de reconnexion de l'appareil. Merci!!!!"
        Start-Sleep -Seconds 3
        $p.Start() | Out-Null

        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
    }
    If(-not ([string]::IsNullOrWhiteSpace($stderr)))
    {
        Write-Host "Erreur du logiciel ADB: $stderr" -ForegroundColor DarkGray
        return "Error: $stderr `r`nSTDOUT: $stdout"
    }
    return $stdout
}

#function WaitReconnectDevice{param( [String]$SerialNumber)
#    $TestConnexion = .\platform-tools\adb.exe -s $SerialNumber shell ls 2>&1
#    while ($TestConnexion -match "error: device '.*' not found") {
#        Start-Sleep -Seconds 2
#        Write-Host "Attente de reconnexion de l'appareil. Merci!!!!"
#        $TestConnexion = .\platform-tools\adb.exe -s $SerialNumber shell  ls 2>&1
#    }
#    Start-Sleep -Seconds 4
#    $TestConnexion = .\platform-tools\adb.exe -s $SerialNumber shell ls /dev/tty 2>&1
#    if($TestConnexion -match "error: device '.*' not found")
#    {
#        WaitReconnectDevice -SerialNumber $SerialNumber
#    }
#
#}
function GetScreen{param( [String]$SerialNumber)
    do{
        [System.Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        $resultScreen = CallADB -SerialNumber $SerialNumber -Command "exec-out uiautomator dump /dev/tty"
        $resultScreen -match '<.*>' | Out-Null
    }while ($matches.Length -eq 0)
    [xml]$result = $matches[0]
    return $result
}
function FoundCoordByXPath{param( [String]$SerialNumber, $XPath, [xml]$ScreenBack = "")
    $ListNode = FoundNodeByXPath -SerialNumber $SerialNumber -XPath $XPath -ScreenBack $ScreenBack
    if ($ListNode.Length -gt 0)
    {
        $ResultClick = $ListNode[0].Node.OuterXml
        $Valid = $ResultClick -match "\[(?<Left>\d*),(?<Up>\d*)\]\[(?<Right>\d*),(?<Down>\d*)\]"
        If ($Valid)
        {
            return $matches
        }
        return $false
        
    }
}
function FoundNodeByXPath{param( [String]$SerialNumber, $XPath, [xml]$ScreenBack = "")   
    if ($XPath.GetType().Name -eq "String")
    {
        $XPath = @($XPath)
    }
    if([string]::IsNullOrWhiteSpace($ScreenBack.Value))
    {
        $ScreenBack = GetScreen -SerialNumber $SerialNumber
    }

    $i = 0
    Do {
        $ListNode = Select-Xml -Xml $ScreenBack -XPath $XPath[$i] #Filtre XML Only
        $i = $i+1
    }
    while(($ListNode.Length -eq 0) -and ($i -lt $XPath.Length ))
    return $ListNode

}

function SlideByXPath{param( [String]$SerialNumber, $XPath, [xml]$ScreenBack = "", [String]$Orientation, [float]$Ratio=1)#Orientation = Up,Down,Left,Right
    $result = FoundCoordByXPath -SerialNumber $SerialNumber -XPath $XPath -ScreenBack $ScreenBack
    if($result.Length -ne $false)
    {
        [int]$MidX = ([int]$result["Left"]+[int]$result["Right"])/2
        [int]$MidY = ([int]$result["Up"]+[int]$result["Down"])/2
        #Correction variable en enlevant 5% du chiffre
        [int]$Up = ([int]$result["Up"])*0.95*$Ratio
        [int]$Down = ([int]$result["Down"])*0.95*$Ratio
        [int]$Left = ([int]$result["Left"])*0.95*$Ratio
        [int]$Right = ([int]$result["Right"])*0.95*$Ratio
        If($Orientation = "Up")
        {
            SendCommandShell -SerialNumber $SerialNumber -Command "input swipe $MidX $Down $MidX $Up 1000"
        }
        elseif($Orientation = "Down")
        {
            SendCommandShell -SerialNumber $SerialNumber -Command "input swipe $MidX $Up $MidX $Down 1000"
        }
        elseif($Orientation = "Left")
        {
            SendCommandShell -SerialNumber $SerialNumber -Command "input swipe $Right $MidY $Left $MidY 1000"
        }
        elseif($Orientation = "Right")
        {
            SendCommandShell -SerialNumber $SerialNumber -Command "input swipe $Left $MidY $Right $MidY 1000"
        }
    }
    else{
        return $False
    }
}

function ClickOnNodeByXPath {
param( [String]$SerialNumber, $XPath, $LongClick = $False)

if ($XPath.GetType().Name -eq "String")
{
    $XPath = @($XPath)
}
$result = GetScreen -SerialNumber $SerialNumber

$ResultClick = ""
$AntiBug = Select-Xml -Xml $result -XPath ".//*[@package='com.samsung.android.MtpApplication']/node[@resource-id='android:id/button1']" #Filtre Anti-bug Message MTP
If ($AntiBug.Length -gt 0)
{
    $ResultClick = $AntiBug[0].Node.OuterXml
}
else
{
    $i = 0
    Do {

        $ListNode = Select-Xml -Xml $result -XPath $XPath[$i] #Filtre XML Only
        $i = $i+1
    }
    while(($ListNode.Length -eq 0) -and ($i -lt $XPath.Length ))
}
if ($ListNode.Length -eq 0)
{
    return $False
}
$ResultClick = $ListNode[0].Node.OuterXml
$Valid = $ResultClick -match "\[(?<Left>\d*),(?<Up>\d*)\]\[(?<Right>\d*),(?<Down>\d*)\]"

If ($Valid)
{
    [int]$MidX = ([int]$matches["Left"]+[int]$matches["Right"])/2
    [int]$MidY = ([int]$matches["Up"]+[int]$matches["Down"])/2
    
    if(-not $LongClick -or $AntiBug.Length -ne 0)
    {
        SendCommandShell -SerialNumber $SerialNumber -Command "input tap $MidX $MidY"
    }
    else {
        SendCommandShell -SerialNumber $SerialNumber -Command "input swipe $MidX $MidY $MidX $MidY 650"
    }

    If ($AntiBug.Length -ne 0)
    {
        return ClickOnNodeByXPath -SerialNumber $SerialNumber -Xpath $XPath -LongClick $LongClick
    }
    return $True
}
else {
    return $False
}


}
function SendCommandShell{
    param( [String]$SerialNumber, [String]$Command)
    return CallADB -SerialNumber $SerialNumber -Command "shell $Command"
}


function ClearTextEdit {
    param( [String]$SerialNumber, [String]$IdTextEdit)
    GetScreen -SerialNumber $SerialNumber
    
    $NbrChar = ((Select-Xml -Xml $result -XPath ".//*[@resource-id='$IdTextEdit']")[0]).Node.text.Length
    $repeatInput = ""
	$i = 0
	while( $i -le $NbrChar){
		$repeatInput += " KEYCODE_DEL"
		$i += 1
    }
    SendCommandShell -SerialNumber $SerialNumber -Command "input keyevent KEYCODE_MOVE_END"
    SendCommandShell -SerialNumber $SerialNumber -Command "input keyevent --longpress $repeatInput"

}

function PushFile{ param( [String]$SerialNumber, [String]$PathSource,  [String]$PathDestination, [bool]$Sync = $False)
    If($Sync)
    {
        CallADB -SerialNumber $SerialNumber -Command "--sync push $PathSource $PathDestination"
    }
    else {
        CallADB -SerialNumber $SerialNumber -Command "push $PathSource $PathDestination"
    }
}


#Include All Addon_ ...
$ListAddon = Get-ChildItem -Path ".\" | Select-Object
$ListAddon = $ListAddon.Name.Split([Environment]::NewLine)
$ListAddon =  $ListAddon | Where-Object { ($_ -match "Addon") }
foreach ($item in $ListAddon)
{
    . .\$item
}

