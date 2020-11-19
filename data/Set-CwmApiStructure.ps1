function Set-CwmApiStructure {
    Param(
        [Parameter(Mandatory=$True)]
        [validateNotNullorEmpty()]
        [string]
        $jsonFile,

        [Parameter(Mandatory=$True)]
        [validateNotNullorEmpty()]
        [string]
        $xmlFile
    )
    
    function g {
        param(
            [parameter(Mandatory=$true)]
            [object]$path,
            [parameter(Mandatory=$true)]
            [ValidateSet("get","put","post","patch","delete")]
            [string]$restMethod
        )

        $root = $path.value.$($restMethod)
        if ( $null -ne $root.tags ) {
            $tag = ( $root.tags ).replace( '{' , '' ).replace( '}' , '' )
            return $tag
        } else {
            return $null
        }
    }

    function New-EntityList {
        param(
            [parameter(Mandatory=$true)]
            [object]$queries,
            [parameter(Mandatory=$true)]
            [ValidateSet("get","put","post","patch","delete")]
            [string]$restMethod
        )

        $entities = @()
        foreach ( $query in $queries | Where-Object { $null -ne $_."$restMethod" } ) {
            $entities += $query."$restMethod"
        }

        $entities = $entities | Sort-Object -Unique
        return $entities
    }

    $cwmApi = Get-Content $jsonFile -raw | ConvertFrom-Json

    Write-Host "Processing $($cwmApi.info.title), version $($cwmApi.info.version) ($($cwmApi.openapi)) . . ."

    $queries = foreach ( $path in $cwmApi.Paths.psObject.Properties ) {
        if ( $path.Name -NotLike "*regex*" ) {
            [PSCustomObject]@{
                Endpoint = $path.Name
                Get = g -path $path -restMethod 'get'
                Put = g -path $path -restMethod 'put'
                Post = g -path $path -restMethod 'post'
                Patch = g -path $path -restMethod 'patch'
                Delete = g -path $path -restMethod 'delete'
                id = $path.Name -Like "*{id}*"
                parentId = $path.Name -Like "*{parentId}*"
                grandparentId = $path.Name -Like "*{grandparentId}*"
                catalogItemIdentifier = $path.Name -Like "*{catalogItemIdentifier}*"
                externalId = $path.Name -Like "*{externalId}*"
                reportName = $path.Name -Like "*{reportName}*"
                list = $path.Name -Like "*/list"
                count = $path.Name -Like "*/count"
                usages = $path.Name -Like "*/usages" -or $path.Name -Like "*/usages/*"
                merge = $path.Name -Like "*/merge"
                default = $path.Name -Like "*/default"
                withSso = $path.Name -Like "*/withSso"
            }
        }   
    }

    [PSCustomObject]@{
        version = $cwmApi.info.version
        queries = $queries
        getEntityList = New-EntityList -queries $queries -restMethod "get"
        putEntityList = New-EntityList -queries $queries -restMethod "put"
        postEntityList = New-EntityList -queries $queries -restMethod "post"
        patchEntityList = New-EntityList -queries $queries -restMethod "patch"
        deleteEntityList = New-EntityList -queries $queries -restMethod "delete"
    } | Export-CliXml $xmlFile

}