function AdbDevice {
    .\platform-tools\adb.exe devices
   }
function ADBGetProperty{
    param( [String]$SerialNumber, [String]$Property)
    return .\platform-tools\adb.exe -s $SerialNumber shell getprop $Property
}
function GetIMEI{param( [String]$SerialNumber)
    $rawResult = SendCommandShell -SerialNumber $SerialNumber -Command "service call iphonesubinfo 1"
    $result =($rawResult | select-string -pattern "'(.*?)'" -AllMatches).Matches.Value
    $tradParcell = $result -join ""
    $tradParcell = $tradParcell.Replace(".","")
    $tradParcell = $tradParcell.Replace("'","")
    return $tradParcell
}
function FoundCoordByXPath{param( [String]$SerialNumber, $XPath, [xml]$ScreenBack = "")
    if ($XPath.GetType().Name -eq "String")
    {
        $XPath = @($XPath)
    }
    if([string]::IsNullOrWhiteSpace($ScreenBack.Value))
    {
        do{
            (.\platform-tools\adb.exe -s $SerialNumber exec-out uiautomator dump /dev/tty) -match '<.*>' | Out-Null
        }while ($matches.Length -eq 0)
        [xml]$ScreenBack = $matches[0]
    }

    $i = 0
    Do {
        $ListNode = Select-Xml -Xml $ScreenBack -XPath $XPath[$i] #Filtre XML Only
        $i = $i+1
    }
    while(($ListNode.Length -eq 0) -and ($i -lt $XPath.Length ))

    if ($ListNode.Length -eq 0)
    {
        return $False
    }
    $ResultClick = $ListNode[0].Node.OuterXml
    $Valid = $ResultClick -match "\[(?<Left>\d*),(?<Up>\d*)\]\[(?<Right>\d*),(?<Down>\d*)\]"

    If ($Valid)
    {
        return $matches
    }
}

function SlideByXPath{param( [String]$SerialNumber, $XPath, [xml]$ScreenBack = "", [String]$Orientation, [float]$Ratio=1)#Orientation = Up,Down,Left,Right
    $result = FoundCoordByXPath -SerialNumber $SerialNumber -XPath $XPath -ScreenBack $ScreenBack
    if($result.Length -ne $false)
    {
        [int]$MidX = ([int]$result["Left"]+[int]$result["Right"])/2
        [int]$MidY = ([int]$result["Up"]+[int]$result["Down"])/2
        #Correction varraible en enlevant 5% du chiffre
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

do{

    $resultScreen =  .\platform-tools\adb.exe -s $SerialNumber exec-out uiautomator dump /dev/tty

    $resultScreen -match '<.*>' | Out-Null
}while ($matches.Length -eq 0)
[xml]$result = $matches[0]

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
    $retour = .\platform-tools\adb.exe -s $SerialNumber shell $Command
    return $retour
}


function ClearTextEdit {
    param( [String]$SerialNumber, [String]$IdTextEdit)
    (.\platform-tools\adb.exe -s $SerialNumber exec-out uiautomator dump /dev/tty) -match '<.*>' | Out-Null
    [xml]$result = $matches[0]
    
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
        .\platform-tools\adb.exe -s $SerialNumber --sync push $PathSource $PathDestination
    }
    else {
        .\platform-tools\adb.exe -s $SerialNumber push $PathSource $PathDestination
    }
}
function ChangeWallpaper{ param( [String]$SerialNumber, [String] $Path ,[bool]$EcranAccueil = $True, [bool]$EcranVerrouillage = $True)
    Write-Host  "Change wallpaper"
    $NamePictures = ($Path.split("\"))[-1]
    PushFile -SerialNumber $SerialNumber -PathSource $Path -PathDestination '/sdcard/Pictures' -Sync $false | Out-Null
    if($EcranAccueil -and $EcranVerrouillage){
        SendCommandShell -SerialNumber $SerialNumber -Command "am start --user 0 -n com.sec.android.wallpapercropper2/com.sec.android.wallpapercropper2.BothCropActivity -d file:///sdcard/Pictures/$NamePictures" | Out-Null
    }
    elseif ($EcranAccueil){
        SendCommandShell -SerialNumber $SerialNumber -Command "am start --user 0 -n com.sec.android.wallpapercropper2/.HomeCropActivity -d file:///sdcard/Pictures/$NamePictures" | Out-Null
    }
    elseif ($EcranVerrouillage){
        SendCommandShell -SerialNumber $SerialNumber -Command "am start --user 0 -n  com.sec.android.wallpapercropper2/.KeyguardCropActivity -d file:///sdcard/Pictures/$NamePictures" | Out-Null
    }
	
    Start-Sleep -Seconds 1
    if(ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.sec.android.wallpapercropper2:id/save']",".//*[@resource-id='com.sec.android.wallpapercropper2:id/confirm_button']"))
    {
        Write-Host "Change Wallpaper success" -ForegroundColor Green 
    }
    else
    {
        Write-Host "Change Wallpaper failed" -ForegroundColor Red
    }
}


. .\Addon_OptionBuiltin.ps1
. .\Addon_OptionNotBuiltin.ps1
. .\Addon_Package.ps1
. .\Addon_WebBrowser.ps1

