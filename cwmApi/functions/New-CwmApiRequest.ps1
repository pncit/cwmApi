function New-CwmApiRequest {
    <#
    .SYNOPSIS 
    Performs a query against the Connectwise Manage API

    .DESCRIPTION
    This is a very generic function that performs GET, POST, PATCH, PUT, and DELETE requests to the ConnectWise Manage API. If pageSize is not
    specified in the endpoint parameter, this function will automatically pull the maximum page size (1000). Whatever the pageSize, the function
    will loop to pull any additional pages, returning all responses combined into a single response object.

    .PARAMETER endpoint
    The ConnectWise Manage API endpoint to hit.
    
    .PARAMETER query
    The query to append to the URL when making the REST call. The query should NOT be URL encoded.

    .PARAMETER apiMethod
    API method (get, post, patch, put, delete)
    
    .PARAMETER apiRequestBody
    API request body

    .OUTPUTS
    [System.Object] custom object containing API response

    .EXAMPLE
    $tickets = New-CwmApiRequest -endpoint "/service/tickets" -query "conditions=board/id=1 and status/id=505&fields=id,owner/id" -apiMethod "get" 

    .EXAMPLE

    .NOTES
    #>
    [CmdletBinding()]
	param
	(
        [parameter(Mandatory=$true, ParameterSetName='guided')]
        [validateNotNullorEmpty()]
        [string]$endpoint,

        [parameter(Mandatory=$false, ParameterSetName='guided')]
        [validateNotNullorEmpty()]
        [string]$query,

        [parameter(Mandatory=$true, ParameterSetName='direct')]
        [validateNotNullorEmpty()]
        [string]$uri,

        [parameter(Mandatory=$true)]
        [validateNotNullorEmpty()]
        [string]$apiMethod,

        [parameter(Mandatory=$false)]
        [validateNotNullorEmpty()]
        [string]$apiRequestBody
    )

    $errorAction = $PSBoundParameters["ErrorAction"]
    if(-not $errorAction){
        $errorAction = $ErrorActionPreference
    }

    if ( $endpoint ) {
        Write-Debug "Endpoint: $endpoint"
        #where a client name has & (e.g. RHW - River Health & Wellness) we need need to replace the & with %26 in order to use CW API, 
        #but cannot replace all & with %26 because & has a function in REST API calls
        $escapedQuery = ( [uri]::EscapeUriString( $query ) ).replace( '%20&%20', '%20%26%20' )
        $uri = "https://" + $Script:cwmApiUri + $endpoint + $escapedQuery

        #pull maximum records allowable unless query already specifies a count
        if ( $uri.ToLower().IndexOf( "pagesize" ) -eq -1 -and $apiRequestBody -ieq "get" ) {
            if ( $uri.IndexOf( "?" ) -eq -1 ) {
                $uri += "?pageSize=1000"
            } else {
                $uri += "&pageSize=1000" 
            }
        }
    }
    
    Write-Debug "Uri: $uri"
    Write-Debug "apiMethod: $apiMethod"

    #set the parameters for the request
    $params = @{
        Uri         =	$uri
        Method      =	$apiMethod
        ContentType	= 	'application/json'
        Headers     =	@{
            'Authorization'	= $Script:cwmApiAuthString
            'clientId' = $Script:cwmApiClientId
            'Accept' = "application/vnd.connectwise.com+json; version=$Script:cwmApiVersionCode"
        }
    }

    #if body was defined (patch or put), add to params
    if ( $apiRequestBody ) {
        Write-Debug "apiRequestBody: $apiRequestBody"
        $params.Add( 'Body' , $apiRequestBody )
    }

    #make api request
    try { $response = ( Invoke-WebRequest @params -UseBasicParsing ) | Select-Object StatusCode,Content,Headers }
    catch {
        if ( $errorAction.ToString().ToLower() -ne "silentlycontinue") {
            Write-Error "API Request failed`n$PSItem"
        }
        throw
    }

    $content = $response.content | ConvertFrom-Json
    if ( ( $null -eq $response.Headers['Link'] ) -or ( $response.Headers['Link'].IndexOf( 'rel="next"' ) -eq -1 ) ) {
        return $content
    } else {
        #extract 'next' url from a string like
        #<https://api-na.myconnectwise.net/v4_6_release/apis/3.0/service/tickets/?pageSize=1000&page=2>; rel="next", <https://api-na.myconnectwise.net/v4_6_release/apis/3.0/service/tickets/?pageSize=1000&page=230>; rel="last"
        $linkInfo = $response.Headers['Link']
        $linkInfo = $linkInfo.Replace('rel=','').Replace('<','').Replace('>','').Replace('"','').Replace(' ','')
        $linkInfo = $linkInfo.Split(',')
        foreach ( $link in $linkInfo ) {
            $info = $link.split(';')
            if ( $info[1] -eq 'next') {
                $nextUrl = $info[0]
            }
        }
        $params = @{
            "uri" = $nextUrl
            "apiMethod" = $apiMethod
        }
        if ( $apiRequestBody ) {
            $params.Add( 'apiRequestBody' , $apiRequestBody )
        }
        $restOfContent = New-CwmApiRequest @params
        return $content + $restOfContent
    }
}