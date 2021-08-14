function Set-CwmApiEntity {
    [CmdletBinding()]
    Param (
        [string]$bodyJson,
        [String]$id,
        [String]$parentId,
        [String]$grandParentId
        [String]$endpointDisambiguationString
    )
    DynamicParam {
        $Script:cwmApiPutEntityParameter
    }

    begin {
        $entity = $PSBoundParameters.entity
    }

    process {
        #winnow down to one endpoint based on parameters
        $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.put -eq $entity }
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
        if ( $PSBoundParameters.ContainsKey('endpointDisambiguationString') ) {
            $endpoint = ( $endpointCandidates | Where-Object { $_.endpoint -ilike "*$endpointDisambiguationString*" } ).endpoint
        }

        #confirm we have landed on a single endpoint
        if ( $null -eq $endpoint ) {
            $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.put -eq $entity }
            $message = "Unable to find an endpoint for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId. Candidates are:`n"
            Throw $message + ( $endpointCandidates.Endpoint | Out-String )
        }
        if ( $endpoint.count -gt 1 ) {
            $message = "Found multiple endpoints for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId. Found:`n"
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
            apiMethod = "put"
            apiRequestBody = $bodyJson
        }

        #make api call
        return New-CwmApiRequest @params
    }
}