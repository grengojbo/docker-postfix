#!/bin/bash

#judgement
#if [[ -a /etc/supervisor/conf.d/supervisord.conf ]]; then
#  exit 0
#fi

#supervisor
#cat > /etc/supervisor/conf.d/supervisord.conf <<EOF
#[supervisord]
#nodaemon=true
#
#[program:postfix]
#command=/opt/postfix.sh
#
#[program:rsyslog]
#command=/usr/sbin/rsyslogd -n -c3
#EOF

############
#  postfix
############
# cat >> /opt/postfix.sh <<EOF
# #!/bin/bash
# service postfix start
# tail -f /var/log/mail.log
# EOF
# chmod +x /opt/postfix.sh
# postconf -e myhostname=$maildomain
if [[ -n "$MAIL_HOSTNAME" ]]; then
  postconf -e myhostname=$MAIL_HOSTNAME
fi
if [[ -n "$MAIL_DOMAIN" ]]; then
  postconf -e mydomain=$MAIL_DOMAIN
fi
postconf -e "mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain"
postconf -F '*/*/chroot = n'

# No Open Proxy / No Spam
postconf -e smtpd_sender_restrictions=permit_sasl_authenticated,permit_mynetworks,reject_unknown_sender_domain,permit
postconf -e smtpd_helo_restrictions=permit_mynetworks,reject_invalid_hostname,permit
postconf -e smtpd_relay_restrictions=permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination
postconf -e "smtpd_recipient_restrictions=permit_mynetworks,permit_inet_interfaces,permit_sasl_authenticated,reject_invalid_hostname,reject_non_fqdn_hostname,reject_non_fqdn_sender,reject_non_fqdn_recipient,reject_rbl_client zen.spamhaus.org,permit"

############
# SASL SUPPORT FOR CLIENTS
# The following options set parameters needed by Postfix to enable
# Cyrus-SASL support for authentication of mail clients.
############
# /etc/postfix/main.cf
postconf -e smtpd_sasl_auth_enable=yes
postconf -e broken_sasl_auth_clients=yes
# postconf -e smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination
# smtpd.conf
cat >> /etc/postfix/sasl/smtpd.conf <<EOF
pwcheck_method: auxprop
auxprop_plugin: sasldb
mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5 NTLM
EOF
# sasldb2
echo $smtp_user | tr , \\n > /tmp/passwd
while IFS=':' read -r _user _pwd; do
  # echo $_pwd | saslpasswd2 -p -c -u $maildomain $_user
  echo $_pwd | saslpasswd2 -p -c -u $MAIL_HOSTNAME $_user
done < /tmp/passwd
chown postfix.sasl /etc/sasldb2

############
# Enable TLS
############
if [[ -n "$(find /etc/postfix/certs -iname *.crt)" && -n "$(find /etc/postfix/certs -iname *.key)" ]]; then
  # /etc/postfix/main.cf
  postconf -e smtpd_tls_cert_file=$(find /etc/postfix/certs -iname *.crt)
  postconf -e smtpd_tls_key_file=$(find /etc/postfix/certs -iname *.key)
  chmod 400 /etc/postfix/certs/*.*
  # /etc/postfix/master.cf
  postconf -M submission/inet="submission   inet   n   -   n   -   -   smtpd"
  postconf -P "submission/inet/syslog_name=postfix/submission"
  postconf -P "submission/inet/smtpd_tls_security_level=encrypt"
  postconf -P "submission/inet/smtpd_sasl_auth_enable=yes"
  postconf -P "submission/inet/milter_macro_daemon_name=ORIGINATING"
  # postconf -P "submission/inet/smtpd_recipient_restrictions=permit_sasl_authenticated,reject_unauth_destination"
fi

#############
#  opendkim
#############

if [[ -z "$(find /etc/opendkim/domainkeys -iname *.private)" ]]; then
  exit 0
fi
cat >> /etc/supervisor/conf.d/supervisord.conf <<EOF

[program:opendkim]
command=/usr/sbin/opendkim -f
EOF
# /etc/postfix/main.cf
postconf -e milter_protocol=2
postconf -e milter_default_action=accept
postconf -e smtpd_milters=inet:localhost:12301
postconf -e non_smtpd_milters=inet:localhost:12301

cat >> /etc/opendkim.conf <<EOF
AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes

Canonicalization        relaxed/simple

ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable

Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256

UserID                  opendkim:opendkim

Socket                  inet:12301@localhost
EOF
cat >> /etc/default/opendkim <<EOF
SOCKET="inet:12301@localhost"
EOF

cat >> /etc/opendkim/TrustedHosts <<EOF
127.0.0.1
localhost
192.168.0.1/24

*.$maildomain
EOF
cat >> /etc/opendkim/KeyTable <<EOF
mail._domainkey.$MAIL_HOSTNAME $MAIL_HOSTNAME:mail:$(find /etc/opendkim/domainkeys -iname *.private)
EOF
cat >> /etc/opendkim/SigningTable <<EOF
*@$MAIL_HOSTNAME mail._domainkey.$MAIL_HOSTNAME
EOF
chown opendkim:opendkim $(find /etc/opendkim/domainkeys -iname *.private)
chmod 400 $(find /etc/opendkim/domainkeys -iname *.private)