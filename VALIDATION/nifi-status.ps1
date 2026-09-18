$ErrorActionPreference="Stop"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[System.Net.ServicePointManager]::SecurityProtocol='Tls12'
$base='https://localhost:8443/nifi-api'
$u = if ($env:NIFI_USER) { $env:NIFI_USER } else { 'etudiant' }
$p = if ($env:NIFI_PASS) { $env:NIFI_PASS } else { throw 'definir $env:NIFI_PASS (voir Hadoop/nifi/credentials.env, hors git)' }
$login=Invoke-RestMethod -Method Post -Uri "$base/access/token" -Body @{username=$u;password=$p} -ContentType 'application/x-www-form-urlencoded'
$h=@{Authorization="Bearer $login";'Content-Type'='application/json';Accept='application/json'}
$pg=(Invoke-RestMethod -Method Get -Uri "$base/process-groups/root" -Headers $h).id
$raw=Invoke-WebRequest -Method Get -Uri "$base/process-groups/$pg/processors" -Headers $h -UseBasicParsing
$j=$raw.Content|ConvertFrom-Json
foreach($p in $j.processors){
  $sn=$p.status.aggregateSnapshot
  Write-Host ("{0,-16} state={1,-9} queued={2,4}/{3,8} active={4,4} in={5,4} out={6,4}" -f $p.component.name,$p.component.state,$sn.queuedCount,$sn.queuedSize,$sn.activeThreadCount,$sn.inputCount,$sn.outputCount)
  if($p.component.validationErrors){ $p.component.validationErrors|ForEach-Object{ Write-Host "   VALID: $_" } }
  foreach($bl in $sn.bulletins){ Write-Host "   BULL: $($bl.bulletin.message)" }
  foreach($bt in $p.component.bulletins){ Write-Host "   COMP-BULL: $($bt.bulletin.message)" }
}
$raw2=Invoke-WebRequest -Method Get -Uri "$base/flow/process-groups/$pg/controller-services" -Headers $h -UseBasicParsing
$j2=$raw2.Content|ConvertFrom-Json
foreach($cs in $j2.controllerServices){ Write-Host ("{0,-18} state={1}" -f $cs.component.name,$cs.component.state) }