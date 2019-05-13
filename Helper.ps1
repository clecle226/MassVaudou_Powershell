function AdbDevice {
    .\platform-tools\adb.exe devices
   }
function ADBGetProperty{
    param( [String]$SerialNumber, [String]$Property)
    return .\platform-tools\adb.exe -s $SerialNumber shell getprop $Property
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
param( [String]$SerialNumber, $XPath)

if ($XPath.GetType().Name -eq "String")
{
    $XPath = @($XPath)
}

do{
(.\platform-tools\adb.exe -s $SerialNumber exec-out uiautomator dump /dev/tty) -match '<.*>' | Out-Null
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
    
    SendCommandShell -SerialNumber $SerialNumber -Command "input tap $MidX $MidY"
    If ($AntiBug.Length -ne 0)
    {
        return ClickOnNodeByXPath -SerialNumber $SerialNumber -Xpath $XPath
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
function InstallApks {
    param( [String]$SerialNumber, [Object]$PathApk, [bool] $Granted = $false)
    foreach ($item in $PathApk)
    {
        InstallApk -SerialNumber $SerialNumber -PathApk $item -Granted $Granted
    }
}
function InstallApk {
    param( [String]$SerialNumber, [String]$PathApk, [bool] $Granted = $false)
    $NameApp = ($PathApk.split("\"))[-1]
    $NameApp = $NameApp.Replace(".apk","")
    if($Granted)
    {  
        Write-Host "Installation de $NameApp avec Granted"
        $result = .\platform-tools\adb.exe -s $SerialNumber install -g -r $PathApk
    }
    else {
        Write-Host "Installation de $NameApp"
        $result = .\platform-tools\adb.exe -s $SerialNumber install -r $PathApk
    }
    if($result -contains "Success")
    {
        Write-Host "Installation de $NameApp éffectué avec succés" -ForegroundColor Green
    }
    else{
        Write-Host "Error: Installation de $NameApp à échoué" -ForegroundColor Red
    }

}

function UninstallPackages {
    param( [String]$SerialNumber, [Object]$ListPackagesName)
    #$Msg = "'"
	$i = 1
    foreach ($package in $ListPackagesName)
    {
		if ($i -ne 1){
            $Msg += " && "
        }
		$Msg += "pm uninstall "+$package
        $i +=1
    }
	#$Msg += "'"
    SendCommandShell -SerialNumber $SerialNumber -Command $Msg
}
function DisabledPackages {
    param( [String]$SerialNumber, [Object]$ListPackagesName)
    #$Msg = "'"
	$i = 1
    foreach ($package in $ListPackagesName)
    {
		if ($i -ne 1){
            $Msg += " && "
        }
		$Msg += "pm disable-user "+$package
        $i +=1
    }
	#$Msg += "'"
    SendCommandShell -SerialNumber $SerialNumber -Command $Msg
}    

function InstallationByPlayStore {
    param( [String]$SerialNumber, [Object]$ListPackagesName)
    foreach ($package in $ListPackagesName)
    {
        [bool]$ResultPackage = $false
        SendCommandShell -SerialNumber $SerialNumber -Command "am start -a android.intent.action.VIEW -d 'market://details?id=$package'" | Out-Null
        $ResultPackage =ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='INSTALLER']", ".//*[@resource-id='com.android.vending:id/button_container']/node[last()]")
        if (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='ACCEPTER']", ".//*[@resource-id='com.android.vending:id/continue_button']"))
        {
            Start-Sleep -Seconds 2
        }

        if($ResultPackage)
        {
            Write-Host "Installation du Package '$package' avec success" -ForegroundColor Green
        }
        else {
            Write-Host "ERROR: Erreur l'ors de l'installation du Package '$package', Merci de l'installer manuellement" -ForegroundColor Red
        }
            
    }
}

function CreateWebsiteShortcutChrome {
    param( [String]$SerialNumber, [String]$Adresse = "google.com", [String]$Name = "Test%sWhitespace")

    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.chrome/com.google.android.apps.chrome.Main -d $Adresse" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/menu_button']" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.android.chrome:id/app_menu_list']//*[@text=`"Ajouter à l'écran d'accueil`"]",".//*[@resource-id='com.android.chrome:id/app_menu_list']/*[@index='9']") | Out-Null
    
    ClearTextEdit -SerialNumber $SerialNumber -IdTextEdit "com.android.chrome:id/text" | Out-Null
    $NameParsed = ($Name).replace(" ", "%s")
    SendCommandShell -SerialNumber $SerialNumber -Command "input text $NameParsed" 
    $Verif1 = ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='android:id/button1']"
    $Verif2 = ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/add_item_add_button']"
    if($Verif1 -and $Verif2)
    {
        Write-Host "Create shortcut chrome successful: $Name" -ForegroundColor Green
    }
    elseif($Verif1 -or $Verif2)
    {
        Write-Host "Verify shortcut chrome successful: $Name" -ForegroundColor Yellow
    }
    else {
        Write-Host  "Create shortcut chrome failed: $Name"-ForegroundColor Red
    }
    SendCommandShell -SerialNumber $SerialNumber -Command "am force-stop com.android.chrome"
}
function InitialisationChrome {
    param( [String]$SerialNumber, [bool]$DisableStatistique = $True, [bool]$UtilisationAccount = $True)

	SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.chrome/com.google.android.apps.chrome.Main" | Out-Null
	if ($DisableStatistique){
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/send_report_checkbox']" | Out-Null
    }
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/terms_accept']" | Out-Null

	if ($UtilisationAccount){
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/positive_button']" | Out-Null
		while (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/more_button']"){#Plus de la synchronisation
            Start-Sleep -Seconds 1
        }
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/positive_button']" | Out-Null
    } else {
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/negative_button']" | Out-Null
    }
    SendCommandShell -SerialNumber $SerialNumber -Command "am force-stop com.android.chrome"  | Out-Null
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
function DropMTPMessage {
    param( [String]$SerialNumber, [Diagnostics.Stopwatch]$TimeOut = [Diagnostics.Stopwatch]::StartNew())
    Write-Host "Wait MTP message" -ForegroundColor DarkGray
    ###Message MTP attente Anti-Bug// TimeOut: 1min MAX
    while ((-Not (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@package='com.samsung.android.MtpApplication']/node[@resource-id='android:id/button1']")) -and ($TimeOut.Elapsed.TotalSeconds -lt 60)){
        Start-Sleep -Seconds 1
        Write-Host ([math]::Round(($TimeOut.Elapsed.TotalSeconds - 60)*-1))"secondes remaining" -ForegroundColor Magenta
        
    }
}

function DesactiverRotationAuto{param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Desactivation de la rotation'"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put system accelerometer_rotation 0"
    Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
}
function DesactivationLocalisation{param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Desactivation de la localisation'"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put secure location_providers_allowed -gps"
    Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
}
function OptionActifEnChargement{param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Activation de Actif en chargement'"
    SendCommandShell -SerialNumber $SerialNumber -Command "svc power stayon ac"
    Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
}
function Option_GooglePlay_Maj4G{param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Google play: Toux réseaux'"
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.vending/com.google.android.finsky.activities.SettingsActivity" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@index='3']" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.vending:id/auto_update_settings_always']" | Out-Null
    if(ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='android:id/button1']")
    {
        Write-Host "Activation Google Play 'Tous réseaux'" -ForegroundColor Green
    }
    else {
        Write-Host "IMPOSSIBLE d'activé Google Play 'Tous réseaux'" -ForegroundColor Red
    }
}
function Option_SetMiseEnVeille{param( [String]$SerialNumber, [String]$TimeOut = "30")
    Write-Host "Envoie commande de 'Config Mise en veille à $TimeOut secondes'"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put system screen_off_timeout $TimeOut"+"000" #Valeur en millisecondes
    Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
}

function Option_DisableSoundKeyboard{
    param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Désactivation son de numérotatione et de clavier'"
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.settings/com.android.settings.Settings$\SoundSettingsActivity" | Out-Null
    [String]$TmpScreen = ""
    do{
        [bool]$OutWhile = $false
        do{
            (.\platform-tools\adb.exe -s $SerialNumber exec-out uiautomator dump /dev/tty) -match '<.*>' | Out-Null
        }while ($matches.Length -eq 0)
        [xml]$ScreenBack = $matches[0]
         
        if($TmpScreen -eq $ScreenBack.InnerXML)
        {
            $OutWhile = $True
        }
        else {
            $TmpScreen = $ScreenBack.InnerXML
        }
        $resultSoundKeyboard = FoundCoordByXPath -SerialNumber $SerialNumber -ScreenBack $ScreenBack -XPath ".//*[@text='Son du clavier']/../..//*[@resource-id='android:id/switch_widget']"
        $resultSoundNumboard = FoundCoordByXPath -SerialNumber $SerialNumber -ScreenBack $ScreenBack -XPath ".//*[@text='Sons pavé de numérotation']/../..//*[@resource-id='android:id/switch_widget']"
        if($resultSoundKeyboard -eq $false -and $resultSoundNumboard -eq $false)
        {
            SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='android:id/content']" -Orientation "Up"  -ScreenBack $ScreenBack
        }
        elseif(($resultSoundKeyboard -ne $false -and $resultSoundNumboard -eq $false) -or ($resultSoundKeyboard -eq $false -and $resultSoundNumboard -ne $false))
        {
            SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='android:id/content']" -Orientation "Up" -Ratio 0.26  -ScreenBack $ScreenBack
            #if (SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Son du clavier']/../.." -Orientation "Up" -not)
            #{
            #    SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Sons pavé de numérotation']/../.." -Orientation "Up"
            #}
        }
        elseif($resultSoundKeyboard -ne $false -and $resultSoundNumboard -ne $false){
            [int]$MidXKeyboard = ([int]$resultSoundKeyboard["Left"]+[int]$resultSoundKeyboard["Right"])/2
            [int]$MidYKeyboard = ([int]$resultSoundKeyboard["Up"]+[int]$resultSoundKeyboard["Down"])/2
            [int]$MidXNumboard = ([int]$resultSoundNumboard["Left"]+[int]$resultSoundNumboard["Right"])/2
            [int]$MidYNumboard = ([int]$resultSoundNumboard["Up"]+[int]$resultSoundNumboard["Down"])/2

            $NodeSwitchKeyboard = (Select-Xml -Xml $ScreenBack -XPath ".//*[@text='Son du clavier']/../..//*[@resource-id='android:id/switch_widget']")[0]
            $NodeSwitchNumboard = (Select-Xml -Xml $ScreenBack -XPath ".//*[@text='Sons pavé de numérotation']/../..//*[@resource-id='android:id/switch_widget']")[0]
            if ($NodeSwitchKeyboard.Node.text -eq "Activé" -and $NodeSwitchNumboard.Node.text -eq "Activé")
            {
                SendCommandShell -SerialNumber $SerialNumber -Command "input tap $MidXKeyboard $MidYKeyboard && input tap $MidXNumboard $MidYNumboard"
                Write-Host "Les 2 options 'Son du clavier' et 'Sons pavé de numérotation' ont été désactivés" -ForegroundColor Green
                return $true
            }
            elseif($NodeSwitchKeyboard.Node.text -eq "Activé" -and $NodeSwitchNumboard.Node.text -eq "Désactivé")
            {
                SendCommandShell -SerialNumber $SerialNumber -Command "input tap $MidXKeyboard $MidYKeyboard "
                Write-Host "L'option 'Son du clavier' à été désactivé" -ForegroundColor Green
                Write-Host "L'option 'Sons pavé de numérotation' est déjà désactivé" -ForegroundColor Magenta
                return
                #return $true
            }
            elseif($NodeSwitchKeyboard.Node.text -eq "Désactivé" -and $NodeSwitchNumboard.Node.text -eq "Activé")
            {
                SendCommandShell -SerialNumber $SerialNumber -Command "input tap $MidXNumboard $MidYNumboard "
                Write-Host "L'option 'Sons pavé de numérotation' à été désactivé" -ForegroundColor Green
                Write-Host "L'option 'Son du clavier' est déjà désactivé" -ForegroundColor Magenta
                return
                #return $true
            }
            elseif($NodeSwitchKeyboard.Node.text -eq "Désactivé" -and $NodeSwitchNumboard.Node.text -eq "Désactivé")
            {
                Write-Host "Les 2 options 'Son du clavier' et 'Sons pavé de numérotation' sont déjà désactivés" -ForegroundColor Magenta
                return
                #return $true
            }
        }
    }while(-not $OutWhile)
    Write-Host "ERROR: Les 2 options 'Son du clavier' et 'Sons pavé de numérotation' n'ont PAS été désactivé" -ForegroundColor Red
    return
    #return $false
}

function DesactiverBluetooth{param( [String]$SerialNumber)
    ##disable bluetooth
    Write-Host "Envoie commande de 'Desactivation Bluetooth'"
    SendCommandShell -SerialNumber $SerialNumber -Command "service call bluetooth_manager 9" | Out-Null
    Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
}
function ChangePinTerminal{param( [String]$SerialNumber, [String]$CodePin)
    ##Set PIN
    Write-Host "Changer le code PIN du terminal pour $CodePin"
    SendCommandShell -SerialNumber $SerialNumber -Command "locksettings set-pin $CodePin"
    Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
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
function ChangeOrderShortcutAction{param( [String]$SerialNumber, [Object]$ListInOrder)
	$result = $ListInOrder
	#ActualListOrder = (subprocess.run("/usr/local/bin/adb settings get secure sysui_qs_tiles" capture_output=True)).stdout.decode('utf8')

    $ActualListOrder = SendCommandShell -SerialNumber $SerialNumber -Command "settings get secure sysui_qs_tiles"
	#Get ActualListOrder
	$ActualListOrder = $ActualListOrder.split(",")
	foreach ($item in $ActualListOrder){
		if ( $ListInOrder -notcontains $item){
            $result = $result + $item
        }
    }
	#Set result
	$result = $result -join ","
	$result += "'"
	$result = $result.replace("(", "\\(")
    $result = $result.replace(")", "\\)")
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put secure sysui_qs_tiles '$result"
}

	
function DefinirHomepageChrome{param( [String]$SerialNumber, [String]$Adresse = "google.com")
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.chrome/com.google.android.apps.chrome.Main -d $Adresse"

    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/menu_button']"
    ##Entrer dans parametres
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.android.chrome:id/app_menu_list']//*[@text='Paramètres']",".//*[@resource-id='com.android.chrome:id/app_menu_list']/*[@index='10']")
    ##Page D'accueil
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='android:id/list']//*[@text='Page d\'accueil']",".//*[@resource-id='android:id/list']/*[@index='6']")
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='android:id/list']//*[@text='Ouvrir cette page']",".//*[@resource-id='android:id/list']/*[@index='1']")

    ClearTextEdit -SerialNumber $SerialNumber -IdTextEdit "com.android.chrome:id/homepage_url_edit"
    SendCommandShell -SerialNumber $SerialNumber -Command "input text '$Adresse'"

    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/homepage_save']"
    SendCommandShell -SerialNumber $SerialNumber -Command "am force-stop com.android.chrome"

}
	

function GetIMEI{param( [String]$SerialNumber)
        $rawResult = SendCommandShell -SerialNumber $SerialNumber -Command "service call iphonesubinfo 1"
        $result =($rawResult | select-string -pattern "'(.*?)'" -AllMatches).Matches.Value
        $tradParcell = $result -join ""
        $tradParcell = $tradParcell.Replace(".","")
        $tradParcell = $tradParcell.Replace("'","")
        return $tradParcell
    }

function UninstallOrDisablePackages{param( [String]$SerialNumber, [Object]$ListPackagesName)
    UninstallPackages -SerialNumber $SerialNumber -ListPackagesName $ListPackagesName
    $ListPackage = (SendCommandShell -SerialNumber $SerialNumber -Command "pm list packages").Split([Environment]::NewLine)
	$disablePackage = @()
    foreach ($item in $ListPackage)
    {
        if ($ListPackagesName -contains $item.replace("package:", ""))
        {
            $disablePackage = $disablePackage +$item.replace("package:", "")
        }
    }
    Start-Sleep -Seconds 1
    DisabledPackages -SerialNumber $SerialNumber -ListPackagesName $disablePackage
}
function ChangeHomePageFirefox{
    #resource-id="org.mozilla.firefox:id/menu"
    #text="Paramètres"   #class="android.widget.ListView"//index="10"

}