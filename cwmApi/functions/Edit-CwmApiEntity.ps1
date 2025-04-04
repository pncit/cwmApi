function Edit-CwmApiEntity {
    [CmdletBinding()]
    Param (
        [string]$op,
        [string]$path,
        $value,
        [String]$id,
        [String]$parentId,
        [String]$grandParentId,
        [String]$endpointDisambiguationString,
        [Boolean]$endpointDisambiguationStringInclusive=$true
    )
    DynamicParam {
        $Script:cwmApiPatchEntityParameter
    }

    begin {
        $entity = $PSBoundParameters.entity
    }

    process {
        #winnow down to one endpoint based on parameters
        $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.patch -eq $entity }
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
        #some endpoints cannot be otherwise distinguished
        if ( $PSBoundParameters.ContainsKey('endpointDisambiguationString') ) {
          if ( $endpointDisambiguationStringInclusive ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.endpoint -ilike "*$endpointDisambiguationString*" }
          } else {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.endpoint -notlike "*$endpointDisambiguationString*" }
          }
          $endpoint = $endpointCandidates.endpoint
          #confirm we have landed on a single endpoint
          if ( $null -eq $endpoint ) {
            $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.patch -eq $entity }
            $message = "Unable to find an endpoint for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId and including string $endpointDisambiguationString. Candidates are:`n"
            Throw $message + ( $endpointCandidates.Endpoint | Out-String )
          }
          if ( $endpoint.count -gt 1 ) {
            $message = "Found multiple endpoints for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId and excluding string $endpointDisambiguationString. Found:`n"
            Throw $message + $endpoint
          }
        } else {
          #confirm we have landed on a single endpoint
          if ( $null -eq $endpoint ) {
            $endpointCandidates = $Script:cwmApiQueries | Where-Object { $_.patch -eq $entity }
            $message = "Unable to find an endpoint for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId. Candidates are:`n"
            Throw $message + ( $endpointCandidates.Endpoint | Out-String )
          }
          if ( $endpoint.count -gt 1 ) {
            $message = "Found multiple endpoints for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId. Found:`n"
            Throw $message + $endpoint
          }
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

        $apiRequestBody =  ( @{
            op = $op
            path = $path
            value = $value
        } ) | ConvertTo-Json

        $apiRequestBody = "[$apiRequestBody]"

        #set parameters to call New-CwmApiRequest
        Write-Debug "endpoint: $endpoint"
        Write-Debug "apiRequestBody: $apiRequestBody"
        $params = @{
            endpoint = $endpoint
            apiMethod = "patch"
            apiRequestBody = $apiRequestBody
        }

        $params

        #make api call
        return New-CwmApiRequest @params
    }
}