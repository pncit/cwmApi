function Set-CwmApiEnvironment {
    [CmdletBinding()]
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [ValidateSet("au","eu","na")]
        [string]
        $apiRegion,

        [Parameter(Mandatory=$True)]
        [validateNotNullorEmpty()]
        [string]
        $company,

        [Parameter(Mandatory=$True)]
        [validateNotNullorEmpty()]
        [string]
        $structureXmlFile,

        [Parameter(Mandatory=$True)]
        [validateNotNullorEmpty()]
        [string]$publicKey,

        [Parameter(Mandatory=$True)]
        [validateNotNullorEmpty()]
        [string]$privateKey,

        [Parameter(Mandatory=$True)]
        [validateNotNullorEmpty()]
        [string]$clientId
    )

    #get structure
    $structure = Import-Clixml -Path $structureXmlFile

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