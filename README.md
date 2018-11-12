# UploadQlikS3
This script is meant to be a scheduled uploader from Qlik Sense Enterprise apps to a S3 bucket.
Use at your own risk, 
very early development stage, contribute if you can

Regards


## Pre-requisites
You **must** install
* https://github.com/ahaydon/Qlik-Cli
* https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up.html

## Setting up
1. Check Pre-reqs and make sure they are ok
2. Download https://github.com/cleveranjos/UploadQlikS3 and save it under [Documents\WindowsPowerShell]
3. Create a bucket into S3 to receive the apps
4. Configure a AWS IAM user and download the Access key ID,Secret access key as csv file. Please refer to this if you have any doubts https://docs.microfocus.com/itom/Service_Management_Automation_-_X:2018.02/Create-an-AWS-access-key-ID-and-secret-access-key_19895482 and save it in [Documents\WindowsPowerShell]  
5. Give that user the policy "AmazonS3FullAccess" 
6. Change the $region parameter to your Availability Zone
7. Change $bucketName to your bucket you´ve created into step 3
8. Change $workingarea to a working folder of your choice
9. Run it :)

## Useful reading
* https://4sysops.com/archives/manage-amazon-aws-s3-with-powershell/
* http://todhilton.com/technicalwriting/upload-backup-your-files-to-amazon-s3-with-powershell/
