function Remove-CwmApiEntity {
    [CmdletBinding()]
    Param (
        [String]$id,
        [String]$parentId,
        [String]$grandParentId,
        [String]$endpointDisambiguationString,
        [Boolean]$endpointDisambiguationStringInclusive=$true
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
        #some endpoints cannot be otherwise distinguished
        if ( $PSBoundParameters.ContainsKey('endpointDisambiguationString') ) {
          if ( $endpointDisambiguationStringInclusive ) {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.endpoint -ilike "*$endpointDisambiguationString*" }
          } else {
            $endpointCandidates = $endpointCandidates | Where-Object { $_.endpoint -notlike "*$endpointDisambiguationString*" }
          }
        }
        $endpoint = $endpointCandidates.endpoint
        #confirm we have landed on a single endpoint
        if ($null -eq $endpoint -or $endpoint.Count -gt 1) {
          if ($endpoint.Count -gt 1) {
            $message = 'Found multiple endpoints'
            $feedback = ". Found:`n$endpoint"
          } else { 
            $message = 'Unable to find an endpoint' 
            $feedback = ". Candidates are:`n" + ($Script:cwmApiQueries | Where-Object { $_.delete -eq $entity } | Select-Object -ExpandProperty Endpoint | Out-String)
          }
          $message += " for '$entity' with id=$id, parentId=$parentId, grandparentId=$grandparentId"
          if ($PSBoundParameters.ContainsKey('endpointDisambiguationString') -and $endpointDisambiguationStringInclusive) {
            $message += " and including string '$endpointDisambiguationString'"
          } elseif ($PSBoundParameters.ContainsKey('endpointDisambiguationString')) {
            $message += " and excluding string '$endpointDisambiguationString'"
          }
          throw "$message$feedback"
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
