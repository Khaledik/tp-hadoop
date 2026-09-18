$ErrorActionPreference="Stop"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[System.Net.ServicePointManager]::SecurityProtocol='Tls12'
$base='https://localhost:8443/nifi-api'
$u = if ($env:NIFI_USER) { $env:NIFI_USER } else { 'etudiant' }
$p = if ($env:NIFI_PASS) { $env:NIFI_PASS } else { throw 'definir $env:NIFI_PASS (voir Hadoop/nifi/credentials.env, hors git)' }
$login=Invoke-RestMethod -Method Post -Uri "$base/access/token" -Body @{username=$u;password=$p} -ContentType 'application/x-www-form-urlencoded'
$h=@{Authorization="Bearer $login";'Content-Type'='application/json';Accept='application/json'}

$start=(Get-Date).ToUniversalTime().AddMinutes(-30).ToString('MM-dd-yyyy HH:mm:ss.fff').Replace('-','/')
$end=(Get-Date).ToUniversalTime().ToString('MM-dd-yyyy HH:mm:ss.fff').Replace('-','/')
Write-Host "start=$start end=$end"

$bodyJson="{""provenance"":{""request"":{""maxResults"":80,""summarize"":false,""incrementalResults"":false,""startDate"":""$start"",""endDate"":""$end""}}}"
Write-Host "BODY: $bodyJson"
$r=Invoke-WebRequest -Method Post -Uri "$base/provenance" -Headers $h -Body $bodyJson -UseBasicParsing
Write-Host "POST HTTP=$($r.StatusCode)"
$qid=[regex]::Match($r.Content,'"id"\s*:\s*"([^"]+)"').Groups[1].Value
Write-Host "queryId=$qid"

for($i=0;$i -lt 15;$i++){
  Start-Sleep -Seconds 2
  $res=Invoke-RestMethod -Method Get -Uri "$base/provenance/$qid/results" -Headers $h
  if($res.provenance.finished){ break }
}
Write-Host "finished=$($res.provenance.finished) total=$($res.provenance.results.total)"
foreach($ev in $res.provenance.results.provenanceEvents){
  $fn=""
  if($ev.filename){ $fn=$ev.filename }
  $comp=""
  if($ev.componentDetails.name){ $comp=$ev.componentDetails.name }
  $rel=""
  if($ev.details.relationship){ $rel=$ev.details.relationship }
  Write-Host ("{0,-35} {1,-22} {2,-18} {3}" -f $fn,$ev.eventType,$comp,$rel)
}