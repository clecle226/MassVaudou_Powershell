function SamsungExperience_EraseAllPage{param([String]$SerialNumber, [bool]$DisabledBixby = $true) #Bixby or alias(briefing/upday ....)
    SendCommandShell -SerialNumber $SerialNumber -Command "input keyevent KEYCODE_HOME" | Out-Null

    <#Verifier si com.sec.android.app.launcher:id/home_view
    #am start -n com.sec.android.app.launcher/com.sec.android.app.launcher.activities.LauncherActivity & 
    if((FoundNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_view']").length -gt 0 )
    {
        #SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_view']" -Orientation "Down" -Ration 0.8
        SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_content']" -Orientation "Down" | Out-Null

    }#>

    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/home_page_indicator']" --LongClick $True | Out-Null

    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/home_page_indicator']/*[last()]" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@class='android.widget.ImageView' and @package='com.sec.android.app.launcher']",".//*[@content-desc='Ajouter une page, Bouton']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/home_page_indicator']/*[1]" | Out-Null
    if((FoundNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@class='android.widget.Switch']").length -gt 0 )
    {
        if($DisabledBixby)
        {
            ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@class='android.widget.Switch']" | Out-Null
        }
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/home_page_indicator']/*[2]" | Out-Null
    }

    while (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@content-desc='Supprimer']")
    {
        ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@text='SUPPRIMER']",".//*[@resource-id='android:id/button1']") | Out-Null
    }
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/workspace']" | Out-Null
    #SlideByXPath -SerialNumber $SerialNumber -XPath
    #$ListeNode = FoundNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/inactive']"

}

function Contact_ImportAllVcf{param([String]$SerialNumber)
    #jump com.samsung.android.contacts/com.samsung.contacts.activities.ContactFirstTimeUseActivity
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.samsung.android.contacts/com.android.contacts.activities.PeopleActivity" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.samsung.android.contacts:id/ImportButton']",".//*[@text='IMPORTER CONTACTS']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@text='Téléphone']" | Out-Null # Si compte google
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.android.packageinstaller:id/permission_allow_button']",".//*[@text='AUTORISER']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.samsung.android.contacts:id/select_all_wrapper']",".//*[@text='Tout']") | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath @(".//*[@resource-id='com.samsung.android.contacts:id/menu_done']",".//*[@text='OK']") | Out-Null
}

function CreateDirectoryApp{param([String]$SerialNumber, [Object]$ListApp, [String]$NameDir)
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.sec.android.app.launcher/com.sec.android.app.launcher.activities.LauncherActivity & input keyevent KEYCODE_HOME" | Out-Null
    SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/home_view']" -Orientation "Down"
    <#Verifier si com.sec.android.app.launcher:id/home_view
    if((FoundNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_view']").length -eq 0 )
    {
        #SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_view']" -Orientation "Down" -Ration 0.8
        SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_content']" -Orientation "Down" | Out-Null

    }#>
    #Desactiver idle animation
    $DefaultIDLE = SendCommandShell -SerialNumber $SerialNumber -Command "settings get global animator_duration_scale"
    SendCommandShell -SerialNumber $SerialNumber -Command "settings set global animator_duration_scale 0.0"

    #Selectionner 2 app dans la liste
    $i = 0
    $ScreenAppView = GetScreen -SerialNumber $SerialNumber
    $SelectedNode = @()
    $SelectedApp = $ListApp
    while($SelectedNode.length -lt 2)
    {
        $resultNode = FoundNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/iconview_titleView' and @text='${ListApp[$i]}']/.." -ScreenBack $ScreenAppView
        If($resultNode.length -ne 0)
        {
            $SelectedNode.Add($resultNode[0])
            $SelectedApp.Remove(${ListApp[$i]})
        }
        $i++
    }
    $ResultClick = $SelectedNode[0].Node.OuterXml
    $ResultClick -match "\[(?<Left>\d*),(?<Up>\d*)\]\[(?<Right>\d*),(?<Down>\d*)\]"
    [int]$MidX = ([int]$matches["Left"]+[int]$matches["Right"])/2
    [int]$MidY = ([int]$matches["Up"]+[int]$matches["Down"])/2
    SendCommandShell -SerialNumber $SerialNumber -Command "input swipe $MidX $MidY $MidX $MidY 650"
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/global_icon_text' and @text='Sélect. éléments']/.."
    $ResultClick = $SelectedNode[1].Node.OuterXml
    $ResultClick -match "\[(?<Left>\d*),(?<Up>\d*)\]\[(?<Right>\d*),(?<Down>\d*)\]"
    [int]$MidX = ([int]$matches["Left"]+[int]$matches["Right"])/2
    [int]$MidY = ([int]$matches["Up"]+[int]$matches["Down"])/2
    SendCommandShell -SerialNumber $SerialNumber -Command "input tap $MidX $MidY"

    #ClickCréerDossier
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/multi_select_create_folder_layout']"

    #Entrer Nom dossier
    SendCommandShell -SerialNumber $SerialNumber -Command "input text $NameDir & input keyevent KEYCODE_TAB"
    
    #Click Ajouter app
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/folder_add_button_container']"

    #Click on ALL APP
    $TmpScreen = GetScreen -SerialNumber $SerialNumber
    $SelectedApp = $SelectedApp | Sort-Object
    foreach($item in $SelectedApp)
    {
        if( -not (ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/list_item_text' and @text='$item']/.." -ScreenBack $TmpScreen))
        {
            #Si il arrive pas à clicker sur l'application, il click sur la première lettre dans l'index et il réessaye

        }

    }
    #Si Remise en ordre demander... Le faire (todo function for this)

    #Réactivation IDLE
    SendCommandShell -SerialNumber $SerialNumber -Command "settings set global animator_duration_scale $DefaultIDLE"

}