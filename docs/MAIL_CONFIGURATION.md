# WSMS PRO - Mail Configuration

This guide shows the simplest way to make WSMS email alerts work on Ubuntu.

Recommended approach: use `msmtp` as a lightweight SMTP relay instead of running a full mail server.

## What WSMS Needs

WSMS alert scripts use the local `mail` command.

For alerts to work, the server must have:

- a `mail` command available in PATH
- a configured mail transport that can actually send messages
- `ALERT_EMAIL` set in `~/scripts/wsms-config.sh`

WSMS configuration controls whether alerts are attempted:

```bash
ALERT_EMAIL="admin@example.com"
ALERT_ON_FAILURE="yes"
ALERT_ON_SUCCESS="no"
```

This does not configure mail delivery by itself. It only tells WSMS where and when to send alerts.

## Simplest Setup: msmtp

Install required packages:

```bash
sudo apt update
sudo apt install -y msmtp msmtp-mta bsd-mailx ca-certificates
```

Create mail configuration:

```bash
cat > ~/.msmtprc << 'EOF'
defaults
auth on
tls on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile ~/.msmtp.log

account default
host SMTP_HOST
port 587
from SMTP_FROM
user SMTP_USER
password SMTP_PASSWORD
EOF

chmod 600 ~/.msmtprc
```

You can also start from the example file stored in the repository:

```bash
cp docs/msmtprc.example ~/.msmtprc
chmod 600 ~/.msmtprc
```

Replace these values:

- `SMTP_HOST` - SMTP server, for example `smtp.office365.com`, `smtp.gmail.com`, `mail.example.com`
- `SMTP_FROM` - sender address, for example `admin@mindreflection.co.uk`
- `SMTP_USER` - SMTP login, usually full email address
- `SMTP_PASSWORD` - SMTP password or app password

## Manual Delivery Test

Test mail delivery before using WSMS alerts:

```bash
echo "manual test" | mail -s "WSMS manual test" admin@example.com
echo $?
```

If the last command returns `0`, submission to the local mail system succeeded.

Check the msmtp log:

```bash
cat ~/.msmtp.log
```

Optional `mail` wrapper configuration:

```bash
cp docs/mailrc.example ~/.mailrc
```

Then replace `SMTP_FROM` with the sender address you actually use.

## WSMS Test Commands

After mail is configured, test WSMS directly:

```bash
wsms-test-alert
wsms-daily-check
```

Notes:

- `wsms-test-alert` sends a test alert immediately.
- `wsms-daily-check` sends a success message only when `ALERT_ON_SUCCESS="yes"`.
- `wsms-daily-check` can also send a failure alert when it detects critical problems.

## Common Problems

### `mail: command not found`

Install the required packages:

```bash
sudo apt install -y msmtp msmtp-mta bsd-mailx
```

### WSMS says alert submitted, but no email arrives

This usually means SMTP delivery is failing outside WSMS.

Check:

```bash
cat ~/.msmtp.log
```

Typical causes:

- wrong SMTP host
- wrong username or password
- missing app password
- blocked outbound SMTP by hosting provider
- sender address rejected by SMTP server
- invalid envelope sender, for example `admin ubuntu_server` instead of `admin@example.com`

### Troubleshooting Step by Step (SMTP 501 / invalid sender)

If you see errors like:

- `sendmail: envelope from address ... not accepted by the server`
- `501 <admin ubuntu_server>: "@" or "." expected after "admin"`

follow this sequence:

1. Check the latest msmtp log entries:

```bash
tail -n 50 ~/.msmtp.log
```

2. Confirm the sender used by msmtp is a real email address:

```bash
grep -E '^from ' ~/.msmtprc
```

3. Fix `from` value in `~/.msmtprc` (must contain `@` and domain):

```bash
from admin@example.com
```

4. If you use `~/.mailrc`, ensure it matches the same sender:

```bash
grep -E '^set from=' ~/.mailrc
```

5. Send a manual test again:

```bash
echo "manual test after fix" | mail -s "WSMS sender test" admin@example.com
```

6. Re-check `~/.msmtp.log` and verify there is no SMTP 501 response.

7. Run WSMS test command:

```bash
wsms-test-alert
```

### `wsms-daily-check` runs but sends no success email

Set:

```bash
ALERT_ON_SUCCESS="yes"
```

in `~/scripts/wsms-config.sh`.

## Security Note

Do not commit real SMTP passwords into this repository.

Keep SMTP credentials only on the server in files such as:

- `~/.msmtprc`
- `~/scripts/wsms-config.sh`
