# Files-S3-Backup

Tool to do backup of directories and files on a server and send to S3 service the resulting TAR file.

## Prerequisites

* An IAM User or an AWS IAM Role attached to the EC2 instance (only for executions from EC2 instances) with the following IAM policy attached:

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

* Pip tool for Python packages management. Installation:

      $ curl -O https://bootstrap.pypa.io/get-pip.py
      $ sudo python get-pip.py

* AWS CLI to configure the profile to use (access key and/or region). Installation and configuration:

      $ sudo pip install awscli

      $ aws configure [--profile <profile-name>]
      AWS Access Key ID [None]: <access_key_id>         # Leave blank in EC2 instances with associated IAM Role
      AWS Secret Access Key [None]: <secret_access_key> # Leave blank in EC2 instances with associated IAM Role
      Default region name [None]: <region>              # eu-west-1, eu-central-1, us-east-1, ...
      Default output format [None]:

## Configuration

1. Download the project code in your favourite path:

       $ git clone https://github.com/rubenmromero/files-s3-backup.git

2. Create a copy of [fs3backup.conf.dist](conf/fs3backup.conf.dist) template named `conf/fs3backup.conf` and set the backup properties with the appropiate values:

       # From the project root folder
       $ cp conf/fs3backup.conf.dist conf/fs3backup.conf
       $ vi conf/fs3backup.conf

3. If you want to schedule the periodic tool execution, copy the [files-s3-backup](cron.d/files-s3-backup) template to the `/etc/cron.d` directory and replace the existing `<tags>` with the appropiate values:

       # From the project root folder
       $ sudo cp cron.d/files-s3-backup /etc/cron.d
       $ sudo vi cron.d/files-s3-backup

## Execution Method

Once configured the backup properties into `conf/fs3backup.conf` file, simply run `bin/fs3backup.sh` script as follows:

    # ./bin/fs3backup.sh

## Related Links

* [Installing the AWS CLI Using pip](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html#install-tool-pip)
* [Configuring the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
* [s3 - AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/reference/s3/)
