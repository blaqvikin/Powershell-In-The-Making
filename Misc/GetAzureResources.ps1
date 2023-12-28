$subs = Import-csv ./Subscriptions.Prod.CES.csv

foreach ($sub in $subs) {

Get-AzureRmResource >> ./prod-resources-zar_2.csv
}
