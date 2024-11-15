#!/bin/bash
##### CREATE VPC #####

aws ec2 create-vpc --cidr-block 10.10.0.0/16

## Copy VpcId from output
## Update --vpc-id in the commands below:

aws ec2 create-subnet --vpc-id vpc-{{vpc_id}} --cidr-block 10.10.1.0/24

aws ec2 create-subnet --vpc-id vpc-{{vpc_id}} --cidr-block 10.10.2.0/24

## Create an Internet Gateway

aws ec2 create-internet-gateway

## Copy InternetGatewayId from the output
## Update the internet-gateway-id and vpc-id in the command below:

aws ec2 attach-internet-gateway --vpc-id vpc-{{vpc_id}} --internet-gateway-id igw-{{igw_id}}

## Create a custom route table

aws ec2 create-route-table --vpc-id vpc-{{vpc_id}}

## Copy RouteTableId from the output
## Update the route-table-id and gateway-id in the command below:

aws ec2 create-route --route-table-id rtb-{{rtb_id}} --destination-cidr-block 0.0.0.0/0 --gateway-id igw-{{igw_id}}

## Check route has been created and is active

aws ec2 describe-route-tables --route-table-id rtb-{{rtb_id}}

## Retrieve subnet IDs
## Update VPC ID in the command below:

aws ec2 describe-subnets --filters "Name=vpc-id,Values=vpc-{{vpc_id}}" --query 'Subnets[*].{ID:SubnetId,CIDR:CidrBlock}'

## Associate subnet with custom route table to make public
## Update subnet-id and route-table-id in the command below:

aws ec2 associate-route-table  --subnet-id subnet-{{subnet_id_1}} --route-table-id rtb-{{rtb_id}}

## Configure subnet to issue a public IP to EC2 instances
## Update subnet-id in the command below:

aws ec2 modify-subnet-attribute --subnet-id subnet-{{subnet_id_1}} --map-public-ip-on-launch


##### LAUNCH INSTANCE INTO SUBNET FOR TESTING #####

## Create a key pair and output to MyKeyPair.pem
## Modify output path accordingly

aws ec2 create-key-pair --key-name MyKeyPair --query 'KeyMaterial' --output text > ./MyKeyPair.pem

## Linux / Mac only - modify permissions

chmod 400 MyKeyPair.pem

## Create security group with rule to allow SSH

aws ec2 create-security-group --group-name SSHAccess --description "Security group for SSH access" --vpc-id vpc-{{vpc_id}}

## Copy security group ID from output
## Update group-id in the command below:

aws ec2 authorize-security-group-ingress --group-id sg-{{sg_id}} --protocol tcp --port 22 --cidr 0.0.0.0/0

## Launch instance in public subnet using security group and key pair created previously:
## Obtain the AMI ID from the console, update the security-group-ids and subnet-ids

aws ec2 run-instances --image-id ami-{{ami_id}} --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids sg-{{sg_id}} --subnet-id subnet-{{subnet_id_1}}

## Copy instance ID from output and use in the command below
## Check instance is in running state:

aws ec2 describe-instances --instance-id i-{{instance_id}}

## Note the public IP address
## Connect to instance using key pair and public IP

ssh -i MyKeyPair.pem ec2-user@54.253.97.225



##### CLEAN UP #####

## Run commands in the following order replacing all values as necessary

aws ec2 terminate-instances --instance-ids i-{{instance_id}}
aws ec2 delete-security-group --group-id sg-{{sg_id}}
aws ec2 delete-subnet --subnet-id subnet-{{subnet_id_2}}
aws ec2 delete-subnet --subnet-id subnet-{{subnet_id_1}}
aws ec2 delete-route-table --route-table-id rtb-{{rtb_id}}
aws ec2 detach-internet-gateway --internet-gateway-id igw-{{igw_id}} --vpc-id vpc-{{vpc_id}}
aws ec2 delete-internet-gateway --internet-gateway-id igw-{{igw_id}}
aws ec2 delete-vpc --vpc-id vpc-{{vpc_id}}
