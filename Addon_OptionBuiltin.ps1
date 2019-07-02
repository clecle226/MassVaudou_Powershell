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
	$result = "'$result'"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put secure sysui_qs_tiles $result"
}

function DesactivationOptionDeveloppement{param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Désactivation Option de developpement'"
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.settings/.Settings$\DevelopmentSettingsActivity" | Out-Null
    $ScreenForDoubleClick = GetScreen -SerialNumber $SerialNumber
    $CoordButtonBack = FoundCoordByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='android:id/action_bar']/*[@index='1']",".//*[@content-desc=`"Remonter d'un niveau`"]") -ScreenBack $ScreenForDoubleClick
    $CoordButtonDev = FoundCoordByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.android.settings:id/switch_bar']",".//*[@text='Activé']") -ScreenBack $ScreenForDoubleClick
    [int]$MidXButtonDev = ([int]$CoordButtonDev["Left"]+[int]$CoordButtonDev["Right"])/2
    [int]$MidYButtonDev = ([int]$CoordButtonDev["Up"]+[int]$CoordButtonDev["Down"])/2
    [int]$MidXButtonBack = ([int]$CoordButtonBack["Left"]+[int]$CoordButtonBack["Right"])/2
    [int]$MidYButtonBack = ([int]$CoordButtonBack["Up"]+[int]$CoordButtonBack["Down"])/2
    SendCommandShell -SerialNumber $SerialNumber -Command "input tap $MidXButtonDev $MidYButtonDev & sleep 2 & input tap $MidXButtonBack $MidYButtonBack"

}

function DesactiverRotationAuto{param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Désactivation de la rotation auto'"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put system accelerometer_rotation 0" | Out-Null
    $retourLocation = SendCommandShell -SerialNumber $SerialNumber -Command "settings get system accelerometer_rotation"
    If($retourLocation -match "0")
    {
        Write-Host "Rotation auto désactivé" -ForegroundColor Green
    }
    ElseIf($retourLocation -match "1"){
        Write-Host "Impossible de désactivé la rotation auto" -ForegroundColor Red
    }
    else {
        Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
    }
}
function DesactivationLocalisation{param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Desactivation de la localisation'"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put secure location_providers_allowed -gps" | Out-Null
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put secure location_providers_allowed -network" | Out-Null
    $retourLocation = SendCommandShell -SerialNumber $SerialNumber -Command "settings get secure location_providers_allowed"
    If(([string]::IsNullOrWhiteSpace($retourLocation)))
    {
        Write-Host "Position désactivé" -ForegroundColor Green
    }
    Else{
        Write-Host "Impossible de désactivé la position" -ForegroundColor Red
    }
}
function OptionActifEnChargement{param( [String]$SerialNumber, [bool]$Enabled = $true)
    If($Enabled)
    {
        Write-Host "Envoie commande de 'Activation de Actif en chargement'"
        SendCommandShell -SerialNumber $SerialNumber -Command "svc power stayon ac"
    }
    else {
        Write-Host "Envoie commande de 'Désactivation de Actif en chargement'"
        SendCommandShell -SerialNumber $SerialNumber -Command "svc power stayon false"
    }
    Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
}
function Option_SetMiseEnVeille{param( [String]$SerialNumber, [String]$TimeOut = "30")
    Write-Host "Envoie commande de 'Config Mise en veille à $TimeOut secondes'"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put system screen_off_timeout ${TimeOut}000" | Out-Null #Valeur en millisecondes
    $RetourVeille = SendCommandShell -SerialNumber $SerialNumber -Command "settings get system screen_off_timeout"
    If($RetourVeille -match "${TimeOut}000")
    {
        Write-Host "Mise en veille mis à $TimeOut secondes avec succée" -ForegroundColor Green
    }
    ElseIf(-not ([string]::IsNullOrWhiteSpace($RetourVeille)))
    {
        Write-Host "Erreur pour la modification de la mise en veille: Merci de corriger Manuellement" -ForegroundColor Red
    }
    Else{
        Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
    }
}
function DesactiverBluetooth{param( [String]$SerialNumber)
    ##disable bluetooth
    Write-Host "Envoie commande de 'Desactivation Bluetooth'"
    SendCommandShell -SerialNumber $SerialNumber -Command "service call bluetooth_manager 9" | Out-Null
    $retourBluetooth = (SendCommandShell -SerialNumber $SerialNumber -Command "dumpsys bluetooth_manager").split("`r`n") |Select-String -Pattern "^  enabled: (true|false)"
    If($retourBluetooth -match "false")
    {
        Write-Host "Bluetooth désactivé avec succée" -ForegroundColor Green
    }
    ElseIf($retourBluetooth -match "true")
    {
        Write-Host "Erreur dans la désactivation du bluetooth: Merci de corriger Manuellement" -ForegroundColor Red
    }
    Else{
        Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
    }
    
}
function ChangePinTerminal{param( [String]$SerialNumber, [String]$CodePin)
    #lock_screen_show_notifications in secure (à vérifier)
    #show_note_about_notification_hiding=0
    ##Set PIN
    Write-Host "Changer le code PIN du terminal pour $CodePin"
    $RetourCommande = SendCommandShell -SerialNumber $SerialNumber -Command "locksettings set-pin $CodePin"
    #"test $RetourCommande"
    #$RetourCommande
    #$RetourCommande -match 'Error while executing command: set-pin'
    #$Matches
    if($RetourCommande -match 'Error while executing command: set-pin')
    {
        Write-Host "Erreur dans la création de Code PIN: Merci de corriger Manuellement" -ForegroundColor Red

    }
    ElseIf($RetourCommande -match "Pin set to '$CodePin'")
    {
        Write-Host "Code Pin changé" -ForegroundColor Green
    }
    Else{
        Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
    }
    
}