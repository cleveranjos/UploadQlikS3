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
        $f = (Get-ChildItem -filter "$($app.id).qvf")
        if (!$f -or $f.LastWriteTime.DateTime -lt $app.modifiedDate.ToDateTime ) {
            Write-Verbose "Dumping $($app.name)"
            Export-QlikApp -id $app.id 
            
            Write-Verbose "Tagging to enable management" 
            $tags = @(`
                @{key = "Name"; value = $app.name}, `
                @{key = "Stream"; value = $app.stream.name}, `
                @{key = "Owner"; value = $app.owner}, `
                @{key = "Description"; value = $app.description} )

            Write-Verbose "Uploadind as $($app.id).qvf"    
            Write-S3Object `
                -Region $region `
                -BucketName $bucketName `
                -File "$($app.id).qvf" `
                -AccessKey $credentials.'Access key ID' `
                -SecretKey $credentials.'Secret access key' `
                -TagSet $tags
            Write-Verbose "Checking"
            Get-S3Object `
                -Region $region `
                -BucketName $bucketName `
                -Key "$($app.id).qvf" `
                -AccessKey $credentials.'Access key ID' `
                -SecretKey $credentials.'Secret access key'
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}
Pop-Location
