function Remove-CwmApiEntity {
    [CmdletBinding()]
    Param (
        [String]$id,
        [String]$parentId,
        [String]$grandParentId
    )
    DynamicParam {
        $Script:cwmApiDeleteEntityParameter
    }

    begin {
        $entity = $PSBoundParameters.entity
    }

    process {
        #winnow down to one endpoint based on parameters
        $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.delete -eq $entity }
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
        $endpoint = $endpointCandidates.EndPoint
        
        #confirm we have landed on a single endpoint
        if ( $null -eq $endpoint ) {
            $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.delete -eq $entity }
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

        #set parameters to call New-CwmApiRequest
        $params = @{
            endpoint = $endpoint
            apiMethod = "delete"
        }

        #make api call
        return New-CwmApiRequest @params
    }
}
