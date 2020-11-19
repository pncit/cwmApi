function Get-CwmApiEntity {
    [CmdletBinding()]
    Param (
        [String]$id,
        [String]$parentId,
        [String]$grandParentId,
        [String]$catalogItemIdentifier,
        [String]$externalId,
        [String]$reportName,
        [Switch]$count,
        [Switch]$list,
        [Switch]$usages,
        [Switch]$merge,
        [Switch]$default,
        [Switch]$withSso,
        [String]$conditions,
        [String]$childConditions,
        [String]$customFieldConditions,
        [String]$orderBy,
        [String]$fields,
        [String]$pageSize,
        [String]$pageId
    )
    DynamicParam {
        $Script:cwmApiGetEntityParameter
    }

    begin {
        $entity = $PSBoundParameters.entity
    }

    process {

        #winnow down to one endpoint based on parameters
        $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.get -eq $entity }
        if ( $id ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.id }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.id }
        }
        if ( $parentId ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.parentId }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.parentId }
        }
        if ( $grandParentId ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.grandParentId }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.grandParentId }
        }
        if ( $catalogItemIdentifier ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.catalogItemIdentifier }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.catalogItemIdentifier }
        }
        if ( $externalId ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.externalId }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.externalId }
        }
        if ( $reportName ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.reportName }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.reportName }
        }
        if ( $count ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.count }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.count }
        }
        if ( $list ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.list }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.list }
        }
        if ( $usages ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.usages }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.usages }
        }
        if ( $merge ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.merge }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.merge }
        }
        if ( $default ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.default }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.default }
        }
        if ( $withSso ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.withSso }
        } else {
            $endpointCandidates = $endpointCandidates | Where-Object { !$_.withSso }
        }
        $endpoint = $endpointCandidates.EndPoint
        
        #confirm we have landed on a single endpoint
        if ( $null -eq $endpoint ) {
            $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.get -eq $entity }
            $message = "Unable to find an endpoint for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId, catalogItemIdentifier=$catalogItemIdentifier, externalId=$externalId, reportName=$reportName, count=$count, list=$list, usages=$usages, merge=$merge, default=$default, withSso=$withSso. Candidates are:`n"
            Throw $message + ( $endpointCandidates.Endpoint | Out-String )
        }
        if ( $endpoint.count -gt 1 ) {
            $message = "Found multiple endpoints for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId, catalogItemIdentifier=$catalogItemIdentifier, externalId=$externalId, reportName=$reportName, count=$count, list=$list, usages=$usages, merge=$merge, default=$default, withSso=$withSso. Found:`n"
            Throw $message + $endpoint
        }

        #manipulate endpoint to reflect parameters
        if ( $id ) {
            $endpoint = $endpoint.replace( '{id}' , $id )
        }
        if ( $parentId ) {
            $endpoint = $endpoint.replace( '{parentId}' , $parentId )
        }
        if ( $grandParentId ) {
            $endpoint = $endpoint.replace( '{grandParentId}' , $grandParentId )
        }
        if ( $catalogItemIdentifier ) {
            $endpoint = $endpoint.replace( '{catalogItemIdentifier}' , $catalogItemIdentifier )
        }
        if ( $externalId ) {
            $endpoint = $endpoint.replace( '{externalId}' , $externalId )
        }
        if ( $reportName ) {
            $endpoint = $endpoint.replace( '{reportName}' , $reportName )
        }

        #build query
        $query = $null
        if ( $conditions ) {
            $query += "&conditions=$conditions"
        }
        if ( $childConditions ) {
            $query += "&childConditions=$childConditions"
        }
        if ( $customFieldConditions ) {
            $query += "&customFieldConditions=$customFieldConditions"
        }
        if ( $orderBy ) {
            $query += "&orderBy=$orderBy"
        }
        if ( $fields ) {
            $query += "&fields=$fields"
        }
        if ( $pageSize ) {
            $query += "&pageSize=$pageSize"
        }
        if ( $pageId ) {
            $query += "&pageId=$pageId"
        }
        if ( $query ) {
            $query = '?' + $query.substring( 1 )
        }
   
        #set parameters to call New-CwmApiRequest
        $params = @{
            endpoint = $endpoint
            apiMethod = "get"
        }
        if ( $query ) {
            $params.Add( 'query' , $query )
        }
        
        #make api call
        return New-CwmApiRequest @params
    }

}