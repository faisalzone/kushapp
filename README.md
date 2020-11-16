# Github CI/CD to AWS EC2 Bitnami

Lizzy is a good mau 🦁

When creating the EC2 instance, enter the following in "Step 3: Configure Instance Details" in the 'User data' field 'As text'-

```
#!/bin/bash
sudo apt-get update
sudo apt-get install ruby
sudo apt-get install wget
cd /home/bitnami
wget https://aws-codedeploy-ap-southeast-2.s3.ap-southeast-2.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto
sudo pip install awscli
cd /opt/bitnami/apps/django
sudo chown -R bitnami /opt/bitnami/apps/django
sudo chmod -R g+w /opt/bitnami/apps/django
sudo /opt/bitnami/ctlscript.sh restart apache
sudo pip install pytz
sudo pip install --upgrade Django --install-option="--prefix=/opt/bitnami/apps/django"
sudo /opt/bitnami/ctlscript.sh restart apache
```

(reference: https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install-ubuntu.html)