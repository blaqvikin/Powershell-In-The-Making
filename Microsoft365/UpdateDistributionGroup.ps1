Import-Csv .\NewFormerEmployees.csv | ForEach-Object { Add-DistributionGroupMember -Identity 0d58c9fa-c042-439b-95a1-8859b66fe83f -Member $_.userprincipalname}