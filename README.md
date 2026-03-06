# polaris
Market trend analysis

## Clone with status verification and retry

Use `clone_repo_with_retry.sh` to clone a repository, verify the clone status, and retry automatically if verification fails.

```bash
bash ./clone_repo_with_retry.sh <repo_url> <target_dir> [max_retries] [retry_delay_seconds]
```
