# Connect To SharePoint Online Module. 

Connect-SPOService -Url https://carterjonasllp-admin.sharepoint.com/

# Create Site.

New-SPOSite -Url "https://carterjonasllp-admin.sharepoint.com/Test" -Owner "daniel.duna@carterjonas.co.uk" -StorageQuota 2048 -Title "Automated Test" -Template "Document Center"