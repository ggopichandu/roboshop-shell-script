#!/bin/bash

instances=("mangodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "web")

for name in ${instances(@)}; do
if [ $name == "shipping" ] || [ $name == "mysql" ]
then
    instance_type="t3.medium"
else
    instance_type="t3.micro"
fi
echo "Creating instance for: $name with instance type: $instance_type"
instance_id=$(aws ec2 run-instances --image-id ami-0220d79f3f480ecf5 --instance-type $instance_type --security-group-ids sg-046836072ceb917dd --subnet-id subnet-0546bcf98efcaa4a4
--query "Instances[0].InstanceId" --output text)