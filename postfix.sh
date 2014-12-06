#!/bin/bash
# service saslauthd start
service postfix start
tail -f /var/log/mail.log