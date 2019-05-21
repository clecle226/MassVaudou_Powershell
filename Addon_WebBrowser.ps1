function SelectDefaultNavigator{
    param( [String]$SerialNumber, [String]$Name = "Chrome")
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.settings/.Settings$\ManageApplicationsActivity"
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@class='android.widget.Button']",".//*[@content-desc='Options supplémentaires']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Applications par défaut']/../..",".//*[@class='android.widget.ListView']//*[index='1']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Application de navigation']/../..",".//*[@class='android:id/list']//*[index='0']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='$Name']/../..") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@class='android.widget.ImageButton']",".//*[@content-desc='Remonter d\'un niveau']") | Out-Null
    SendCommandShell -SerialNumber $SerialNumber -Command "am force-stop com.android.settings"
}

#Google Chrome

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
function CreateWebsiteShortcutChrome {
    param( [String]$SerialNumber, [String]$Adresse = "google.com", [String]$Name = "Test%sWhitespace")

    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.chrome/com.google.android.apps.chrome.Main -d $Adresse" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/menu_button']" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.android.chrome:id/app_menu_list']//*[@text='Ajouter à l'écran d'accueil']",".//*[@resource-id='com.android.chrome:id/app_menu_list']/*[@index='9']") | Out-Null
    
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

function DefinirHomepageChrome{param( [String]$SerialNumber, [String]$Adresse = "google.com")
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.android.chrome/com.google.android.apps.chrome.Main -d $Adresse"

    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/menu_button']"
    ##Entrer dans parametres
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.android.chrome:id/app_menu_list']//*[@text='Paramètres']/..",".//*[@resource-id='com.android.chrome:id/app_menu_list']/*[@index='10']")
    ##Page D'accueil
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='android:id/list']//*[@text='Page d&apos;accueil']",".//*[@resource-id='android:id/list']/*[@index='6']")
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='android:id/list']//*[@text='Ouvrir cette page']",".//*[@resource-id='android:id/list']/*[@index='1']")

    ClearTextEdit -SerialNumber $SerialNumber -IdTextEdit "com.android.chrome:id/homepage_url_edit"
    SendCommandShell -SerialNumber $SerialNumber -Command "input text '$Adresse'"

    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.android.chrome:id/homepage_save']"
    SendCommandShell -SerialNumber $SerialNumber -Command "am force-stop com.android.chrome"

}

#Mozilla Firefox
function DefinirHomepageFirefox{
    param( [String]$SerialNumber, [String]$Adresse = "google.com")
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n org.mozilla.firefox/org.mozilla.gecko.BrowserApp -d $Adresse" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/menu']" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Paramètres']",".//*[@class='android.widget.ListView']//*[index='11']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Général']/../..",".//*[@resource-id='android:id/list']/*[index='1']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Écran d’accueil']/../..",".//*[@resource-id='android:id/list']/*[index='0']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Définir une page d’accueil']/../..",".//*[@resource-id='android:id/list']/*[index='0']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/radio_user_address']" | Out-Null
    ClearTextEdit -SerialNumber $SerialNumber -IdTextEdit "org.mozilla.firefox:id/edittext_user_address" | Out-Null

    SendCommandShell -SerialNumber $SerialNumber -Command "input text '$Adresse'" | Out-Null

    If(ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='android:id/button1']",".//*[@text='OK']"))
    {
        Write-Host "Changement de la page d'accueil de Firefox par:  $Adresse" -ForegroundColor Green 
    }
    else
    {
        Write-Host "ERROR :Erreur lors du Changement de la page d'accueil de Firefox" -ForegroundColor Red
    }
    SendCommandShell -SerialNumber $SerialNumber -Command "am force-stop org.mozilla.firefox"
}
function CleanFavoriFirefox{
    param( [String]$SerialNumber)
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n org.mozilla.firefox/org.mozilla.gecko.BrowserApp" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/menu']" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Marque-pages']",".//*[@class='android.widget.ListView']//*[index='4']") | Out-Null
    while (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/bookmarks_list']/*[1]" -LongClick $true){
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Supprimer']/../..",".//*[@class='android.widget.ListView']/*[index='6']") | Out-Null
    }

    If(-not (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/bookmarks_list']/*[1]"))
    {
        Write-Host "Tous les marque-pages semblent avoir été supprimé (merci de vérifier)" -ForegroundColor Magenta 
    }
    else
    {
        Write-Host "ERROR :Erreur lors de la suppression des marque-pages" -ForegroundColor Red
    }
    SendCommandShell -SerialNumber $SerialNumber -Command "am force-stop org.mozilla.firefox"
}
function AddFavoriFirefox{
    param( [String]$SerialNumber, [String]$Adresse = "google.com", [String]$Name = "Test%sWhitespace")

    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n org.mozilla.firefox/org.mozilla.gecko.BrowserApp -d $Adresse" | Out-Null
    Start-Sleep -Seconds 2
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/menu']" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/bookmark']" | Out-Null
    if(-not (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/snackbar_action']"))
    {
        #Si il as pas réussi à cliquer sur le bouton option alors chemin long
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/menu']" | Out-Null
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Marque-pages']",".//*[@class='android.widget.ListView']//*[index='4']") | Out-Null
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='$Adresse']/../.." -LongClick $true | Out-Null
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='Modifier']/../..",".//*[@class='android.widget.ListView']/*[index='5']") | Out-Null
    }
    else {
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='android:id/text1']",".//*[@text='Modifier']") | Out-Null
    }
    ClearTextEdit -SerialNumber $SerialNumber -IdTextEdit "org.mozilla.firefox:id/edit_bookmark_name"
    $NameParsed = ($Name).replace(" ", "%s")
    SendCommandShell -SerialNumber $SerialNumber -Command "input text $NameParsed" 

    If(ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='org.mozilla.firefox:id/done']")
    {
        Write-Host "Le marque-page '$Name' a été créé sur Firefox avec succé" -ForegroundColor Green 
    }
    else
    {
        Write-Host "ERROR :Erreur lors de la création du marque-page '$Name'" -ForegroundColor Red
    }
    SendCommandShell -SerialNumber $SerialNumber -Command "am force-stop org.mozilla.firefox"
}