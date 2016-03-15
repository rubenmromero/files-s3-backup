# Files to S3 - Backup

Script to do backup of directories and files of a server and send to S3 service the resulting TAR file.

## Prerequisites

* AWS IAM EC2 Role (only for executions from EC2 instances) or IAM User with the following associated IAM policy:

        Policy Name : AmazonS3FullAccess

        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": "s3:*",
              "Resource": "*"
            }
          ]
        }

* AWS CLI for ec2 commands. Installation and configuration:

        $ sudo pip install awscli

        $ aws configure
        AWS Access Key ID [None]: <access_key>		# Leave blank in EC2 instances with associated IAM Role
        AWS Secret Access Key [None]: <secret_key>	# Leave blank in EC2 instances with associated IAM Role
        Default region name [None]: eu-west-1
        Default output format [None]:

## Configuration

1. Download the project code in your favourite path:

        $ git clone https://github.com/rubenmromero/files_to_S3-backup.git

2. Create a copy of [files_to_S3.conf.dist](conf/files_to_S3.conf.dist) template named conf/files_to_S3.conf and ...
