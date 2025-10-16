<#
.SYNOPSIS
    Evidence Bundle Manager - Deduplication, integrity, and lifecycle management
    
.DESCRIPTION
    Implements the evidence bundler component that produces one pack per packet
    with sub-entries per feature, deduplicating repeated diffs and linking all
    artifacts via packet manifest hashes for betrayal-resistant governance.
    
.NOTES
    Part of the optimized offline, governance-anchored resilience cockpit
    Maintains full auditability while minimizing storage footprint through deduplication
#>

#Requires -Version 5.1

[CmdletBinding()]
param(
    [string]$EvidenceRoot = "$env:USERPROFILE\Documents\WindowsGovernance\Evidence",
    [string]$CompressionLevel = 'Optimal',
    [int]$RetentionDays = 365,
    [switch]$EnableDeduplication = $true,
    [switch]$VerifyIntegrity = $true
)

# Import civic governance module
$ModulePath = Join-Path $PSScriptRoot "..\modules\CivicGovernance.psm1"
Import-Module $ModulePath -Force

Write-Host "=== Evidence Bundle Manager ===" -ForegroundColor Cyan
Write-Host "Optimized storage with integrity preservation" -ForegroundColor Gray

# Initialize evidence storage structure
$EvidenceStructure = @{
    Root = $EvidenceRoot
    Packs = Join-Path $EvidenceRoot "Packs"
    Deltas = Join-Path $EvidenceRoot "Deltas"
    Indices = Join-Path $EvidenceRoot "Indices"
    Archives = Join-Path $EvidenceRoot "Archives"
    Manifests = Join-Path $EvidenceRoot "Manifests"
}

# Create directory structure
foreach ($Dir in $EvidenceStructure.Values) {
    if (-not (Test-Path $Dir)) {
        New-Item -Path $Dir -ItemType Directory -Force | Out-Null
        Write-Host "   Created evidence directory: $Dir" -ForegroundColor Green
    }
}

<#
.SYNOPSIS
    Creates a deduplicated evidence pack from packet results
#>
function New-EvidencePack {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PacketId,
        
        [Parameter(Mandatory)]
        [hashtable]$PacketResults,
        
        [Parameter(Mandatory)]
        [hashtable]$PacketManifest
    )
    
    Write-Host "`n=== Creating Evidence Pack: $PacketId ===" -ForegroundColor Yellow
    
    $PackCreationStart = Get-Date
    $DeltaRegistry = @{}
    $FeatureReferences = @{}
    $DeduplicationStats = @{
        TotalEvidence = 0
        UniqueDeltas = 0
        DuplicatesFound = 0
        StorageSavings = 0
    }
    
    # Process each feature's evidence for deduplication
    foreach ($FeatureId in $PacketResults.Keys) {
        $FeatureResult = $PacketResults[$FeatureId]
        $Evidence = $FeatureResult.Evidence
        
        if ($null -eq $Evidence) { continue }
        
        $DeduplicationStats.TotalEvidence++
        
        # Convert evidence to normalized string for deduplication
        $EvidenceJson = $Evidence | ConvertTo-Json -Depth 10 -Compress
        $EvidenceHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($EvidenceJson)))).Hash
        
        if ($EnableDeduplication -and $DeltaRegistry.ContainsKey($EvidenceHash)) {
            # Evidence already exists - create reference
            $DeduplicationStats.DuplicatesFound++
            $DeduplicationStats.StorageSavings += $EvidenceJson.Length
            
            $FeatureReferences[$FeatureId] = @{
                Type = 'Reference'
                DeltaHash = $EvidenceHash
                FeatureStatus = $FeatureResult.Status
                FeatureYield = $FeatureResult.Yield
                Timestamp = (Get-Date).ToString('o')
            }
            
        } else {
            # New evidence - create delta entry
            $DeduplicationStats.UniqueDeltas++
            
            $DeltaId = "Delta_$($EvidenceHash.Substring(0,16))"
            $DeltaPath = Join-Path $EvidenceStructure.Deltas "$DeltaId.json"
            
            $DeltaEntry = @{
                Hash = $EvidenceHash
                Content = $Evidence
                Size = $EvidenceJson.Length
                Created = (Get-Date).ToString('o')
                ReferencedBy = @($FeatureId)
            }
            
            # Save delta to disk with compression
            if ($CompressionLevel -eq 'Optimal') {
                $CompressedContent = $EvidenceJson | ConvertTo-Json -Compress
                $CompressedContent | Out-File -FilePath $DeltaPath -Encoding UTF8
            } else {
                $DeltaEntry.Content | ConvertTo-Json -Depth 10 | Out-File -FilePath $DeltaPath -Encoding UTF8
            }
            
            $DeltaRegistry[$EvidenceHash] = @{
                DeltaId = $DeltaId
                Path = $DeltaPath
                Size = (Get-Item $DeltaPath).Length
                Hash = $EvidenceHash
            }
            
            $FeatureReferences[$FeatureId] = @{
                Type = 'Direct'
                DeltaHash = $EvidenceHash
                DeltaId = $DeltaId
                DeltaPath = $DeltaPath
                FeatureStatus = $FeatureResult.Status
                FeatureYield = $FeatureResult.Yield
                Timestamp = (Get-Date).ToString('o')
            }
        }
    }
    
    # Create pack manifest with integrity anchors
    $PackManifest = @{
        PacketId = $PacketId
        Created = (Get-Date).ToString('o')
        FeatureCount = $PacketResults.Count
        Deltas = $DeltaRegistry
        FeatureReferences = $FeatureReferences
        PacketManifest = $PacketManifest
        DeduplicationStats = $DeduplicationStats
        Integrity = @{
            Version = "1.0"
            Algorithm = "SHA256"
            ManifestHash = $null  # Will be calculated after serialization
        }
    }
    
    # Calculate manifest hash for integrity verification
    $ManifestJson = $PackManifest | ConvertTo-Json -Depth 15
    $ManifestHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($ManifestJson)))).Hash
    $PackManifest.Integrity.ManifestHash = $ManifestHash
    
    # Save pack manifest
    $PackManifestPath = Join-Path $EvidenceStructure.Manifests "$PacketId.json"
    $PackManifest | ConvertTo-Json -Depth 15 | Out-File -FilePath $PackManifestPath -Encoding UTF8
    
    # Create evidence pack index entry
    $PackIndex = @{
        PacketId = $PacketId
        ManifestPath = $PackManifestPath
        ManifestHash = $ManifestHash
        Created = (Get-Date).ToString('o')
        FeatureCount = $PacketResults.Count
        DeltaCount = $DeduplicationStats.UniqueDeltas
        ReferencesCount = $DeduplicationStats.DuplicatesFound
        StorageSavings = $DeduplicationStats.StorageSavings
        TotalSize = ($DeltaRegistry.Values | Measure-Object -Property Size -Sum).Sum
    }
    
    $PackIndexPath = Join-Path $EvidenceStructure.Indices "$PacketId.index.json"
    $PackIndex | ConvertTo-Json -Depth 10 | Out-File -FilePath $PackIndexPath -Encoding UTF8
    
    $PackCreationDuration = (Get-Date) - $PackCreationStart
    
    Write-Host "   SUCCESS: Evidence pack created in $($PackCreationDuration.TotalSeconds.ToString('F2'))s" -ForegroundColor Green
    Write-Host "   Features: $($PacketResults.Count), Unique deltas: $($DeduplicationStats.UniqueDeltas), References: $($DeduplicationStats.DuplicatesFound)" -ForegroundColor Gray
    Write-Host "   Storage savings: $($DeduplicationStats.StorageSavings) bytes ($([math]::Round($DeduplicationStats.StorageSavings / 1KB, 2)) KB)" -ForegroundColor Gray
    Write-Host "   Pack hash: $($ManifestHash.Substring(0,16))..." -ForegroundColor Magenta
    
    # Audit the pack creation
    Write-CeremonialAudit -Action "Evidence Pack Created" -Layer "Evidence-Management" -ConfigHash $ManifestHash -Metadata @{
        PacketId = $PacketId
        FeatureCount = $PacketResults.Count
        DeduplicationRatio = if ($DeduplicationStats.TotalEvidence -gt 0) { 
            [math]::Round($DeduplicationStats.DuplicatesFound / $DeduplicationStats.TotalEvidence * 100, 2) 
        } else { 0 }
        StorageSavings = $DeduplicationStats.StorageSavings
        CreationTime = $PackCreationDuration.TotalSeconds
    }
    
    return @{
        PacketId = $PacketId
        ManifestPath = $PackManifestPath
        ManifestHash = $ManifestHash
        IndexPath = $PackIndexPath
        DeduplicationStats = $DeduplicationStats
    }
}

<#
.SYNOPSIS
    Verifies integrity of evidence packs and their references
#>
function Test-EvidenceIntegrity {
    [CmdletBinding()]
    param(
        [string]$PacketId,
        [switch]$DeepScan
    )
    
    Write-Host "`n=== Verifying Evidence Integrity: $PacketId ===" -ForegroundColor Yellow
    
    $IntegrityResults = @{
        PacketId = $PacketId
        ManifestValid = $false
        DeltasValid = $false
        ReferencesValid = $false
        OverallValid = $false
        Issues = @()
        Details = @{}
    }
    
    try {
        # Load pack manifest
        $ManifestPath = Join-Path $EvidenceStructure.Manifests "$PacketId.json"
        if (-not (Test-Path $ManifestPath)) {
            $IntegrityResults.Issues += "Manifest file not found: $ManifestPath"
            return $IntegrityResults
        }
        
        $PackManifest = Get-Content $ManifestPath | ConvertFrom-Json
        
        # Verify manifest hash
        $ManifestContent = $PackManifest | ConvertTo-Json -Depth 15
        $CurrentManifestHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($ManifestContent)))).Hash
        
        if ($CurrentManifestHash -eq $PackManifest.Integrity.ManifestHash) {
            $IntegrityResults.ManifestValid = $true
            Write-Host "   SUCCESS: Manifest integrity verified" -ForegroundColor Green
        } else {
            $IntegrityResults.Issues += "Manifest hash mismatch"
            Write-Host "   FAILED: Manifest integrity compromised" -ForegroundColor Red
        }
        
        # Verify delta files
        $DeltaIssues = @()
        $ValidDeltas = 0
        
        foreach ($DeltaHash in $PackManifest.Deltas.Keys) {
            $DeltaInfo = $PackManifest.Deltas[$DeltaHash]
            $DeltaPath = $DeltaInfo.Path
            
            if (Test-Path $DeltaPath) {
                if ($DeepScan) {
                    # Deep scan: Verify delta content hash
                    $DeltaContent = Get-Content $DeltaPath -Raw
                    $DeltaContentHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($DeltaContent)))).Hash
                    
                    if ($DeltaContentHash -eq $DeltaHash) {
                        $ValidDeltas++
                    } else {
                        $DeltaIssues += "Delta content hash mismatch: $DeltaPath"
                    }
                } else {
                    # Quick scan: Just verify file exists and size
                    $FileInfo = Get-Item $DeltaPath
                    if ($FileInfo.Length -eq $DeltaInfo.Size) {
                        $ValidDeltas++
                    } else {
                        $DeltaIssues += "Delta file size mismatch: $DeltaPath"
                    }
                }
            } else {
                $DeltaIssues += "Delta file not found: $DeltaPath"
            }
        }
        
        if ($DeltaIssues.Count -eq 0) {
            $IntegrityResults.DeltasValid = $true
            Write-Host "   SUCCESS: All $ValidDeltas deltas verified" -ForegroundColor Green
        } else {
            $IntegrityResults.Issues += $DeltaIssues
            Write-Host "   FAILED: $($DeltaIssues.Count) delta issues found" -ForegroundColor Red
        }
        
        # Verify feature references
        $ReferenceIssues = @()
        $ValidReferences = 0
        
        foreach ($FeatureId in $PackManifest.FeatureReferences.Keys) {
            $Reference = $PackManifest.FeatureReferences[$FeatureId]
            $DeltaHash = $Reference.DeltaHash
            
            if ($PackManifest.Deltas.ContainsKey($DeltaHash)) {
                $ValidReferences++
            } else {
                $ReferenceIssues += "Feature $FeatureId references non-existent delta: $DeltaHash"
            }
        }
        
        if ($ReferenceIssues.Count -eq 0) {
            $IntegrityResults.ReferencesValid = $true
            Write-Host "   SUCCESS: All $ValidReferences feature references verified" -ForegroundColor Green
        } else {
            $IntegrityResults.Issues += $ReferenceIssues
            Write-Host "   FAILED: $($ReferenceIssues.Count) reference issues found" -ForegroundColor Red
        }
        
        # Overall integrity assessment
        $IntegrityResults.OverallValid = $IntegrityResults.ManifestValid -and $IntegrityResults.DeltasValid -and $IntegrityResults.ReferencesValid
        
        $IntegrityResults.Details = @{
            ManifestHash = $PackManifest.Integrity.ManifestHash
            DeltaCount = $PackManifest.Deltas.Count
            FeatureCount = $PackManifest.FeatureReferences.Count
            DeduplicationRatio = if ($PackManifest.FeatureReferences.Count -gt 0) {
                [math]::Round($PackManifest.DeduplicationStats.DuplicatesFound / $PackManifest.FeatureReferences.Count * 100, 2)
            } else { 0 }
        }
        
        if ($IntegrityResults.OverallValid) {
            Write-Host "   SUCCESS: Complete evidence pack integrity verified" -ForegroundColor Green
        } else {
            Write-Host "   FAILED: Evidence pack integrity compromised ($($IntegrityResults.Issues.Count) issues)" -ForegroundColor Red
        }
        
    } catch {
        $IntegrityResults.Issues += "Integrity verification failed: $($_.Exception.Message)"
        Write-Host "   ERROR: Integrity verification exception: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    return $IntegrityResults
}

<#
.SYNOPSIS
    Retrieves feature evidence from deduplicated storage
#>
function Get-FeatureEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$PacketId,
        
        [Parameter(Mandatory)]
        [string]$FeatureId
    )
    
    Write-Host "Retrieving evidence for feature $FeatureId from packet $PacketId..." -ForegroundColor Gray
    
    try {
        # Load pack manifest
        $ManifestPath = Join-Path $EvidenceStructure.Manifests "$PacketId.json"
        if (-not (Test-Path $ManifestPath)) {
            Write-Warning "Pack manifest not found: $ManifestPath"
            return $null
        }
        
        $PackManifest = Get-Content $ManifestPath | ConvertFrom-Json
        
        # Find feature reference
        if (-not $PackManifest.FeatureReferences.ContainsKey($FeatureId)) {
            Write-Warning "Feature not found in pack: $FeatureId"
            return $null
        }
        
        $FeatureReference = $PackManifest.FeatureReferences[$FeatureId]
        $DeltaHash = $FeatureReference.DeltaHash
        
        # Load delta content
        if ($PackManifest.Deltas.ContainsKey($DeltaHash)) {
            $DeltaInfo = $PackManifest.Deltas[$DeltaHash]
            $DeltaPath = $DeltaInfo.Path
            
            if (Test-Path $DeltaPath) {
                $DeltaContent = Get-Content $DeltaPath | ConvertFrom-Json
                
                return @{
                    FeatureId = $FeatureId
                    Evidence = $DeltaContent.Content
                    Status = $FeatureReference.FeatureStatus
                    Yield = $FeatureReference.FeatureYield
                    Timestamp = $FeatureReference.Timestamp
                    DeltaHash = $DeltaHash
                    RetrievedAt = (Get-Date).ToString('o')
                }
            } else {
                Write-Warning "Delta file not found: $DeltaPath"
                return $null
            }
        } else {
            Write-Warning "Delta not found in pack: $DeltaHash"
            return $null
        }
        
    } catch {
        Write-Error "Failed to retrieve feature evidence: $($_.Exception.Message)"
        return $null
    }
}

<#
.SYNOPSIS
    Manages evidence lifecycle and retention policies
#>
function Invoke-EvidenceLifecycleManagement {
    [CmdletBinding()]
    param(
        [int]$RetentionDays = 365,
        [switch]$ArchiveOldEvidence = $true,
        [switch]$CompressArchives = $true
    )
    
    Write-Host "`n=== Evidence Lifecycle Management ===" -ForegroundColor Yellow
    
    $CutoffDate = (Get-Date).AddDays(-$RetentionDays)
    $ManagementStats = @{
        PacksProcessed = 0
        PacksArchived = 0
        PacksDeleted = 0
        StorageReclaimed = 0
    }
    
    # Process all pack manifests
    $ManifestFiles = Get-ChildItem -Path $EvidenceStructure.Manifests -Filter "*.json"
    
    foreach ($ManifestFile in $ManifestFiles) {
        try {
            $PackManifest = Get-Content $ManifestFile.FullName | ConvertFrom-Json
            $PackCreated = [DateTime]::Parse($PackManifest.Created)
            $ManagementStats.PacksProcessed++
            
            if ($PackCreated -lt $CutoffDate) {
                if ($ArchiveOldEvidence) {
                    # Archive old evidence
                    $ArchiveName = "$($PackManifest.PacketId)_$(Get-Date -Format 'yyyyMMdd').zip"
                    $ArchivePath = Join-Path $EvidenceStructure.Archives $ArchiveName
                    
                    # Create archive of pack and associated deltas
                    $FilesToArchive = @($ManifestFile.FullName)
                    
                    foreach ($DeltaHash in $PackManifest.Deltas.Keys) {
                        $DeltaInfo = $PackManifest.Deltas[$DeltaHash]
                        if (Test-Path $DeltaInfo.Path) {
                            $FilesToArchive += $DeltaInfo.Path
                        }
                    }
                    
                    if ($CompressArchives) {
                        Compress-Archive -Path $FilesToArchive -DestinationPath $ArchivePath -Force
                        
                        # Remove original files after successful archiving
                        foreach ($File in $FilesToArchive) {
                            $OriginalSize = (Get-Item $File).Length
                            Remove-Item $File -Force
                            $ManagementStats.StorageReclaimed += $OriginalSize
                        }
                    }
                    
                    $ManagementStats.PacksArchived++
                    Write-Host "   Archived: $($PackManifest.PacketId)" -ForegroundColor Gray
                    
                } else {
                    # Delete old evidence
                    foreach ($DeltaHash in $PackManifest.Deltas.Keys) {
                        $DeltaInfo = $PackManifest.Deltas[$DeltaHash]
                        if (Test-Path $DeltaInfo.Path) {
                            $OriginalSize = (Get-Item $DeltaInfo.Path).Length
                            Remove-Item $DeltaInfo.Path -Force
                            $ManagementStats.StorageReclaimed += $OriginalSize
                        }
                    }
                    
                    $OriginalSize = (Get-Item $ManifestFile.FullName).Length
                    Remove-Item $ManifestFile.FullName -Force
                    $ManagementStats.StorageReclaimed += $OriginalSize
                    
                    $ManagementStats.PacksDeleted++
                    Write-Host "   Deleted: $($PackManifest.PacketId)" -ForegroundColor Gray
                }
            }
            
        } catch {
            Write-Warning "Failed to process pack manifest $($ManifestFile.Name): $($_.Exception.Message)"
        }
    }
    
    Write-Host "   SUCCESS: Lifecycle management completed" -ForegroundColor Green
    Write-Host "   Processed: $($ManagementStats.PacksProcessed) packs" -ForegroundColor Gray
    Write-Host "   Archived: $($ManagementStats.PacksArchived) packs" -ForegroundColor Gray
    Write-Host "   Deleted: $($ManagementStats.PacksDeleted) packs" -ForegroundColor Gray
    Write-Host "   Storage reclaimed: $([math]::Round($ManagementStats.StorageReclaimed / 1MB, 2)) MB" -ForegroundColor Gray
    
    return $ManagementStats
}

# Export functions for use by other modules
Export-ModuleMember -Function @(
    'New-EvidencePack',
    'Test-EvidenceIntegrity', 
    'Get-FeatureEvidence',
    'Invoke-EvidenceLifecycleManagement'
)