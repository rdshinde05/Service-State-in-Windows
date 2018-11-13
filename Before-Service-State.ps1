$hosts = $env:computername

write-host "Capturing Service State on Server $hosts for Post Verification"

$Folderpath = $env:TEMP

$preReboot =  get-Service * | where {$_.Status -eq "Running"} 

$preReboot

$preReboot |  Export-Clixml -Path $Folderpath\preboot-service.xml
