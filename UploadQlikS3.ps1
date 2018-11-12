$region = "sa-east-1"
$bucketName = "storage.qlik" 
$workingarea = "C:\QlikBackup\S3WorkingArea" 
$awsfile = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\accessKeys.csv"

try {
    Push-Location $workingarea
    Connect-Qlik
    if (Get-ChildItem "$($awsfile)" ) {
        $credentials = Import-Csv -Path "$($awsfile)"
    }
    else {
        Write-Error "Not able to find AWS credentials"
        Exit
    }
}
catch {
    Write-Error "Could not stablish connections"
    Exit 
}

$apps = Get-QlikApp -filter "Published eq true and tags.name eq 'S3'" -full

foreach ($app in $apps) {
    try {
        Write-Verbose "Checking if $($app.name) is newer" 
        $s3 = Get-S3Object `
            -Region $region `
            -BucketName $bucketName `
            -Key "$($app.id).qvf" `
            -AccessKey $credentials.'Access key ID' `
            -SecretKey $credentials.'Secret access key'

        if (!$s3 -or ( $s3.LastModified.ToString("yyyy/MM/dd hh:mm") -lt $app.modifiedDate ) ) {
            Write-Verbose "Dumping $($app.name)"
            Export-QlikApp -id $app.id            
            Write-Verbose "Tagging to enable management" 

            $tags = @(`
                @{key = "name"; value = $( $app.name -replace '[()]', '')}, `
                @{key = "modifiedDate"; value = $app.modifiedDate}, `
                @{key = "stream"; value = $app.stream.name}, `
                @{key = "userDirectory"; value = $(if ($a.owner.userDirectory.GetType() -eq "string") {$a.owner.userDirectory } else {$a.owner.userDirectory[0].Trim()} )}, ` 
                @{key = "userId"; value = $(if ($a.owner.userId.GetType() -eq "string") {$a.owner.userId } else {$a.owner.userId[0].Trim()})})
            $tags
            Write-Verbose "Uploadind as $($app.id).qvf"    
            Write-S3Object `
                -Region $region `
                -BucketName $bucketName `
                -File "$($app.id).qvf" `
                -AccessKey $credentials.'Access key ID' `
                -SecretKey $credentials.'Secret access key' `
                -TagSet $tags
        }
    }
    catch {
        Write-Error $_.Exception.Message
        Write-Error $app.name
    }
}
#Remove-Item *
Pop-Location
