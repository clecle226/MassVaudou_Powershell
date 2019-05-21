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
	#$result = $result.replace("(", "\\(")
    #$result = $result.replace(")", "\\)")
    Write-Host $result -ForegroundColor Yellow
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put secure sysui_qs_tiles '$result"
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
function Option_SetMiseEnVeille{param( [String]$SerialNumber, [String]$TimeOut = "30")
    Write-Host "Envoie commande de 'Config Mise en veille à $TimeOut secondes'"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings put system screen_off_timeout $TimeOut"+"000" #Valeur en millisecondes
    Write-Host "Pas retour commande, merci de vérifier" -ForegroundColor Magenta
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