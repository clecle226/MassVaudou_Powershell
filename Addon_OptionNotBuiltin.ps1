function Option_DisableSoundKeyboard{
    param( [String]$SerialNumber)
    Write-Host "Envoie commande de 'Désactivation son de numérotatione et de clavier'"
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.settings/com.android.settings.Settings$\SoundSettingsActivity" | Out-Null
    
    if(ADBGetProperty -SerialNumber $SerialNumber -Property "ro.build.version.release" -eq "9")
    {
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Sons système']/.." | Out-Null
        $resultNum = ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Son du pavé de numérotation']/../..//*[@text='Activé' and @resource-id='android:id/switch_widget']/.."
        $resultClavier = ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Son du clavier']/../..//*[@text='Activé' and @resource-id='android:id/switch_widget']/.."
        if($resultNum)
        {
            Write-Host "L'option 'Son pavé de numérotation' à été désactivé" -ForegroundColor Green
        }
        else {
            Write-Host "ERROR: L'option 'Sons pavé de numérotation' n'a PAS été désactivé" -ForegroundColor Red
        }
        if($resultClavier)
        {
            Write-Host "L'option 'Son du clavier' à été désactivé" -ForegroundColor Green
        }
        else {
            Write-Host "ERROR: L'option 'Son du clavier' n'a PAS été désactivé" -ForegroundColor Red
        }
        if($resultNum -and $resultClavier)
        {
            return $true
        }
        else {
            return $false
        }
        
    }
    else #Old version (before 9)
    {
        [String]$TmpScreen = ""
        do{
            [bool]$OutWhile = $false
            $ScreenBack = GetScreen -SerialNumber $SerialNumber
             
            if($TmpScreen -eq $ScreenBack.InnerXML)
            {
                $OutWhile = $True
            }
            else {
                $TmpScreen = $ScreenBack.InnerXML
            }
            $resultSoundKeyboard = FoundCoordByXPath -SerialNumber $SerialNumber -ScreenBack $ScreenBack -XPath ".//*[@text='Son du clavier']/../..//*[@resource-id='android:id/switch_widget']"
            $resultSoundNumboard = FoundCoordByXPath -SerialNumber $SerialNumber -ScreenBack $ScreenBack -XPath ".//*[@text='Sons pavé de numérotation']/../..//*[@resource-id='android:id/switch_widget']"
            Write-Host $resultSoundNumboard
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
function DropMTPMessage {
    param( [String]$SerialNumber, [Diagnostics.Stopwatch]$TimeOut = [Diagnostics.Stopwatch]::StartNew())
    if(ADBGetProperty -SerialNumber $SerialNumber -Property "ro.build.version.release" -ne "9")
    {
        Write-Host "Wait MTP message" -ForegroundColor DarkGray
        ###Message MTP attente Anti-Bug// TimeOut: 1min MAX
        while ((-Not (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@package='com.samsung.android.MtpApplication']/node[@resource-id='android:id/button1']")) -and ($TimeOut.Elapsed.TotalSeconds -lt 60)){
            Start-Sleep -Seconds 1
            Write-Host ([math]::Round(($TimeOut.Elapsed.TotalSeconds - 60)*-1))"secondes remaining" -ForegroundColor Magenta
            
        }
    }
    else {
        Write-Host "Pas de message MTP en 9.x.x" -ForegroundColor DarkGray
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
function DisabledTexteIntuitifAndEnabledCorrectionOrthographique{ param( [String]$SerialNumber)
    SendCommandShell -SerialNumber $SerialNumber -Command "am start --user 0 -n com.android.settings/.Settings$\GeneralDeviceSettingsActivity" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Langue et saisie']" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text=`"Clavier à l'écran`"]" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Clavier Samsung']" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Saisie intelligente']" | Out-Null
    $TexteIntuitif = ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Texte intuitif']/../..//*[@text='Activé' and @resource-id='android:id/switch_widget']/.."
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Vérification orthographique auto.']" | Out-Null
    $CorrectOrtho = ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Français (FR)']/../..//*[@text='Désactivé' and @resource-id='android:id/switch_widget']/.."
    if($TexteIntuitif)
    {
        Write-Host "L'option 'Texte intuitif' à été désactivé" -ForegroundColor Green
    }
    else {
        Write-Host "ERROR: L'option 'Texte intuitif' n'a PAS été désactivé" -ForegroundColor Red
    }
    if($CorrectOrtho)
    {
        Write-Host "L'option 'Correction orthographique' à été activé" -ForegroundColor Green
    }
    else {
        Write-Host "ERROR: L'option 'Correction orthographique' n'a PAS été activé" -ForegroundColor Red
    }
    if($TexteIntuitif -and $CorrectOrtho)
    {
        return $true
    }
    else {
        return $false
    }
}