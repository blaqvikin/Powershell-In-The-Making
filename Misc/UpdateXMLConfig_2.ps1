$path = “/home/groot/OneDrive/UbuntuDownloads/Norbert/FromOldEndNewSub.xml”
$csvPath = "/home/groot/OneDrive/UbuntuDownloads/Norbert/untitled.csv”
$columnFile = "/home/groot/OneDrive/UbuntuDownloads/Norbert/column.csv"
$doc = [xml](Get-Content -Path $path)

foreach($e in (Import-Csv -Path $csvPath))
{
 $element = $Doc.InputDirectorConfig.Configuration.Systems.Client[0].clone()
 $element.host = $e.host
 $element.type = $e.type
 $element.check = $e.check
  $doc.InputDirectorConfig.Configuration.Systems.AppendChild($element)
}
$doc.Save(“/home/groot/OneDrive/UbuntuDownloads/Norbert/TestNewParam.xml”)

foreach ($e in (Import-Csv -Path $columnFile)) {
    $element = $Doc.InputDirectorConfig.Configuration.Systems.DirectorMonitorLayout[0].clone()
    $element.col = $e.col
    $doc.InputDirectorConfig.Configuration.Systems.AppendChild($element)
}
$doc.Save(“/home/groot/OneDrive/UbuntuDownloads/Norbert/TestNewParam.xml”)