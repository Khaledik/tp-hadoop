$ErrorActionPreference="Stop"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[System.Net.ServicePointManager]::SecurityProtocol='Tls12'
$base='https://localhost:8443/nifi-api'
$u = if ($env:NIFI_USER) { $env:NIFI_USER } else { 'etudiant' }
$p = if ($env:NIFI_PASS) { $env:NIFI_PASS } else { throw 'definir $env:NIFI_PASS (voir Hadoop/nifi/credentials.env, hors git)' }
$login=Invoke-RestMethod -Method Post -Uri "$base/access/token" -Body @{username=$u;password=$p} -ContentType 'application/x-www-form-urlencoded'
$h=@{Authorization="Bearer $login";'Content-Type'='application/json';Accept='application/json'}
$pg=(Invoke-RestMethod -Method Get -Uri "$base/process-groups/root" -Headers $h).id
$procs=Invoke-RestMethod -Method Get -Uri "$base/process-groups/$pg/processors" -Headers $h
foreach($p in $procs.processors){
  if($p.component.name -in @('GetFile','PutFile-errors')){
    $raw=(Invoke-WebRequest -Method Get -Uri "$base/processors/$($p.component.id)" -Headers $h -UseBasicParsing).Content
    $st=[regex]::Match($raw,'"state":"(\w+)"').Groups[1].Value
    $v=[int][regex]::Match($raw,'"version":(\d+)').Groups[1].Value
    $b=@{revision=@{clientId='val';version=$v};state='RUNNING';disconnectedNodeAcknowledged=$false}
    $r=Invoke-WebRequest -Method Put -Uri "$base/processors/$($p.component.id)/run-status" -Headers $h -Body ($b|ConvertTo-Json -Depth 6) -UseBasicParsing
    Write-Host ("{0} : {1} -> {2}" -f $p.component.name,$st,([regex]::Match($r.Content,'"state":"(\w+)"').Groups[1].Value))
  }
}
Write-Host "RESTART_DONE"