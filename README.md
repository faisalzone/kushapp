# Github CI/CD pipeline to AWS EC2 instance

## Setup Django application

- Django Application should be on an EC2 instance where AMI is a Django Stack powered by Bitnami (HVM). When launching an instance, choose the following from Community AMIs-
```
bitnami-djangostack-2.2.12-2-linux-ubuntu-16.04-x86_64-hvm-ebs-mp-4f79f671-99d9-4cfd-96a3-e9d2609dd04f-ami-0702ceac1ccbac2e3.4 - ami-017384b96c85dfb7b - 64-bit (x86)

This image may not be the latest version available and might include security vulnerabilities. Please check the latest, up-to-date, available version at https://bitnami.com/stacks.

Root device type: ebs | Virtualization type: hvm | ENA Enabled: Yes
```
- Create an [appspec.yml](appspec.yml) file where manage.py file exists.
- Create a [scripts](scripts) folder within the main app folder. This folder will have all the shell scripts supporting the [appspec.yml](appspec.yml) file.

## Preare EC2 instance for CodeDeploy

Access the AWS EC2 instance via SSH and run the following commands-

```
#!/bin/bash
sudo apt-get update
sudo apt-get install ruby
sudo apt-get install wget
cd /home/bitnami
wget https://aws-codedeploy-ap-southeast-2.s3.ap-southeast-2.amazonaws.com/latest/install
sudo chmod +x ./install
sudo ./install auto
sudo apt-get install python3.9
pip install --upgrade pip
pip3 install --upgrade pip
sudo -H pip install awscli
cd /opt/bitnami/apps/django
sudo chown -R bitnami /opt/bitnami/apps/django
sudo chmod -R g+w /opt/bitnami/apps/django
sudo /opt/bitnami/ctlscript.sh restart apache
sudo pip -H install pytz
sudo pip3 -H install pytz
sudo pip install --upgrade Django --install-option="--prefix=/opt/bitnami/apps/django"
sudo /opt/bitnami/ctlscript.sh restart apache
```

(Reference: [Install the CodeDeploy agent for Ubuntu Server - AWS CodeDeploy](https://docs.aws.amazon.com/codedeploy/latest/userguide/codedeploy-agent-operations-install-ubuntu.html))

To check if CodeDeploy is running-

```
service codedeploy-agent status
```

## Create IAM roles and policies



### EC2CodeDeploy (Role 1 of 2)

EC2CodeDeploy role is for AWS EC2.
- Go to IAM > Roles
- Ensure the "AWS service" is selected under heading 'Select type of trusted entity'
- Select "EC2" under heading 'Choose a use case'
- Click "Next: Permissions" button
- Attach the following policies to the role-
  - AmazonEC2RoleforAWSCodeDeploy
  - AmazonS3FullAccess
  - AWSCodeDeployRole
  - EC2CodeDeploy _(Add later)_
- Click "Next: Tags" button
- Add a tag
  - Tag 1
    - Name
    - EC2CodeDeploy
- Click "Next: Review" button
- Type "EC2CodeDeploy" as 'Role name'
- In 'Role description', type 'Allows EC2 instances to call AWS services on your behalf.'
- Click "Create role" button

EC2CodeDeploy is an Inline policy-

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```

Trust relationship policy-
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.ap-southeast-2.amazonaws.com",
          "codedeploy.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Tags (1)
- Tag 1
  - Tag key: Name
  - Tag value: EC2CodeDeploy

### CodeDeployRole (Role 2 of 2)

CodeDeployRole is for AWS CodeDeploy pipeline.
- Go to IAM > Roles
- Ensure the "AWS service" is selected under heading 'Select type of trusted entity'
- Select "CodeDeploy" under heading 'Or select a service to view its use cases'
- Select "CodeDeploy" under heading 'Select your use case'
- Click "Next: Permissions" button
- Attach the following policies to the role-
  - AWSCodeDeployRole
  - CodeDeploy _(Add later)_
- Click "Next: Tags" button
- Add a tag
  - Tag 1
    - Name
    - CodeDeployRole
- Click "Next: Review" button
- Type "CodeDeployRole" as 'Role name'
- In 'Role description', type 'Allows CodeDeploy to call AWS services such as Auto Scaling on your behalf.'
- Click "Create role" button

CodeDeploy is a Managed policy-

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "autoscaling:PutLifecycleHook",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:RecordLifecycleActionHeartbeat",
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DescribeAutoscalingGroups",
                "autoscaling:PutInstanceInStandby",
                "autoscaling:PutInstanceInService",
                "ec2:Describe*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
```

Trust relationship policy-
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.ap-southeast-2.amazonaws.com",
          "codedeploy.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## Attach IAM role to EC2 instance

Perform the following-
- Go to AWS EC2
- Click Instances on the left-side nav
- Select the instance
- Click 'Actions' button
- Click 'Instance Settings' option
- Click 'Attach/Replace IAM Role' option
- Select 'EC2CodeDeploy' from IAM role


## CodeDeploy

### Create an application

To create an application-
- Click Applications on the left-side nav
- Click 'Create application' button
- Enter the following to create application
  - Application configuration
    - Application name: kushapp
    - Compute platform: EC2/On-premises
- Click 'Create application' button

### Create a deployment group

To create a deployment group for the newly application-

- Click 'Deployment groups' tab
- Click 'Create deployment group' button
- Enter the following-
  - Deployment group name
    - Enter a deployment group name: kushapp_deploymentgroup
  - Service role
    - Enter a service role: arn:aws:iam::600163339681/CodeDeployRole
  - Deployment type
    - Choose how to deploy your application: In-place
  - Environment configuration
    - Select any combination of Amazon EC2 Auto Scaling groups, Amazon EC2 instances, and on-premises instances to add to this deployment: Amazon EC2 instances
    - Tag group 1
      - Key: Name
      - Value - optional: EC2_Deployment_Machines
  - Agent configuration with AWS Systems Manager
    - Install AWS CodePlay Agent: Now and schedule updates
    - Basic scheduler
    - 14 Days
  - Deployment settings
    - Deployment configuration: CodeDeployDefault.AllAtOnce
  - Load balancer
    - (untick) Enable load balancing
  - Triggers
    - (none)
  - Alarms
    - (none)
  - Rollbacks
    - (tick) Disable rollbacks
  - Deployment group tags
    - (none)
- Click "Create deployment group" button

## CodePipeline

Create a pipeline-
- Click 'Pipelines' on the left side nav
- Enter the following-
  - Step 1: Choose pipeline settings
    - Pipeline settings
      - Pipeline name: myapplication_pipeline
      - Service role: New service role
      - Role name: AWSCodePipelineServiceRole-ap-south-2-myapplication_pipeline
      - (tick) Allow AWS CodePipeline to create a service role so it can be used with this new pipeline
    - Advanced settings
      - Artifact store: Default location
      - Encryption key: Default AWS Managed Key
    - Click "Next" button
  - Step 2: Add source stage
    - Source
      - Source provider: Github (Version 2)
      - Connection: AWS Connector for Github *(arn:aws:codestar-connections:ap-southeast-2:600163339681:connection/33921b42-537b-418f-bd8f-6cd54481f3f6)*
      - Repository: faisalzone/kushapp
      - Branch: master
      - Output artifact format: CodePipeline default *(AWS CodePipeline uses the default zip format for artifacts in the pipeline. Does not include git metadata about the repository.)*
    - Click "Next" button
  - Step 3: Add build stage
    - Build - optional
      - Build provider: (none)
    - Click "Skip build stage" button
  - Step 4: Add deploy stage
    - Deploy
      - Deploy provider: AWS CodeDeploy
      - Region: Asia Pacific (Sydney)
      - Application name: kushapp
      - Deployment group: kushapp_deploymentgroup
    - Click "Next" button
  - Click "Create pipeline" button

The pipeline is now created and can be viewed by going to 'Pipelines' on the left side nav bar. And then click 'Pipeline' subcategory from nav bar.

## Troubleshooting

### Github

It's important that AWS Connector for GitHub exist at the right places in GitHub.

Go to Settings-
- Click "Applications" on the left side nav
  - Installed GitHub Apps (tab)
    - AWS Connector for Github
  - Authorized GitHub Apps (tab)
    - AWS Connector for GitHub
  - Authorized OAuth Apps
    - AWS CodePipeline (Sydney)

The 'AWS CodePipeline (Sydney)' in 'Authorized OAuth Apps' is not required as it relates to Github (Version 1) as source provider.

## Further Reading

[AWS CodeDeploy: Manage Deployment Complexity](https://www.youtube.com/watch?v=KzziRHOa5X4&ab_channel=AmazonWebServices) by [Ken Exner, Director, AWS Developer Tools](https://www.linkedin.com/in/ken-exner-b914542/)
