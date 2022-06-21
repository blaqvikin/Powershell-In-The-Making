$TempPath = "C:\temp\NewFolder"
If(!(test-path -PathType container $TempPath))
{
      New-Item -ItemType Directory -Path $TempPath

      #Download username csv file from a blob
      wget "https://cloudshsan.blob.core.windows.net/publiccontainer/username.csv?sv=2020-10-02&si=publicpolicy&sr=b&sig=vSljYQXbgaWpTdkNqmLOAI6j1hVezS7xaAyRF5U5Q7g%3D" -OutFile $TempPath\username.csv

      #The users.csv is the file that contains all the users. The csv has a heading named "username"
      Import-Csv $TempPath\username.csv | ForEach-Object {Remove-LocalGroupMember -Group Administrators -Member $_.username}
}

#Else execute the script if this already exists.
Import-Csv $TempPath\username.csv | ForEach-Object {Remove-LocalGroupMember -Group Administrators -Member $_.username}

Start-Sleep -Seconds 5

Remove-Item -Recurse -Force -Path "c:\temp"