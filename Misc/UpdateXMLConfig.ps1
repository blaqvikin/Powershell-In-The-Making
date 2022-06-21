$path = “/home/groot/OneDrive/UbuntuDownloads/Norbert/FromOldEndNewSub.xml”
$csvPath = "/home/groot/OneDrive/UbuntuDownloads/Norbert/untitled.csv”
$doc = [xml](Get-Content -Path $path)

foreach($e in (Import-Csv -Path $csvPath))
{
 $element = $Doc.InputDirectorConfig.Configuration.Systems.Client[0].clone()
 $element.host = $e.host
 $element.MonitorLayout.Monitor.col = $e.MonitorLayout.Monitor.col
 $element.Encryption.type = $e.Encryption.type
 $element.Encryption.EncryptionBinaryKey.check = $e.Encryption.EncryptionBinaryKey.check
 $doc.InputDirectorConfig.Configuration.Systems.AppendChild($element)
}
$doc.Save(“/home/groot/OneDrive/UbuntuDownloads/Norbert/TestNewParam.xml”)