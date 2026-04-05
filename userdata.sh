#! /bin/bash
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh

chmod +x openvpn-install.sh

APPROVE_INSTALL=y ENDPOINT=$(curl ifconfig.me) APPROVE_IP=y IPV6_SUPPORT=n PORT_CHOICE=1 PROTOCOL_CHOICE=1 DNS=1 COMPRESSION_ENABLED=n  CUSTOMIZE_ENC=n CLIENT=openvpn PASS=1 ./openvpn-install.sh


# Wait for the .ovpn file in /root (max 60 seconds)
for i in {1..60}; do
  if [ -f "/root/openvpn.ovpn" ]; then
    echo "Found /root/openvpn.ovpn"
    break
  else
    echo "Waiting for /root/openvpn.ovpn..."
    sleep 1
  fi
done

# Move the file to ec2-user home and fix permissions
sudo mv /root/openvpn.ovpn /home/ec2-user/openvpn.ovpn
sudo chown ec2-user:ec2-user /home/ec2-user/openvpn.ovpn