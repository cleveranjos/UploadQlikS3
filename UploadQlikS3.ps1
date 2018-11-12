$region = "sa-east-1"
$bucketName = "storage.qlik" 
$workingarea = "C:\QlikBackup\S3WorkingArea" 
$awsfile = "$([Environment]::GetFolderPath("MyDocuments"))\WindowsPowerShell\accessKeys.csv"

Function LogWrite
{
   Param ([string]$logstring)
   $Stamp = (Get-Date).toString("yyyy/MM/dd HH:mm:ss")
   Add-content "Log.txt" -value "$Stamp $logstring"
   write-host "$Stamp $logstring"
}
LogWrite "---- Start of Processing"
try {
    Push-Location $workingarea
    Connect-Qlik
    if (Get-ChildItem "$($awsfile)") {
        $credentials = Import-Csv -Path "$($awsfile)"
    }
    else {
        LogWrite "Not able to find AWS credentials" 
        Exit
    }
}
catch {
    LogWrite "Could not stablish connections" 
    Exit 
}
LogWrite "Retrieving apps with tag = S3"
foreach ($app in Get-QlikApp -filter "Published eq true and tags.name eq 'S3'" -full) {
    try {
        LogWrite "Checking if $($app.name) is newer" 
        $s3 = Get-S3Object `
                -Region $region `
                -BucketName $bucketName `
                -Key "$($app.id).qvf" `
                -AccessKey $credentials.'Access key ID' `
                -SecretKey $credentials.'Secret access key'

        if (!$s3 -or ( $s3.LastModified.ToString("yyyy/MM/dd hh:mm") -lt $app.modifiedDate ) ) {
            LogWrite "Dumping $($app.name)"
            Export-QlikApp -id $app.id            
            LogWrite "Tagging to enable management" 
            $tags = @(`
                @{key = "name"; value = $( $app.name -replace '[()]','')}, `
                @{key = "modifiedDate"; value = $app.modifiedDate}, `
                @{key = "stream"; value = $app.stream.name}, `
                @{key = "userDirectory"; value = $(if($app.owner.userDirectory -is "string"){$app.owner.userDirectory} else {$app.owner.userDirectory[0].Trim()})}, ` 
                @{key = "userId"; value = $(if($app.owner.userId -is "string"){$app.owner.userId} else {$app.owner.userId[0].Trim()})}`
                )
            LogWrite "Uploadind as $($app.id).qvf"    
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
        LogWrite $_.Exception.Message
        LogWrite $app.name 
    }
}
LogWrite "Removing temp files"
Remove-Item *.qvf
Pop-Location
LogWrite "---- End of Processing"
