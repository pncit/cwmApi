function Initialize-CwmApiEnvironment {
    [CmdletBinding(DefaultParameterSetName = 'byVersion')]
    param (
        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
        [ValidateSet("au","eu","na")]
        [string]
        $apiRegion,

        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
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
        [validateNotNullorEmpty()]
        [string]$publicKey,

        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
        [validateNotNullorEmpty()]
        [string]$privateKey,

        [Parameter(Mandatory=$True,ParameterSetName = "byVersion")]
        [Parameter(Mandatory=$True,ParameterSetName = "byXml")]
        [validateNotNullorEmpty()]
        [string]$clientId
    )

    #get structure
    if ( ( $PSBoundParameters.ContainsKey( 'version')  ) -eq $true ) {
        $structureXmlFileUrl = switch( $version ) {
            "2020.4" { "https://raw.githubusercontent.com/pncit/cwmApi/main/data/cwmApi_2020.4.xml" }
            default { $null }
        }
        if ( $null -eq $structureXmlFileUrl ) {
            Throw "Unable to find xml file for requested version ($version)"
        }
        $structureXmlFile = "$home\_cwmStructure_temp.xml"
        (New-Object System.Net.WebClient).DownloadFile( $structureXmlFileUrl , $structureXmlFile )
        $structure = Import-Clixml -Path $structureXmlFile
        Remove-Item $structureXmlFile
        if ( $structure.version -ne $version ) {
            Throw "Version in file $structureXmlFileUrl ($($structure.version)) does not match requested version ($version)."
        }
    } else {
        $structure = Import-Clixml -Path $structureXmlFile
    }

    #get api version info
    $versionCode = $structure.version
    $codebase = 'v' + $versionCode.replace( '.' , '_' );

    #get api url
    $apiUri = "api-$apiRegion.myconnectwise.net/$codebase/apis/3.0/"
    
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
    $Script:cwmApiUri = $apiUri
    $Script:cwmApiVersionCode = $versionCode
    $Script:cwmApiAuthString = $authString
    $Script:cwmApiClientId = $clientId
    $Script:cwmApiQueries = $structure.queries
    $Script:cwmApiGetEntityParameter = New-EntityDynamicParameter -entityList $structure.getEntityList
    $Script:cwmApiPutEntityParameter = New-EntityDynamicParameter -entityList $structure.putEntityList
    $Script:cwmApiPostEntityParameter = New-EntityDynamicParameter -entityList $structure.postEntityList
    $Script:cwmApiPatchEntityParameter = New-EntityDynamicParameter -entityList $structure.patchEntityList
    $Script:cwmApiDeleteEntityParameter = New-EntityDynamicParameter -entityList $structure.deleteEntityList
}