# 🔄 n8n Workflow 1: Blockchain Backup Automation

## 🎯 **PRIORITY 1** - Deploy This First!

**Purpose:** Automatically backup blockchain ledger to Azure Blob Storage every 4 hours with immutability protection.

**Status:** Ready to create
**Estimated Time:** 30-45 minutes (first time)
**Frequency:** Every 4 hours
**Criticality:** 🔥 **CRITICAL** - Protects audit trail

---

## 📋 Step-by-Step Setup

### Step 1: Create New Workflow

1. **Open n8n**: http://localhost:5678
2. **Login** with:
   - Username: `civic-admin`
   - Password: `ChangeMeToSecurePassword!` (or your password)
3. **Click "+ Workflow"** (top-right, or "Add Workflow" button)
4. **Name it**: "Blockchain Backup (Every 4 Hours)"
5. **Click "Save"** (top-right)

---

### Step 2: Add Schedule Trigger

1. **Click "+" on canvas** → Search for "Schedule Trigger"
2. **Select "Schedule Trigger"** node
3. **Configure**:
   - Mode: `Every X hours`
   - Hours: `4`
   - Minutes: `0`
4. **Click "Execute Node"** to test (should show success)

---

### Step 3: Add Read Binary File Node

1. **Click "+" after Schedule Trigger** → Search for "Read Binary Files"
2. **Select "Read Binary Files"** node
3. **Configure**:
   - File Selector: `File Path`
   - File Path: `/civic/logs/council_ledger.jsonl`
4. **Click "Execute Node"** to test
   - Should show file contents in binary data

**Troubleshooting:**

- If "File not found" error:
  - Check volume mounts in `docker-compose.yml`
  - Verify file exists: `ls ../../logs/council_ledger.jsonl`
  - Restart container: `docker-compose restart n8n`

---

### Step 4: Add Code Node (Generate Timestamp Filename)

1. **Click "+" after Read Binary Files** → Search for "Code"
2. **Select "Code"** node
3. **Configure**:

   - Language: `JavaScript`
   - Code:

   ```javascript
   // Generate timestamped filename
   const now = new Date();
   const timestamp = now.toISOString().replace(/[:.]/g, "-");
   const filename = `council_ledger_${timestamp}.jsonl`;

   // Pass through binary data with new filename
   return [
     {
       json: {
         filename: filename,
         timestamp: now.toISOString(),
         originalPath: "/civic/logs/council_ledger.jsonl",
       },
       binary: {
         data: $input.item.binary.data,
       },
     },
   ];
   ```

4. **Click "Execute Node"** to test
   - Should show filename like: `council_ledger_2025-10-17T01-32-00-000Z.jsonl`

---

### Step 5: Add Azure Blob Storage Node (Upload)

#### 5a. Create Azure Blob Storage Credential

1. **Go to "Credentials" menu** (left sidebar)
2. **Click "Add Credential"**
3. **Search for "Azure Storage"** → Select **"Azure Blob Storage"**
4. **Configure**:
   - Credential Name: `civic-azure-storage`
   - Account Name: Your Azure Storage account (e.g., `civicstorage`)
   - Account Key: Get from Azure Portal:
     ```
     Azure Portal → Storage Accounts → [Your Account] →
     Access Keys → Show keys → Copy key1
     ```
5. **Click "Test"** to verify connection
6. **Click "Save"**

#### 5b. Add Azure Blob Storage Node

1. **Click "+" after Code node** → Search for "Azure Blob Storage"
2. **Select "Azure Blob Storage"** node
3. **Configure**:
   - Credential: `civic-azure-storage`
   - Resource: `File`
   - Operation: `Upload`
   - Container Name: `blockchain-backups-immutable`
     - **Note:** Create this container in Azure Portal first:
       ```
       Azure Portal → Storage Accounts → [Account] →
       Containers → + Container → Name: blockchain-backups-immutable →
       Public access: Private → Advanced: Enable version-level immutability
       ```
   - Blob Name: `={{ $json.filename }}`
   - Input Data Field Name: `data`
4. **Click "Execute Node"** to test
   - Should show success message
   - Check Azure Portal to verify file uploaded

**Troubleshooting:**

- "Container not found": Create container in Azure Portal first
- "Authentication failed": Verify account name and key in credential
- "Forbidden": Check storage account firewall rules

---

### Step 6: Add If Node (Success/Failure Check)

1. **Click "+" after Azure Blob** → Search for "If"
2. **Select "If"** node
3. **Configure**:
   - Condition: `Value 1`
     - Type: `String`
     - Value1: `={{ $json.statusCode }}`
   - Operation: `Equal`
   - Value 2: `201` (or `200`)

This will split the workflow into success/failure paths.

---

### Step 7: Add Discord Webhook (Success Notification)

#### 7a. Create Discord Webhook

1. **Go to your Discord server** → Server Settings → Integrations → Webhooks
2. **Click "New Webhook"**
3. **Configure**:
   - Name: `Civic Blockchain Alerts`
   - Channel: Select channel for notifications
4. **Copy Webhook URL**
5. **Click "Save"**

#### 7b. Add Discord Node (Success Branch)

1. **Click "+" after "true" branch of If node** → Search for "Discord"
2. **Select "Discord"** node
3. **Configure**:

   - Credential: Click "Create New"
     - Webhook URL: Paste Discord webhook URL
     - Save as: `civic-discord-webhook`
   - Resource: `Message`
   - Operation: `Send`
   - Webhook URL: (auto-filled from credential)
   - Content:

   ```
   ✅ **Blockchain Backup Success**

   **Time:** {{ $now.format('yyyy-MM-dd HH:mm:ss') }}
   **File:** {{ $('Code').item.json.filename }}
   **Location:** Azure Blob Storage → blockchain-backups-immutable
   **Status:** Uploaded successfully

   🔒 Immutability: 90-day retention lock active
   ```

4. **Click "Execute Node"** to test
   - Should send message to Discord channel

---

### Step 8: Add Discord Webhook (Failure Notification)

1. **Click "+" after "false" branch of If node** → Search for "Discord"
2. **Select "Discord"** node
3. **Configure**:

   - Credential: `civic-discord-webhook` (same as above)
   - Resource: `Message`
   - Operation: `Send`
   - Content:

   ```
   ❌ **Blockchain Backup FAILED**

   **Time:** {{ $now.format('yyyy-MM-dd HH:mm:ss') }}
   **Error:** {{ $json.error || 'Unknown error' }}

   ⚠️ **ACTION REQUIRED:** Check n8n execution logs for details.
   Manual backup may be needed.
   ```

4. **Click "Execute Node"** to test

---

### Step 9: Add Error Trigger (Catch All Failures)

1. **Click "+" on canvas** (not connected to anything) → Search for "Error Trigger"
2. **Select "Error Trigger"** node
3. This will catch any errors not handled by the If node

4. **Connect to Discord node** (create another Discord node for error notifications):

   - Content:

   ```
   🚨 **CRITICAL: Blockchain Backup Workflow Error**

   **Time:** {{ $now.format('yyyy-MM-dd HH:mm:ss') }}
   **Node:** {{ $json.node.name }}
   **Error:** {{ $json.error.message }}

   ⚠️ **URGENT ACTION REQUIRED**
   Check n8n immediately!
   ```

---

### Step 10: Activate Workflow

1. **Click "Save"** (top-right)
2. **Toggle "Active" switch** (top-right) → Turn ON
3. **Workflow is now running!** 🎉

---

## ✅ Verification Checklist

After setup, verify:

- ✅ Workflow is "Active" (toggle in top-right)
- ✅ Schedule Trigger shows next execution time
- ✅ Manual test execution succeeds (click "Execute Workflow")
- ✅ File appears in Azure Blob Storage
- ✅ Discord notification received
- ✅ Immutability policy active on container (90-day lock)

---

## 🔍 Testing the Workflow

### Manual Test Execution

1. **Click "Execute Workflow"** (top-right, next to Active toggle)
2. **Wait for execution** (should take 5-10 seconds)
3. **Check results**:
   - All nodes should show green checkmarks
   - Azure Blob Storage node shows "1 item"
   - Discord node shows "1 item"
4. **Verify in Azure Portal**:
   - Go to Storage Account → Containers → blockchain-backups-immutable
   - Should see file: `council_ledger_2025-10-17T...jsonl`
5. **Check Discord channel**:
   - Should see success notification

### Wait for Automatic Execution

- **Next run**: Check Schedule Trigger node for "Next Execution"
- **View executions**: Go to "Executions" tab (left sidebar)
- **Filter by workflow**: Select "Blockchain Backup (Every 4 Hours)"

---

## 📊 Monitoring & Maintenance

### Check Execution History

1. **Go to "Executions" tab** (left sidebar)
2. **Filter by**:
   - Workflow: "Blockchain Backup (Every 4 Hours)"
   - Status: "Success" or "Error"
   - Time range: Last 7 days
3. **Click any execution** to see details

### Azure Storage Monitoring

```powershell
# List recent backups
az storage blob list \
  --account-name civicstorage \
  --container-name blockchain-backups-immutable \
  --output table

# Check blob properties (including immutability)
az storage blob show \
  --account-name civicstorage \
  --container-name blockchain-backups-immutable \
  --name council_ledger_2025-10-17T....jsonl
```

### Retention Policy

- **Local**: Indefinite (C:\civic-infrastructure\logs\council_ledger.jsonl)
- **Azure Blob**: Indefinite (immutable 90 days, then modifiable)
- **Backups kept**: All backups (no auto-deletion)
- **Manual cleanup**: Review quarterly, delete old backups if needed

---

## 🛠️ Troubleshooting

### Workflow Not Triggering

**Check:**

- Workflow is Active (toggle is ON)
- Schedule Trigger shows "Next Execution" time
- Container is running: `docker ps | findstr civic-n8n`

**Fix:**

```powershell
# Restart container
cd docker\n8n
docker-compose restart n8n

# Check logs
docker logs civic-n8n --tail 50
```

### File Not Found Error

**Check:**

- Volume mounts in `docker-compose.yml`
- File exists: `ls logs\council_ledger.jsonl`

**Fix:**

```yaml
# In docker-compose.yml, verify:
volumes:
  - ../../logs:/civic/logs:ro # :ro = read-only
```

### Azure Upload Fails

**Check:**

- Credential has correct account name + key
- Container exists in Azure Portal
- Firewall rules allow access

**Fix:**

1. Test credential: Credentials → civic-azure-storage → Test
2. Check Azure Portal: Storage Account → Networking → Firewall
3. Add your IP or allow all networks (for testing)

### Discord Notifications Not Sending

**Check:**

- Webhook URL is correct
- Discord channel exists
- Webhook not deleted in Discord

**Fix:**

1. Recreate webhook in Discord
2. Update credential in n8n
3. Test Discord node manually

---

## 📈 Success Metrics

After 24 hours, you should have:

- ✅ 6 successful backups (every 4 hours)
- ✅ 6 files in Azure Blob Storage
- ✅ 6 Discord notifications received
- ✅ 0 errors in Executions tab
- ✅ Blockchain ledger safe and protected

---

## 🚀 Next Steps

After Workflow 1 is working:

1. ✅ **Create Workflow 2**: Evidence Bundle Validation
2. ✅ **Create Workflow 3**: Service Health Check
3. ✅ **Create Workflow 4**: AI Error Analysis
4. ✅ **Export workflows** to JSON (Workflow menu → Download)
5. ✅ **Backup n8n data**: `Copy-Item -Recurse .\n8n-data .\n8n-data-backup`
6. ✅ **Log to blockchain**: Record #10 (n8n deployment + first workflow)

---

## 📚 Additional Resources

- **n8n Schedule Trigger Docs**: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.scheduletrigger/
- **Azure Blob Storage Node**: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.microsoftazure/
- **Discord Webhook**: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.discord/
- **Code Node Examples**: https://docs.n8n.io/code/builtin/code-node-examples/

---

**Created:** 2025-10-17
**Version:** 1.0
**Status:** Ready to implement
**Est. Time:** 30-45 minutes
**Priority:** 🔥 **CRITICAL**

🎯 **Your Mission:** Create this workflow in the next hour to protect your blockchain ledger!

