$region = "sa-east-1" 

try {
    Push-Location "C:\QlikBackup\S3WorkingArea" 
    Connect-Qlik
    $awsfile = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\accessKeys.csv"
    if (Get-ChildItem "$($awsfile)" ) {
        $credentials = Import-Csv -Path "$($awsfile)"
    } else {
        Write-Error "Not able to find AWS credentials"
        Exit
    }
} catch {
    Write-Error "Could not stablish connections"
    Exit 
}

$apps = Get-QlikApp -filter "Published eq true and tags.name eq 'S3'" -full

foreach($app in $apps) {
  try {
    Write-Verbose "Checking if $($app.name) is newer" 
    $f = (Get-ChildItem -filter "$($app.id).qvf")
    if (!$f -or $f.LastWriteTime.DateTime -lt $app.modifiedDate.ToDateTime ) {
        Write-Verbose "Dumping $($app.name)"
        Export-QlikApp -id $app.id 
        Write-S3Object  `
            -Region $region `
            -BucketName "storage.qlik" `
            -File "$($app.id).qvf" `
            -AccessKey $credentials.'Access key ID' ` 
            -SecretKey $credentials.'Secret access key' `
    }
    $status = "OK"
  }
  catch {
    Write-Error $_.Exception.Message
  }
  #write-host $app.name $status 
}
Pop-Location
