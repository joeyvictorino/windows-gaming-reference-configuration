@{
    Policies = @(
        @{
            Id='ads.consumer-experiences'; Name='Turn off Microsoft consumer experiences'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableWindowsConsumerFeatures'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress consumer suggestions and related promotional experiences.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.cloud-optimized-content'; Name='Turn off cloud optimized content'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableCloudOptimizedContent'
            Type='DWord'; Desired=1; Editions=@('Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Use fallback local experience instead of cloud-optimized consumer content.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.consumer-account-state'; Name='Turn off cloud consumer account state content'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableConsumerAccountStateContent'
            Type='DWord'; Desired=1; Editions=@('Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress cloud consumer account-state content without removing Xbox/account functionality.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.spotlight-all'; Name='Turn off Windows Spotlight features'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableWindowsSpotlightFeatures'
            Type='DWord'; Desired=1; Editions=@('Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Remove Spotlight tips/promotional surfaces without replacing user wallpaper.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.welcome'; Name='Turn off Windows Spotlight welcome experience'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableWindowsSpotlightWindowsWelcomeExperience'
            Type='DWord'; Desired=1; Editions=@('Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress post-update promotional welcome experiences.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.settings-spotlight'; Name='Turn off Windows Spotlight in Settings'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableWindowsSpotlightOnSettings'
            Type='DWord'; Desired=1; Editions=@('Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress Spotlight suggestions in Settings.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.action-center-spotlight'; Name='Turn off Spotlight suggestions in notification surfaces'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableWindowsSpotlightOnActionCenter'
            Type='DWord'; Desired=1; Editions=@('Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress Windows suggestion notifications.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.third-party-suggestions'; Name='Turn off third-party suggestions'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableThirdPartySuggestions'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress third-party app/content suggestions surfaced by Windows.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.tailored'; Name='Turn off tailored experiences with diagnostic data'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableTailoredExperiencesWithDiagnosticData'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Prevent diagnostic data from driving personalized tips/ads/recommendations.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.tips'; Name='Do not show Windows tips'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\CloudContent'; ValueName='DisableSoftLanding'
            Type='DWord'; Desired=1; Editions=@('Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress Windows soft-landing tips.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience'
        },
        @{
            Id='ads.advertising-id'; Name='Turn off advertising ID'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo'; ValueName='DisabledByGroupPolicy'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Disable the Windows advertising identifier without removing Store infrastructure.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-privacy'
        },
        @{
            Id='ads.widgets'; Name='Disable Widgets/news'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Dsh'; ValueName='AllowNewsAndInterests'
            Type='DWord'; Desired=0; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Remove Widgets/news from the gaming appliance experience.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-newsandinterests'
        },
        @{
            Id='ads.start-recommended'; Name='Hide Start Recommended section'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\Explorer'; ValueName='HideRecommendedSection'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22621
            Risk='Low'; Reason='Keep Start focused on intentional app choices.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-start'
        },
        @{
            Id='ads.start-sites'; Name='Hide personalized website recommendations in Start'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\Explorer'; ValueName='HideRecommendedPersonalizedSites'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22621
            Risk='Low'; Reason='Remove website recommendations from Start.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-start'
        },
        @{
            Id='ads.account-notifications'; Name='Turn off account-related notifications in Start'; Category='NoAds'; Mechanism='LGPO'
            Scope='User'; Key='SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\AccountNotifications'; ValueName='DisableAccountNotifications'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=26100
            Risk='Low'; Reason='Suppress Start nags about backup, quotas and subscription management.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-notifications'
        },
        @{
            Id='ads.search-highlights'; Name='Disable Search highlights'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\Windows Search'; ValueName='EnableDynamicContentInWSB'
            Type='DWord'; Desired=0; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Remove dynamic web/promotional content from Windows search.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-search'
        },
        @{
            Id='ads.search-web'; Name='Do not display web results in Windows Search'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\Windows Search'; ValueName='ConnectedSearchUseWeb'
            Type='DWord'; Desired=0; Editions=@('Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Make Windows Search local-first without touching browser/Xbox networking.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-search'
        },
        @{
            Id='privacy.required-diagnostics'; Name='Limit Windows diagnostic data to Required'; Category='Privacy'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\DataCollection'; ValueName='AllowTelemetry'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Preserve Windows supportability/security diagnostics while preventing Optional diagnostic collection.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/windows/client-management/mdm/policy-csp-system'
        },
        @{
            Id='privacy.wer-enabled'; Name='Keep Windows Error Reporting enabled'; Category='Reliability'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; ValueName='Disabled'
            Type='DWord'; Desired=0; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Preserve crash diagnostics instead of deleting error-reporting infrastructure.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/troubleshoot/windows-client/system-management-components/windows-error-reporting-diagnostics-enablement-guidance'
        },
        @{
            Id='privacy.wer-additional'; Name='Restrict unsolicited additional WER data'; Category='Privacy'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting'; ValueName='DontSendAdditionalData'
            Type='DWord'; Desired=1; Editions=@('Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Restrict additional error-reporting payloads while keeping WER operational.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/troubleshoot/windows-client/system-management-components/windows-error-reporting-diagnostics-enablement-guidance'
        },
        @{
            Id='gaming.game-mode'; Name='Enable Windows Game Mode'; Category='Gaming'; Mechanism='Preference'
            Scope='User'; Key='SOFTWARE\Microsoft\GameBar'; ValueName='AutoGameModeEnabled'
            Type='DWord'; Desired=1; Editions=@('Core','CoreN','Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Use the Windows gaming setting intended for Game Mode.'; PerformanceClaim='No universal FPS gain claimed.'
            Source='https://learn.microsoft.com/windows/apps/develop/settings/settings-windows-11'
        },
        @{
            Id='qol.file-extensions'; Name='Show filename extensions'; Category='QualityOfLife'; Mechanism='Preference'
            Scope='User'; Key='SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced'; ValueName='HideFileExt'
            Type='DWord'; Desired=0; Editions=@('Core','CoreN','Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Make file types explicit.'; PerformanceClaim='None'
            Source='Windows Settings equivalent: File Explorer > View > Show > File name extensions'
        },
        @{
            Id='ads.edge-newtab-content'; Name='Disable Microsoft content on Edge new tab page'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Edge'; ValueName='NewTabPageContentEnabled'
            Type='DWord'; Desired=0; Editions=@('Core','CoreN','Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Remove Microsoft feed/content from the Edge new tab page.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/deployedge/microsoft-edge-policies/newtabpagecontentenabled'
        },
        @{
            Id='ads.edge-shopping'; Name='Disable Microsoft Edge shopping assistant'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Edge'; ValueName='EdgeShoppingAssistantEnabled'
            Type='DWord'; Desired=0; Editions=@('Core','CoreN','Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Remove coupon, rebate, price-comparison and shopping banners.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/deployedge/microsoft-edge-policies/edgeshoppingassistantenabled'
        },
        @{
            Id='ads.edge-recommendations'; Name='Disable Edge feature recommendations'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Edge'; ValueName='ShowRecommendationsEnabled'
            Type='DWord'; Desired=0; Editions=@('Core','CoreN','Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress Edge recommendation dialogs, flyouts, coach marks and banners.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/deployedge/microsoft-edge-policies/showrecommendationsenabled'
        },
        @{
            Id='ads.edge-default-sites'; Name='Hide default top sites on Edge new tab page'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Edge'; ValueName='NewTabPageHideDefaultTopSites'
            Type='DWord'; Desired=1; Editions=@('Core','CoreN','Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Hide vendor-supplied default top-site tiles while preserving browser functionality.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/deployedge/microsoft-edge-policies/newtabpagehidedefaulttopsites'
        },
        @{
            Id='ads.edge-first-run'; Name='Hide Edge first-run experience'; Category='NoAds'; Mechanism='LGPO'
            Scope='Machine'; Key='SOFTWARE\Policies\Microsoft\Edge'; ValueName='HideFirstRunExperience'
            Type='DWord'; Desired=1; Editions=@('Core','CoreN','Professional','ProfessionalN','Enterprise','EnterpriseN','Education','EducationN'); MinBuild=22000
            Risk='Low'; Reason='Suppress first-run splash/promotional setup UI.'; PerformanceClaim='None'
            Source='https://learn.microsoft.com/deployedge/microsoft-edge-policies/hidefirstrunexperience'
        }
    )
}
