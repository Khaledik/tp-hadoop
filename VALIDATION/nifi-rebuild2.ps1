$ErrorActionPreference="Stop"
[System.Net.ServicePointManager]::ServerCertificateValidationCallback={$true}
[System.Net.ServicePointManager]::SecurityProtocol='Tls12'
$base='https://localhost:8443/nifi-api'
$u = if ($env:NIFI_USER) { $env:NIFI_USER } else { 'etudiant' }
$p = if ($env:NIFI_PASS) { $env:NIFI_PASS } else { throw 'definir $env:NIFI_PASS (voir Hadoop/nifi/credentials.env, hors git)' }
$login=Invoke-RestMethod -Method Post -Uri "$base/access/token" -Body @{username=$u;password=$p} -ContentType 'application/x-www-form-urlencoded'
$h=@{Authorization="Bearer $login";'Content-Type'='application/json';Accept='application/json'}
$pg=(Invoke-RestMethod -Method Get -Uri "$base/process-groups/root" -Headers $h).id
$convId='9a73fb7c-01a0-1000-6be8-6c968dffea9d'
$conn3='9a73fc56-01a0-1000-86bb-01e7c5df9f52'
$readerId='9a73f921-01a0-1000-ee3e-c658e7b5f292'
$writerId='9a73fb13-01a0-1000-2c7e-2e8a8103b26a'
$gfId='9a73f80b-01a0-1000-fb1c-e94b1aeeffca'
$peId='9a73f85d-01a0-1000-a541-23e204e3b391'
$pmId='9a73fb9b-01a0-1000-f9cb-1fe934ba1c28'

# drop queue of conn3
$dr=Invoke-RestMethod -Method Post -Uri "$base/connections/$conn3/drop-request" -Headers $h
for($i=0;$i -lt 20;$i++){
  Start-Sleep -Seconds 2
  $st=Invoke-RestMethod -Method Get -Uri "$base/connections/$conn3/drop-request/$($dr.dropRequest.id)" -Headers $h
  if($st.dropRequest.finished){ break }
}
Write-Host "drop finished=$($st.dropRequest.finished) dropped=$($st.dropRequest.droppedCount)"

# delete conn3
$conns=Invoke-RestMethod -Method Get -Uri "$base/process-groups/$pg/connections" -Headers $h
foreach($c in $conns.connections){
  if($c.id -eq $conn3){
    $null=Invoke-WebRequest -Method Delete -Uri "$base/connections/$conn3?version=$($c.revision.version)&clientId=val" -Headers $h -UseBasicParsing
    Write-Host "deleted conn3 ($($c.component.name))"
  }
}

# delete ConvertRecord
$ptr=Invoke-RestMethod -Method Get -Uri "$base/processors/$convId" -Headers $h
$null=Invoke-WebRequest -Method Delete -Uri "$base/processors/$convId?version=$($ptr.revision.version)&clientId=val" -Headers $h -UseBasicParsing
Write-Host "deleted ConvertRecord"

# recreate
$prop=@{'Record Reader'=$readerId;'Record Writer'=$writerId;'Include Zero Record FlowFiles'='true'}
$body=@{revision=@{clientId='val';version=0};component=@{parentGroupId=$pg;name='ConvertRecord';type='org.apache.nifi.processors.standard.ConvertRecord';position=@{x=300;y=0};config=@{properties=$prop;schedulingPeriod='5 sec';autoTerminatedRelationships=@()}}}
$e=Invoke-RestMethod -Method Post -Uri "$base/process-groups/$pg/processors" -Headers $h -Body ($body|ConvertTo-Json -Depth 10)
$newId=$e.component.id
Write-Host "new ConvertRecord id=$newId"
if($e.component.validationErrors){ $e.component.validationErrors|ForEach-Object{"  VALID: $_"} } else { Write-Host "  no validation errors" }

function New-Conn($src,$rel,$dst){
  $b=@{revision=@{clientId='val';version=0};component=@{parentGroupId=$pg;source=@{id=$src;type='PROCESSOR';groupId=$pg};destination=@{id=$dst;type='PROCESSOR';groupId=$pg};selectedRelationships=@($rel);backPressureObjectThreshold=10000;backPressureDataSizeThreshold='1 GB'}}
  $null=Invoke-RestMethod -Method Post -Uri "$base/process-groups/$pg/connections" -Headers $h -Body ($b|ConvertTo-Json -Depth 10)
  Write-Host "conn $src/$rel -> $dst"
}
New-Conn $gfId 'success' $newId
New-Conn $newId 'success' $pmId
New-Conn $newId 'failure' $peId

function RunProc($id){
  $raw=(Invoke-WebRequest -Method Get -Uri "$base/processors/$id" -Headers $h -UseBasicParsing).Content
  $v=[int][regex]::Match($raw,'"version":(\d+)').Groups[1].Value
  $b=@{revision=@{clientId='val';version=$v};state='RUNNING';disconnectedNodeAcknowledged=$false}
  $null=Invoke-WebRequest -Method Put -Uri "$base/processors/$id/run-status" -Headers $h -Body ($b|ConvertTo-Json -Depth 6) -UseBasicParsing
}
RunProc $gfId; RunProc $newId; RunProc $pmId; RunProc $peId
Start-Sleep -Seconds 3
Write-Host "all running"
Write-Host "REBUILD_DONE id=$newId"