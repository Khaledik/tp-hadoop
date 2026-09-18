$ErrorActionPreference="Stop"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[System.Net.ServicePointManager]::SecurityProtocol='Tls12'
$base='https://localhost:8443/nifi-api'
$u = if ($env:NIFI_USER) { $env:NIFI_USER } else { 'etudiant' }
$p = if ($env:NIFI_PASS) { $env:NIFI_PASS } else { throw 'definir $env:NIFI_PASS (voir Hadoop/nifi/credentials.env, hors git)' }
$login=Invoke-RestMethod -Method Post -Uri "$base/access/token" -Body @{username=$u;password=$p} -ContentType 'application/x-www-form-urlencoded'
$h=@{Authorization="Bearer $login";'Content-Type'='application/json';Accept='application/json'}
$convId='9a73fb7c-01a0-1000-6be8-6c968dffea9d'
$readerId='9a73f921-01a0-1000-ee3e-c658e7b5f292'
$writerId='9a73fb13-01a0-1000-2c7e-2e8a8103b26a'

$prop = New-Object 'System.Collections.Generic.Dictionary[string,object]' ([System.StringComparer]::Ordinal)
$prop['Record Reader']=$readerId
$prop['Record Writer']=$writerId
$prop['Include Zero Record Flow Files']=$null
$prop['Include Zero Record Flowfiles']=$null
$prop['record-reader']=$null
$prop['record-writer']=$null
$prop['include-zero-record-flowfiles']=$null

$raw=(Invoke-WebRequest -Method Get -Uri "$base/processors/$convId" -Headers $h -UseBasicParsing).Content
$v=[int][regex]::Match($raw,'"version":(\d+)').Groups[1].Value
$cur=[regex]::Match($raw,'"state":"(\w+)"').Groups[1].Value
$bs=@{revision=@{clientId='val';version=$v};state='STOPPED';disconnectedNodeAcknowledged=$false}
$null=Invoke-WebRequest -Method Put -Uri "$base/processors/$convId/run-status" -Headers $h -Body ($bs|ConvertTo-Json -Depth 6) -UseBasicParsing 2>$null
for($i=0;$i -lt 20;$i++){
  Start-Sleep -Seconds 2
  $raw=(Invoke-WebRequest -Method Get -Uri "$base/processors/$convId" -Headers $h -UseBasicParsing).Content
  $cur=[regex]::Match($raw,'"state":"(\w+)"').Groups[1].Value
  if($cur -eq 'STOPPED'){ break }
}
Write-Host "reached state=$cur"
$v=[int][regex]::Match($raw,'"version":(\d+)').Groups[1].Value
$jsonProps = @{}
foreach($k in $prop.Keys){ $jsonProps[$k] = $prop[$k] }
$body=@{revision=@{clientId='val';version=$v};component=@{id=$convId;config=@{properties=$jsonProps;schedulingPeriod='5 sec';autoTerminatedRelationships=@()}}}
$bodyJson = $body | ConvertTo-Json -Depth 10
Write-Host "BODY: $bodyJson"
$r=Invoke-WebRequest -Method Put -Uri "$base/processors/$convId" -Headers $h -Body $bodyJson -UseBasicParsing
$c=$r.Content
$ve=[regex]::Match($c,'"validationErrors"\s*:\s*\[([^\]]*)\]').Groups[1].Value
Write-Host "ver=$([regex]::Match($c,'"version":(\d+)').Groups[1].Value )"
if($ve){ $ve -split '","' | ForEach-Object { Write-Host "  VE: $_" } } else { Write-Host "  NO validation errors" }

$raw2=(Invoke-WebRequest -Method Get -Uri "$base/processors/$convId" -Headers $h -UseBasicParsing).Content
$v2=[int][regex]::Match($raw2,'"version":(\d+)').Groups[1].Value
$b2=@{revision=@{clientId='val';version=$v2};state='RUNNING';disconnectedNodeAcknowledged=$false}
$r2=Invoke-WebRequest -Method Put -Uri "$base/processors/$convId/run-status" -Headers $h -Body ($b2|ConvertTo-Json -Depth 6) -UseBasicParsing
Write-Host "run -> $([regex]::Match($r2.Content,'"state":"(\w+)"').Groups[1].Value)"
Write-Host "NULLTRY_DONE"