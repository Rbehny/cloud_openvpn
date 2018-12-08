# cloud_openvpn

Quick project to create a AWS VPN service. Project uses OpenVPN, AWS (EC2, S3, CFT, SNS, IAM, ASG/LCs, and SGs). The CFT build is pretty basic building out a LC and ASG to provision a EC2 with packages for OpenVPN then pulling down PKI data from S3. The only novel item is not using an Elastic IP and using the random public IP AWS provides to the EC2 then sending that IP via SNS to the devices I use the VPN on.

