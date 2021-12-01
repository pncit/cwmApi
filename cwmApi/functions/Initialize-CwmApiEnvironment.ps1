function Initialize-CwmApiEnvironment {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    param (
        [Parameter(Mandatory=$False,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$False,ParameterSetName = "byXml")]
        [Parameter(Mandatory=$False,ParameterSetName = "Default")]
        [ValidateSet("au","eu","na")]
        [string]
        $apiRegion,

        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
        [Parameter(Mandatory=$True,ParameterSetName = "Default")]
        [validateNotNullorEmpty()]
        [string]
        $company,

        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [validateNotNullorEmpty()]
        [string]
        $version,

        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
        [validateNotNullorEmpty()]
        [string]
        $structureXmlFile,

        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
        [Parameter(Mandatory=$True,ParameterSetName = "Default")]
        [validateNotNullorEmpty()]
        [string]$publicKey,

        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
        [Parameter(Mandatory=$True,ParameterSetName = "Default")]
        [validateNotNullorEmpty()]
        [string]$privateKey,

        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
        [Parameter(Mandatory=$True,ParameterSetName = "Default")]
        [validateNotNullorEmpty()]
        [string]$clientId
    )
    Write-Verbose "Initiating cwmAPI session..."

    #get company api info
    Write-Verbose "Getting $company info..."
    $companyApiInfo = ( Invoke-WebRequest -uri "https://na.myconnectwise.net/login/companyinfo/$company" -UseBasicParsing ).Content | ConvertFrom-Json
    $companyUrl = $companyApiInfo.SiteUrl
    $companyVersion = $companyApiInfo.VersionCode.substring(1)
    if ( ( $PSBoundParameters.ContainsKey( 'version') ) -eq $false ) {
        $version = $companyVersion
    }
    Write-Debug -Message "Company URL: $companyUrl"
    Write-Debug -Message "Company Version: $companyVersion"
    Write-Debug -Message "Requested Version: $version"

    #get structure
    Write-Verbose "Getting api structure..."
    if ( ( $PSBoundParameters.ContainsKey( 'structureXmlFile') ) -eq $false ) {
        $structureXmlFileUrl = switch( $version ) {
            "2020.4" { "https://raw.githubusercontent.com/pncit/cwmApi/main/data/cwmApi_2020.4.xml" }
            "2021.1" { "https://raw.githubusercontent.com/pncit/cwmApi/main/data/cwmApi_2021.1.xml" }
            "2021.2" { "https://raw.githubusercontent.com/pncit/cwmApi/main/data/cwmApi_2021.2.xml" }
            "2021.3" { "https://raw.githubusercontent.com/pncit/cwmApi/main/data/cwmApi_2021.3.xml" }
            default { $null }
        }
        if ( $null -eq $structureXmlFileUrl ) {
            Throw "Unable to find xml file for requested version ($version)"
        }
        Write-Debug -Message "StructureXmlFileUrl: $structureXmlFileUrl"
        $tmp = [System.IO.Path]::GetTempPath()
        $structureXmlFile = Join-Path $tmp "_cwmStructure_temp.xml"
        (New-Object System.Net.WebClient).DownloadFile( $structureXmlFileUrl , $structureXmlFile )
        $structure = Import-Clixml -Path $structureXmlFile
        Remove-Item $structureXmlFile
        if ( $structure.version -ne $version ) {
            Throw "Version in file $structureXmlFileUrl ($($structure.version)) does not match requested version ($version)."
        }
    } else {
        if ( Test-Path $structureXmlFile ) {
            $structure = Import-Clixml -Path $structureXmlFile
        } else {
            Throw "Unable to find requested structure file ($structureXmlFile)"
        }
    }

    #get api version info
    $version = $structure.version
    Write-Debug -Message "Version: $version"

    if ( $companyVersion -ne $version) {
        Write-Verbose "Default API version for $company is $companyVersion, but requested version is $version. Using $version as requested."
    }

    #get api url
    $codebase = 'v4_6_release';
    $apiUri = "$companyUrl/$codebase/apis/3.0/"
    Write-Debug -Message "apiUri: $apiUri"
    #get auth string
    $user = "$company+$publicKey"
    $pass = $privateKey
    $pair = "${user}:${pass}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $authString = "Basic $base64"

    function New-EntityDynamicParameter {
        Param (
        [Parameter(Mandatory=$True)]
        [validateNotNullorEmpty()]
        $entityList
        )

        $ParameterName = "Entity"
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $AttributeCollection.Add($ParameterAttribute)
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($entityList)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }
    
    #save data to variables
    Write-Verbose "Compiling script variables..."
    $Script:cwmApiUri = $apiUri
    $Script:cwmApiVersionCode = $version
    $Script:cwmApiAuthString = $authString
    $Script:cwmApiClientId = $clientId
    $Script:cwmApiQueries = $structure.queries
    Write-Verbose "Compiling dynamic parameters..."
    $Script:cwmApiGetEntityParameter = New-EntityDynamicParameter -entityList $structure.getEntityList
    $Script:cwmApiPutEntityParameter = New-EntityDynamicParameter -entityList $structure.putEntityList
    $Script:cwmApiPostEntityParameter = New-EntityDynamicParameter -entityList $structure.postEntityList
    $Script:cwmApiPatchEntityParameter = New-EntityDynamicParameter -entityList $structure.patchEntityList
    $Script:cwmApiDeleteEntityParameter = New-EntityDynamicParameter -entityList $structure.deleteEntityList
    Write-Verbose "cwmAPI session initiated."
}