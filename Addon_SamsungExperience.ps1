function SamsungExperience_EraseAllPage{param([String]$SerialNumber, [bool]$DisabledBixby = $true) #Bixby or alias(briefing/upday ....)
    SendCommandShell -SerialNumber $SerialNumber -Command "am start -n com.sec.android.app.launcher/com.sec.android.app.launcher.activities.LauncherActivity" | Out-Null

    #Verifier si com.sec.android.app.launcher:id/home_view
    if((FoundNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_view']").length -gt 0 )
    {
        #SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_view']" -Orientation "Down" -Ration 0.8
        SlideByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/apps_content']" -Orientation "Down" | Out-Null

    }

    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/home_page_indicator']" --LongClick $True | Out-Null

    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@resource-id='com.sec.android.app.launcher:id/home_page_indicator']/*[last()]" | Out-Null
    ClickOnNodeByXPath -SerialNumber $SerialNumber -XPath ".//*[@content-desc='Ajouter une page, Bouton']" | Out-Null
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