#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi        
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root user"
    exit 1
else 
    echo "You are super user"
fi

dnf install python3.11 gcc python3-devel -y
VALIDATE $? "Installing Python"

id roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Adding Roboshop user"
else
    echo -e "roboshop user already exist ...$Y SKIPPING $N"
fi 

rm -rf /app &>> $LOGFILE
VALIDATE $? ""Clean up exisiting directory

mkdir -p /app &>> $LOGFILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip
VALIDATE $? "Downloading payment application"

cd /app 
VALIDATE $? "Moving to app directory"

unzip /tmp/payment.zip
VALIDATE $? "Extracting payment application"

pip3.11 install -r requirements.txt
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/roboshop-shell-script/payment.service /etc/systemd/system/payment.service
VALIDATE $? "Copying payment service"

systemctl daemon-reload
VALIDATE $? "Daemon reload"

systemctl enable payment 
VALIDATE $? "Enabling Payment"

systemctl start payment
VALIDATE $? "Starting Payment"