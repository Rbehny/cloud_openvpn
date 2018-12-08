# cloud_openvpn

Quick project to create a AWS VPN service. This is more cost effective for me than a commericial VPN solutions, ~$5 per month once outside of the free tier and year. Project uses OpenVPN, AWS (EC2, S3, CFT, SNS, IAM, ASG/LCs, and SGs). The CFT build is pretty basic building out a LC and ASG to provision a EC2 with packages for OpenVPN then pulling down PKI data from a private S3. The only novel item is not using an Elastic IP and using the random public IP AWS provides to the EC2 then sending that IP via SNS to the devices I use the VPN on. I manually populate the VPN program with the new IP on the days I use the service. 

Using it for working from public wifi locations. The ASG uses scheduled events to set desired instance count to 1 during business hours "M-F, 8-6" and to 0 instances the rest of the time. 

![Test Image 1](https://github.com/Rbehny/cloud_openvpn/blob/master/AWS_VPN.jpg)
