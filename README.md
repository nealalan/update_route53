
Scope:

- EC2 Ubuntu instance running with port 22, 80, 443 open
- Configure nginx to only use https and make sure it passes with an A+ on securityheaders.io

update_route53.sh - Initial code prior to having some issues with variables being set and used. I hard coded some of the variables in v2.0, with plans to convert them back in a future update.
update_route53.v2.sh - Place this on an Ubuntu EC2 instance to update the Route53 A DNS record with the net IP address

<img src="https://raw.githubusercontent.com/nealalan/update_route53/master/update_route53%202018-01-05%20at%2010.11.30%20PM.png">
