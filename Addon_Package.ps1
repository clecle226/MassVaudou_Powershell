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
        $result = CallADB -SerialNumber $SerialNumber -Command "install -g -r $PathApk"
    }
    else {
        Write-Host "Installation de $NameApp"
        $result = CallADB -SerialNumber $SerialNumber -Command "install -r $PathApk"
    }
    if($result -match "Success")
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
    <#$ListResult = $Result.Split([Environment]::NewLine)
    $i = 0
    foreach ($package in $ListPackagesName)
    {
        if($ListResult[$i] -match "SUCCESS")
        {
            Write-Host "Le package $package a bien été désinstallé." -ForegroundColor Green
        }
        else {
            Write-Host "ERROR: Le package $package n'a pas été désisntallé. Msg: " -ForegroundColor Red
            Write-Host $ListResult[$i]
        }
        $i +=1
    }#>
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
        if((FoundNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Mettez à jour votre compte pour continuer à installer des applications sur Google Play.']").length -ne 0 )
        {
            #Correction de la PUTAIN DE PROCEDURE non A4W
            ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='CONTINUER']", ".//*[@resource-id='com.android.vending:id/footer1']")
            ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='PASSER']", ".//*[@resource-id='com.android.vending:id/secondary_button']")
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
