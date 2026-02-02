# Infrastructure-Host

## Multipass Network Troubleshooting

When multipass has network issues (e.g., "Remote is unknown or unreachable"):

1. **If running elevated (Administrator):**
   - Purge bad/stale entries from `C:\Windows\System32\drivers\etc\hosts.ics`
   - Restart the SharedAccess service (Internet Connection Sharing):
     ```powershell
     Restart-Service SharedAccess
     ```

2. **Then retry the multipass operation**
