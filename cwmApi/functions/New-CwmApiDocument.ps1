function New-CwmApiDocument {
    <#
    .SYNOPSIS 
    Uploads a document to Connectwise

    .DESCRIPTION
    This will upload a file on the local computer to a specified item in ConnectWise Mange

    .PARAMETER File
    The file to upload (FileInfo item, created by Get-Item "Path/to/item/file.xyz" )
    
    .PARAMETER RecordType
    Entity type to attach document to

    .PARAMETER RecordId
    Entity to attach document to
    
    .PARAMETER PrivateFlag
    Whether to make the deocument private

    .PARAMETER ReadOnlyFlag
    Whether to make the deocument readyonly

    .PARAMETER IsAvatar

    .OUTPUTS
    [System.Object] custom object containing API response

    .EXAMPLE

    .NOTES
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true)]
        [System.IO.FileInfo[]]$File,
        [parameter(Mandatory=$true)]
        [ValidateSet("Ticket","Agreement","Company","Configuration","Contact","Expense","Opportunity","PurchaseOrder","Project","SalesOrder","ServiceTemplate","Rma")]
        [String]$RecordType,
        [parameter(Mandatory=$true)]
        [Int]$RecordId,
        [parameter(Mandatory=$true)]
        [String]$Title,
        [parameter(Mandatory=$false)]
        [Boolean]$PrivateFlag=$false,
        [parameter(Mandatory=$false)]
        [Boolean]$ReadOnlyFlag=$false,
        [parameter(Mandatory=$false)]
        [Boolean]$IsAvatar=$false
    )
    
    process {
        $FileBin = [System.IO.File]::ReadAllBytes( $File.FullName )
        $Enc = [System.Text.Encoding]::GetEncoding("iso-8859-1")
        $FileEnc = $Enc.GetString( $FileBin )
        $FileName = $File.Name

        $Boundary = [System.Guid]::NewGuid().ToString()    

        $LF = "`r`n"
        $BodyLines = (
            "--$Boundary",
            "Content-Disposition: form-data; name=`"File`"; filename=`"$FileName`"$LF",
            $FileEnc,
            "--$Boundary",
            "Content-Disposition: form-data; name=`"RecordType`"$LF",
            $RecordType,
            "--$Boundary",
            "Content-Disposition: form-data; name=`"RecordId`"$LF",
            $RecordId,
            "--$Boundary",
            "Content-Disposition: form-data; name=`"Title`"$LF",
            $Title,
            "--$Boundary",
            "Content-Disposition: form-data; name=`"PrivateFlag`"$LF",
            $PrivateFlag,
            "--$Boundary",
            "Content-Disposition: form-data; name=`"ReadOnlyFlag`"$LF",
            $ReadOnlyFlag,
            "--$Boundary",
            "Content-Disposition: form-data; name=`"IsAvatar`"$LF",
            $IsAvatar,
            "--$Boundary--$LF"
        ) -join $LF

        $params = @{
            Uri         =	"https://" + $Script:cwmApiUri + "/system/documents"
            Method      =	"post"
            ContentType	= 	"multipart/form-data; Boundary=`"$Boundary`""
            Headers     =	@{
                'Authorization'	= $Script:cwmApiAuthString
                'clientId' = $Script:cwmApiClientId
                'Accept' = "application/vnd.connectwise.com+json; version=$Script:cwmApiVersionCode"
            }
            Body        = $BodyLines
        }

        $Result = Invoke-RestMethod @Params
        Return $Result
    }
}