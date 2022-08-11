//https://www.youtube.com/watch?v=7xngnjfIlK4&t=4783s
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}


resource "aws_security_group" "instances" {
  name = "instance-security-group"
}

resource "aws_security_group_rule" "allow_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instances.id

  from_port   = 0
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}


resource "aws_instance" "web" {
  ami           = "ami-011899242bb902164" # Ubuntu 20.04 LTS // us-east-1
  instance_type = "t3.micro"
    security_groups = [aws_security_group.instances.name]
  user_data       = <<-EOF
            #!/bin/bash -xe
            amazon-linux-extras install epel -y
            yum update -y
            yum install openvpn -y
            #remove easy-rsa after server built
            yum install easy-rsa -y
            #one time manual server setup for CA, certs, keys, crl
            #/usr/share/easy-rsa/3/easyrsa init-pki
            #/usr/share/easy-rsa/3/easyrsa build-ca nopass
            #/usr/share/easy-rsa/3/easyrsa build-server-full vpn-server nopass
            #/usr/share/easy-rsa/3/easyrsa build-client-full vpn-client-01 nopass
            #/usr/share/easy-rsa/3/easyrsa gen-crl
            #/usr/share/easy-rsa/3/easyrsa gen-dh
            #echo "" > /home/ec2-user/pki/ta.key
            #openvpn --genkey --secret /home/ec2-user/pki/ta.key
            #copy files to openvpn location
            #cp /home/ec2-user/pki/ca.crt /etc/openvpn/ca.crt
            #cp /home/ec2-user/pki/dh.pem /etc/openvpn/dh.pem
            #cp /home/ec2-user/pki/issued/vpn-server.crt /etc/openvpn/vpn-server.crt
            #cp /home/ec2-user/pki/private/vpn-server.key /etc/openvpn/vpn-server.key
            #cp /home/ec2-user/pki/ta.key /etc/openvpn/ta.key
            #cp /home/ec2-user/pki/crl.pem /etc/openvpn/crl.pem
            #copy files up to S3
            #will need to update the local copies with the below s3 for each iteration
            #aws s3 cp /home/ec2-user/pki/ca.crt s3://vpnconfigs-robertbehny/ca.crt
            #aws s3 cp /home/ec2-user/pki/dh.pem s3://vpnconfigs-robertbehny/dh.pem
            #aws s3 cp /home/ec2-user/pki/issued/vpn-server.crt s3://vpnconfigs-robertbehny/vpn-server.crt
            #aws s3 cp /home/ec2-user/pki/private/vpn-server.key s3://vpnconfigs-robertbehny/vpn-server.key
            #aws s3 cp /home/ec2-user/pki/ta.key s3://vpnconfigs-robertbehny/ta.key
            #aws s3 cp /home/ec2-user/pki/crl.pem s3://vpnconfigs-robertbehny/crl.pem
            #aws s3 cp /home/ec2-user/pki/private/vpn-client-01.key s3://vpnconfigs-robertbehny/vpn-client-01.key
            #aws s3 cp /home/ec2-user/pki/issued/vpn-client-01.crt s3://vpnconfigs-robertbehny/vpn-client-01.crt
            #end one time setup
            aws s3 cp s3://vpnconfigs-robertbehny/ca.crt /etc/openvpn/ca.crt
            aws s3 cp s3://vpnconfigs-robertbehny/dh.pem /etc/openvpn/dh.pem
            aws s3 cp s3://vpnconfigs-robertbehny/vpn-server.crt /etc/openvpn/vpn-server.crt
            aws s3 cp s3://vpnconfigs-robertbehny/vpn-server.key /etc/openvpn/vpn-server.key
            aws s3 cp s3://vpnconfigs-robertbehny/ta.key /etc/openvpn/ta.key
            aws s3 cp s3://vpnconfigs-robertbehny/crl.pem /etc/openvpn/crl.pem
            aws s3 cp s3://vpnconfigs-robertbehny/vpn-client-01.key /etc/openvpn/vpn-client-01.key
            aws s3 cp s3://vpnconfigs-robertbehny/vpn-client-01.crt /etc/openvpn/vpn-client-01.crt
            aws s3 cp s3://vpnconfigs-robertbehny/server.conf /etc/openvpn/server.conf
            aws s3 cp s3://vpnconfigs-robertbehny/iptable_script /var/lib/cloud/scripts/per-boot/iptable_script
            #enable ipv4 forwarding (needs every time); runs out of the above /per-boot folder
            iptables -F FORWARD
            iptables -F INPUT
            iptables -F OUTPUT
            iptables -X
            modprobe iptable_nat
            iptables -t nat -A POSTROUTING -s 10.4.0.1/2 -o eth0 -j MASQUERADE
            iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
            echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
            #systemctl start openvpn@server.service
            systemctl -f enable openvpn@server.service
            systemctl start openvpn@server.service
            curl http://169.254.169.254/latest/meta-data/public-ipv4 > msg.temp
            aws sns publish --topic-arn arn:aws:sns:us-east-1:080000927841:vpn_public_ip --region us-east-1 --message file://msg.temp
            rm msg.temp
            #figure out how to combine ec2 ip address and a string then echo into the above files
            #curl http://169.254.169.254/latest/meta-data/public-ipv4 > ip.temp
            #downloads the public ip and saves into ip.temp
            #echo "--message " > msgspace.temp
            #writes server with a space to temp file
            #tr -d '\n' < msgspace.temp > msg.temp
            #removes new line instruction at the end of the server file
            #cat msg.temp ip.temp > serverandip.temp
            #combines the word "server " with a space and the public ip address
            #need to combine the above file and the subnet then add to the server.conf
            #diagnostic: head -n 1 new.temp | od -c Command to see what instruction is in the echo file.
            #setup iptables (setup the iptables script) then remove comments below
            #http://www.startupcto.com/server-tech/centos/setting-up-openvpn-server-on-centos
            #systemctl enable iptables
            #systemctl start iptables
            #service iptables save
              EOF
  tags = {
    Name = "HelloWorld"
  }
}

