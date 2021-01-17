# Fonctionne seulement avec powershell v7+.
if(!($PSVersionTable.PSVersion.Major -eq "7")){ Write-Host "Script use only PwSH v7"; exit 0 }

# Definition des variables.
# $AutoRemediation=$true permet de re-equilibrage du Commander/Standby en fonction du Stretch-Cluster.
$IP = "X.X.X.X"
$Rest = "rest/v7"
$AutoRemediation = $false
$Login = @{
    "userName" = "manager"
    "password" = "monsupermdp"
}

# Definition des commandes AnyCLI.
$VsfMember1 = @{ "cmd" = "show vsf member 1" }
$VsfMember2 = @{ "cmd" = "show vsf member 2" }
$VsfMember3 = @{ "cmd" = "show vsf member 3" }
$VsfMember4 = @{ "cmd" = "show vsf member 4" }
$VsfRedundancy = @{ "cmd" = "redundancy switchover" }

# Ouverture de la session RestAPI, recuperation d'un cookie d'authentification.
$Session = Invoke-RestMethod -Uri "http://$IP/$Rest/login-sessions" -Method 'POST' -ContentType 'application/json' -SessionVariable 'Cookie' -Body ($Login|ConvertTo-Json)

# Recuperation des resultats des commandes effectues sur le stack.
$VsfMember1 = Invoke-RestMethod -Uri "http://$IP/$Rest/cli" -Method POST -ContentType 'application/json' -WebSession $Cookie -Body ($VsfMember1|ConvertTo-Json)
$VsfMember2 = Invoke-RestMethod -Uri "http://$IP/$Rest/cli" -Method POST -ContentType 'application/json' -WebSession $Cookie -Body ($VsfMember2|ConvertTo-Json)
$VsfMember3 = Invoke-RestMethod -Uri "http://$IP/$Rest/cli" -Method POST -ContentType 'application/json' -WebSession $Cookie -Body ($VsfMember3|ConvertTo-Json)
$VsfMember4 = Invoke-RestMethod -Uri "http://$IP/$Rest/cli" -Method POST -ContentType 'application/json' -WebSession $Cookie -Body ($VsfMember4|ConvertTo-Json)

# Resultat recu en Base64, decodage.
$VsfMember1 = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($VsfMember1.result_base64_encoded))
$VsfMember2 = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($VsfMember2.result_base64_encoded))
$VsfMember3 = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($VsfMember3.result_base64_encoded))
$VsfMember4 = [Text.Encoding]::Utf8.GetString([Convert]::FromBase64String($VsfMember4.result_base64_encoded))

# Recuperation des status "Commander", "Standby", "Member" par membres du stack. Conversion pour faciliter l'usage avec powershell
# Convert to String to Array of String, then filter.
$StatusVsfMember1 = (($VsfMember1 -split "`n") | ? {$_ -match "status"}) | ConvertFrom-StringData -Delimiter ":" 
$StatusVsfMember2 = (($VsfMember2 -split "`n") | ? {$_ -match "status"}) | ConvertFrom-StringData -Delimiter ":"
$StatusVsfMember3 = (($VsfMember3 -split "`n") | ? {$_ -match "status"}) | ConvertFrom-StringData -Delimiter ":"
$StatusVsfMember4 = (($VsfMember4 -split "`n") | ? {$_ -match "status"}) | ConvertFrom-StringData -Delimiter ":"

# Recuperation des links actifs par membres du stack. Par defaut 2 actifs.
$LinksVsfMember1 = (($VsfMember1 -split "`n") | ? {$_ -match "Active, Peer member"}) | Measure-Object -Line
$LinksVsfMember2 = (($VsfMember2 -split "`n") | ? {$_ -match "Active, Peer member"}) | Measure-Object -Line
$LinksVsfMember3 = (($VsfMember3 -split "`n") | ? {$_ -match "Active, Peer member"}) | Measure-Object -Line
$LinksVsfMember4 = (($VsfMember4 -split "`n") | ? {$_ -match "Active, Peer member"}) | Measure-Object -Line


$TestStatusVsfMember1 = ($StatusVsfMember1.Values -like "Commander") -or ($StatusVsfMember1.Values -like "Standby")
$TestStatusVsfMember2 = ($StatusVsfMember2.Values -like "Commander") -or ($StatusVsfMember2.Values -like "Standby")
$TestStatusVsfMember3 = ($StatusVsfMember3.Values -like "Commander") -or ($StatusVsfMember3.Values -like "Standby")
$TestStatusVsfMember4 = ($StatusVsfMember4.Values -like "Commander") -or ($StatusVsfMember4.Values -like "Standby")

$TestLinksVsfMember1 = ($LinksVsfMember1.Lines -eq "2")
$TestLinksVsfMember2 = ($LinksVsfMember2.Lines -eq "2")
$TestLinksVsfMember3 = ($LinksVsfMember3.Lines -eq "2")
$TestLinksVsfMember4 = ($LinksVsfMember4.Lines -eq "2")


if($TestVsfMember1 -and $TestVsfMember2)
{
    Write-Host "ERROR -> Use #redundancy switchover or AutoRemediation"
    Write-Host "Member1 ->"$StatusVsfMember1.Values", Member2 ->"$StatusVsfMember1.Values

    if($AutoRemediation -and $TestLinksVsfMember1 -and $TestLinksVsfMember2)
    {
        Invoke-RestMethod -Uri "http://$IP/$Rest/cli" -Method POST -ContentType 'application/json' -WebSession $Cookie -Body ($VsfRedundancy|ConvertTo-Json) -TimeoutSec 2 #TimeOut car retour en erreur suite coupure avec le commander
    }
}
elseif($TestVsfMember3 -and $TestVsfMember4)
{
    Write-Host "ERROR -> Use #redundancy switchover or AutoRemediation"
    Write-Host "Member3 ->"$StatusVsfMember1.Values", Member4 ->"$StatusVsfMember1.Values

    if($AutoRemediation -and $TestLinksVsfMember3 -and $TestLinksVsfMember4)
    {
        Invoke-RestMethod -Uri "http://$IP/$Rest/cli" -Method POST -ContentType 'application/json' -WebSession $Cookie -Body ($VsfRedundancy|ConvertTo-Json) -TimeoutSec 2
    }
}
else
{
    Write-Host "OK -> Priority are balanced"
}


$Session = Invoke-RestMethod -Uri "http://$IP/$Rest/login-sessions" -Method DELETE -ContentType 'application/json' -WebSession $Cookie
