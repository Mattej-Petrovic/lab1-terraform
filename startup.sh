#!/bin/bash
set -euo pipefail

apt-get update
apt-get install -y ufw fail2ban unattended-upgrades auditd audispd-plugins libpam-pwquality

# ─── Brandvägg ───────────────────────────────────────────────
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw --force enable

# ─── Automatiska säkerhetsuppdateringar ──────────────────────
dpkg-reconfigure -plow unattended-upgrades

# ─── SSH-härdning ────────────────────────────────────────────
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^#*X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
sed -i 's/^#*MaxAuthTries.*/MaxAuthTries 3/' /etc/ssh/sshd_config
sed -i 's/^#*AllowAgentForwarding.*/AllowAgentForwarding no/' /etc/ssh/sshd_config
sed -i 's/^#*AllowTcpForwarding.*/AllowTcpForwarding no/' /etc/ssh/sshd_config
sed -i 's/^#*LoginGraceTime.*/LoginGraceTime 60/' /etc/ssh/sshd_config
echo "Protocol 2" >> /etc/ssh/sshd_config
systemctl restart sshd

# ─── Kernel-härdning via sysctl ──────────────────────────────
cat >> /etc/sysctl.conf << 'EOF'
# Disable IP forwarding
net.ipv4.ip_forward = 0
# Disable source routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
# Enable SYN cookies (skydd mot SYN flood)
net.ipv4.tcp_syncookies = 1
# Ignorera ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
# Logga suspicious packets
net.ipv4.conf.all.log_martians = 1
# Disable IPv6 om det inte används
net.ipv6.conf.all.disable_ipv6 = 1
EOF
sysctl -p

# ─── Filrättigheter ──────────────────────────────────────────
chmod 640 /etc/shadow
chmod 640 /etc/gshadow
chmod 644 /etc/passwd
chmod 644 /etc/group

# ─── Lösenordspolicy ─────────────────────────────────────────
sed -i 's/^# minlen.*/minlen = 14/' /etc/security/pwquality.conf
sed -i 's/^# dcredit.*/dcredit = -1/' /etc/security/pwquality.conf
sed -i 's/^# ucredit.*/ucredit = -1/' /etc/security/pwquality.conf
sed -i 's/^# lcredit.*/lcredit = -1/' /etc/security/pwquality.conf
sed -i 's/^# ocredit.*/ocredit = -1/' /etc/security/pwquality.conf

# ─── Auditd (loggning av systemhändelser) ────────────────────
systemctl enable auditd
systemctl start auditd

# ─── Ta bort onödiga tjänster ────────────────────────────────
apt-get remove -y --purge telnet rsh-client rsh-redone-client talk || true

# ─── Fail2ban-config ─────────────────────────────────────────
cat > /etc/fail2ban/jail.local << 'EOF'
[sshd]
enabled = true
maxretry = 3
bantime = 3600
findtime = 600
EOF
systemctl restart fail2ban

# ─── Installera Lynis för audit ──────────────────────────────
apt-get install -y lynis
lynis audit system --quiet --no-colors > /var/log/lynis-audit.log 2>&1 || true

echo "Startup script completed at $(date)" > /var/log/startup-complete.log