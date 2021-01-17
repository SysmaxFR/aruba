# DEBUG WireSharp
#-> fonctionne avec Insomnia
#-> fonctionne avec cURL 
#        curl.exe --request POST --url http://X.X.X.X/rest/v7/login-sessions --header 'Content-Type: application/json' --data "{\"userName\":\"manager\",\"password\":\"monsupermdp\"}"
#-> fonctionne pas avec PS v5
#        analyse WireSharp : "Expect: 100-continue" est ajouté au Headers. Permet d'envoyer le Headers, attendre une réponse avant d'envoyer le body.

#-> erreur avec la commende show vsf member, la trame envoyé est cmd:show (s'arrete au premier espace) 

cd C:\Users\Administrateur\Downloads\curl-7.74.0_2-win64-mingw\bin

$Session = curl.exe --request POST --url http://X.X.X.X/rest/v7/login-sessions --header 'Content-Type: application/json' --data "{\"userName\":\"manager\",\"password\":\"monsupermdp\"}"
$Cookie = ($Session | ConvertFrom-Json).Cookie

#$Vlan = curl.exe --request GET --url http://X.X.X.X/rest/v7/vlans --header 'Content-Type: application/json' --cookie $Cookie
$Vsf = curl.exe --request POST --url http://X.X.X.X/rest/v7/cli --header 'Content-Type: application/json' --cookie $Cookie --data "{\"cmd\":\"sow vsf member 3\"}"
