# No Advertising

WGRC's default is **no Windows advertising or promotional content** where Windows exposes a documented policy that can disable it without breaking gaming.

Default suppression covers:

- Microsoft consumer experiences
- cloud-optimized consumer content on supported Enterprise/Education
- cloud consumer account-state content
- Windows Spotlight and welcome promotion on supported editions
- third-party suggestions
- tailored experiences
- Windows tips
- Advertising ID
- Widgets/news
- Start Recommended
- personalized website recommendations
- account-related Start nags
- Search highlights
- web results in Windows Search on supported Enterprise/Education

Exact mappings are in `configuration/policies.psd1`.

Primary Microsoft sources:

- https://learn.microsoft.com/windows/client-management/mdm/policy-csp-experience
- https://learn.microsoft.com/windows/client-management/mdm/policy-csp-start
- https://learn.microsoft.com/windows/client-management/mdm/policy-csp-notifications
- https://learn.microsoft.com/windows/client-management/mdm/policy-csp-newsandinterests
- https://learn.microsoft.com/windows/client-management/mdm/policy-csp-search
- https://learn.microsoft.com/windows/client-management/mdm/policy-csp-privacy

WGRC does not patch proprietary launcher binaries, DNS, hosts files or certificates to remove in-launcher advertising. Launcher UIs do not auto-start; Playnite is the front door.

## Microsoft Edge

The bundled browser is included in the no-ad posture through documented Edge policy:

- Microsoft content on the New Tab page: off
- Shopping Assistant/coupon/price-comparison banners: off
- feature recommendations and assistance banners: off
- default top-site tiles: hidden
- first-run promotional experience: hidden

Sources:

- https://learn.microsoft.com/deployedge/microsoft-edge-policies/newtabpagecontentenabled
- https://learn.microsoft.com/deployedge/microsoft-edge-policies/edgeshoppingassistantenabled
- https://learn.microsoft.com/deployedge/microsoft-edge-policies/showrecommendationsenabled
- https://learn.microsoft.com/deployedge/microsoft-edge-policies/newtabpagehidedefaulttopsites
- https://learn.microsoft.com/deployedge/microsoft-edge-policies/hidefirstrunexperience
