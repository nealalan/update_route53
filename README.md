
Scope:

- EC2 Ubuntu instance running with port 22, 80, 443 open
- Configure nginx to only use https and make sure it passes with an A+ on securityheaders.io

Backgroup: 

Initially I needed this because my EC2 instances are on a different account than my route 53 DNS records. What a hassle! Next problem was ssh'ing into ubuntu@neonaluminum.com - oops can't do that since the DNS record isn't updated. And I don't know my *new* IP address off the top of my head. So, I wanted this script to run at instance start, after the network was initialized. This wasn't as easy as I though! But I learned a bunch of new things about bash scripting - bonus!

Now, I have updated_route53.v2.sh in the /etc/init.d folder. It runs flawlessly, so far!

update_route53.sh - Initial code prior to having some issues with variables being set and used. I hard coded some of the variables in v2.0, with plans to convert them back in a future update.
update_route53.v2.sh - Place this on an Ubuntu EC2 instance to update the Route53 A DNS record with the net IP address

<img src="https://raw.githubusercontent.com/nealalan/update_route53/master/update_route53%202018-01-05%20at%2010.11.30%20PM.png">
