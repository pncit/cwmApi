# Offline regression checks; no Pester installation or API credentials required.
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$catalogPath = Join-Path $repoRoot 'data/cwmApi_2026.11.xml'
$temporaryCatalog = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())

function Assert-Equal($Actual, $Expected, [string]$Message) {
    if ($Actual -cne $Expected) {
        throw "$Message (expected '$Expected', got '$Actual')"
    }
}

try {
    $catalog = Import-Clixml $catalogPath
    Assert-Equal $catalog.version '2026.11' 'Catalog version'

    # PowerShell 7 is needed only for spec parsing and catalog generation.
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        . (Join-Path $repoRoot 'functions/Set-CwmApiStructure.ps1')
        foreach ($version in @('2025.1', '2026.11')) {
            $jsonPath = Join-Path $repoRoot "data/cwmApi_$version.json"
            $spec = Get-Content $jsonPath -Raw | ConvertFrom-Json -AsHashtable
            Set-CwmApiStructure -jsonFile $jsonPath -xmlFile $temporaryCatalog
            $generated = Import-Clixml $temporaryCatalog
            $committed = Import-Clixml (Join-Path $repoRoot "data/cwmApi_$version.xml")
            Assert-Equal $generated.version $version 'Generated catalog version'
            $paths = @($spec.paths.GetEnumerator() | Where-Object { $_.Key -notlike '*regex*' })
            Assert-Equal $generated.queries.Count $paths.Count 'Generated path count'
            Assert-Equal $committed.queries.Count $paths.Count 'Committed path count'
            foreach ($structure in @($generated, $committed)) {
                # Ordinal comparison keeps the case-distinct AllowedFileTypes paths separate.
                $queries = [Collections.Generic.Dictionary[string, object]]::new([StringComparer]::Ordinal)
                foreach ($query in $structure.queries) { $queries.Add($query.Endpoint, $query) }
                foreach ($path in $paths) {
                    if (-not $queries.ContainsKey($path.Key)) { throw "Missing path $($path.Key)" }
                    $query = $queries[$path.Key]
                    foreach ($method in @('get', 'put', 'post', 'patch', 'delete')) {
                        $tag = $null
                        if ($path.Value[$method]) {
                            $tag = ($path.Value[$method].tags -join '').Replace('{', '').Replace('}', '')
                        }
                        Assert-Equal $query.$method $tag "$method tag for $($path.Key)"
                    }
                    foreach ($parameter in @('id', 'parentId', 'grandparentId', 'catalogItemIdentifier', 'externalId', 'reportName', 'memberRecId', 'reportlink')) {
                        # Older committed catalogs predate the two new flags.
                        if ($version -eq '2025.1' -and $parameter -in @('memberRecId', 'reportlink')) { continue }
                        Assert-Equal $query.$parameter ($path.Key -like "*{$parameter}*") "$parameter flag for $($path.Key)"
                    }
                }
                foreach ($method in @('get', 'put', 'post', 'patch', 'delete')) {
                    $expected = @($paths | ForEach-Object { if ($_.Value[$method]) { $_.Value[$method].tags } } | ForEach-Object { $_.Replace('{', '').Replace('}', '') } | Sort-Object -Unique)
                    $actual = @($structure."${method}EntityList")
                    Assert-Equal ($actual -join '|') ($expected -join '|') "$method entity list for $version"
                }
            }
        }
        Write-Host 'PASS: generated and committed catalogs match the 2025.1 and 2026.11 specifications.'
    }

    $manifest = Test-ModuleManifest (Join-Path $repoRoot 'cwmApi/cwmApi.psd1')
    Assert-Equal $manifest.Version.ToString() '1.6.2' 'Module version'
    $module = Import-Module (Join-Path $repoRoot 'cwmApi/cwmApi.psd1') -Force -PassThru
    # Replace only the network boundary inside the module. All request building,
    # dynamic parameters, endpoint selection and initialization run as shipped.
    & $module {
        param($RepoRoot)
        $script:TestRepoRoot = $RepoRoot
        $script:TestCompanyVersion = '2026.11'
        $script:TestRequests = @()
        $script:TestDownloads = @()
        function script:Invoke-WebRequest {
            param($Uri, $Method, $ContentType, $Headers, $Body, [switch]$UseBasicParsing, [switch]$AllowInsecureRedirect)
            if ($Uri -eq 'https://na.myconnectwise.net/login/companyinfo/test-company') {
                return [pscustomobject]@{ Content = (@{ SiteUrl = 'example.invalid'; VersionCode = "v$script:TestCompanyVersion" } | ConvertTo-Json) }
            }
            if ($Uri -notlike 'https://example.invalid/*') { throw "Unexpected request: $Uri" }
            $request = [pscustomobject]@{ Uri = $Uri; Method = $Method; Headers = $Headers; Body = $Body }
            $script:TestRequests += $request
            return [pscustomobject]@{ StatusCode = 200; Content = '{"id":123}'; Headers = @{} }
        }
        function script:New-Object {
            param([Parameter(Position=0)][string]$TypeName, [Parameter(Position=1)][object[]]$ArgumentList)
            if ($TypeName -eq 'System.Net.WebClient') {
                $client = [pscustomobject]@{}
                $client | Add-Member ScriptMethod DownloadFile {
                    param($Uri, $Destination)
                    $script:TestDownloads += $Uri
                    $filename = ($Uri -split '/')[-1]
                    Copy-Item (Join-Path $script:TestRepoRoot "data/$filename") $Destination
                }
                return $client
            }
            Microsoft.PowerShell.Utility\New-Object @PSBoundParameters
        }
    } $repoRoot
    $credentials = @{ company = 'test-company'; publicKey = 'public'; privateKey = 'private'; clientId = 'client' }
    foreach ($selection in @('explicit', 'automatic', 'local', 'legacy')) {
        $parameters = $credentials.Clone()
        $expectedVersion = '2026.11'
        switch ($selection) {
            'explicit' { $parameters.version = '2026.11' }
            'local' { $parameters.structureXmlFile = $catalogPath }
            'legacy' { $parameters.version = '2025.1'; $expectedVersion = '2025.1' }
        }
        Initialize-CwmApiEnvironment @parameters
        Assert-Equal (& $module { $script:cwmApiVersionCode }) $expectedVersion "$selection version selection"
        Get-CwmApiEntity -Entity ExpenseReports -id 123 | Out-Null
        $request = & $module { $script:TestRequests[-1] }
        Assert-Equal $request.Uri 'https://example.invalid/v4_6_release/apis/3.0//expense/reports/123?pageSize=1000' 'Existing expense-report lookup remains unambiguous'
        Assert-Equal $request.Headers.Accept "application/vnd.connectwise.com+json; version=$expectedVersion" 'API version header'
    }
    $downloads = & $module { $script:TestDownloads }
    Assert-Equal ($downloads -join '|') ('https://raw.githubusercontent.com/pncit/cwmApi/main/data/cwmApi_2026.11.xml|https://raw.githubusercontent.com/pncit/cwmApi/main/data/cwmApi_2026.11.xml|https://raw.githubusercontent.com/pncit/cwmApi/main/data/cwmApi_2025.1.xml') 'Version-specific catalog URLs'
    Initialize-CwmApiEnvironment @credentials -structureXmlFile $catalogPath

    $cases = @(
        @{ Run = { Get-CwmApiEntity -Entity CompanyServiceTemplates -parentId 10 }; Method = 'get'; Path = '/company/companies/10/serviceTemplates?pageSize=1000' }
        @{ Run = { Get-CwmApiEntity -Entity TicketContactAuthentications -id 11 }; Method = 'get'; Path = '/service/tickets/authstatus/11?pageSize=1000' }
        @{ Run = { Get-CwmApiEntity -Entity ExpenseReports -id 123 -memberRecId 456 }; Method = 'get'; Path = '/expense/reports/123/attachments/456?pageSize=1000' }
        @{ Run = { New-CwmApiEntity -Entity Reports -id 12 -bodyJson '{}' }; Method = 'post'; Path = '/system/standardreport/12' }
        @{ Run = { New-CwmApiEntity '{}' 12 '' '' 'standardreport' -Entity Reports }; Method = 'post'; Path = '/system/standardreport/12' }
        @{ Run = { New-CwmApiEntity -Entity Reports -reportlink 'My Report/Detail' -bodyJson '{}' }; Method = 'post'; Path = '/system/standardreport/My%20Report%2FDetail' }
        @{ Run = { Get-CwmApiEntity -Entity AllowedFileType }; Method = 'get'; Path = '/system/allowedfiletypes/?pageSize=1000' }
        @{ Run = { New-CwmApiEntity -Entity AllowedFileType -bodyJson '{}' }; Method = 'post'; Path = '/system/AllowedFileTypes/' }
        @{ Run = { New-CwmApiEntity -Entity ServiceTemplateResources -parentId 10 -bodyJson '{}' }; Method = 'post'; Path = '/service/templates/10/resources' }
        @{ Run = { Set-CwmApiEntity -Entity ServiceTemplateResources -parentId 10 -id 11 -bodyJson '{}' }; Method = 'put'; Path = '/service/templates/10/resources/11' }
        @{ Run = { Edit-CwmApiEntity -Entity ServiceTemplateResources -parentId 10 -id 11 -op replace -path hours -value 2 }; Method = 'patch'; Path = '/service/templates/10/resources/11' }
        @{ Run = { Remove-CwmApiEntity -Entity ServiceTemplateTasks -parentId 10 -id 11 }; Method = 'delete'; Path = '/service/templates/10/tasks/11' }
    )
    foreach ($case in $cases) {
        & $case.Run | Out-Null
        $request = & $module { $script:TestRequests[-1] }
        Assert-Equal $request.Method $case.Method "HTTP method for $($case.Path)"
        Assert-Equal $request.Uri ("https://example.invalid/v4_6_release/apis/3.0/" + $case.Path) 'Request URI'
        Assert-Equal $request.Headers.Accept 'application/vnd.connectwise.com+json; version=2026.11' 'API version header'
    }
    Write-Host 'PASS: explicit, automatic, local and legacy initialization; new endpoints; all five HTTP methods.'
} finally {
    Remove-Item $temporaryCatalog -ErrorAction SilentlyContinue
    Remove-Module cwmApi -ErrorAction SilentlyContinue
}
