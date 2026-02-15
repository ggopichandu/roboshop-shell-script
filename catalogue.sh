#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MONGO_HOST='mangodb.gopichand.online'

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

dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "Disabling current nodejs"

dnf module enable nodejs:20 -y &>> $LOGFILE
VALIDATE $? "Enabling nodejs:20"

dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "Installing Nodejs"

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

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>> $LOGFILE
VALIDATE $? "Downloading Catalouge application"

cd /app &>> $LOGFILE
VALIDATE $? "Moving to app directory"

unzip /tmp/catalogue.zip &>> $LOGFILE
VALIDATE $? "Extracting Catalogue"

npm install &>> $LOGFILE
VALIDATE $? "Install dpendencies"

cp /home/ec2-user/roboshop-shell-script/catalogue.service /etc/systemd/system/catalogue.service &>> $LOGFILE
VALIDATE $? "Copied catalogue service"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon Reload"

systemctl enable catalogue &>> $LOGFILE
VALIDATE $? "Enable catalogue"

systemctl start catalogue &>> $LOGFILE
VALIDATE $? "Starting catalogue"

cp /home/ec2-user/roboshop-shell-script/mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOGFILE
VALIDATE $? "Copying mongo repo"

dnf install -y mongodb-mongosh &>> $LOGFILE
VALIDATE $? "Installing mongo client"

SCHEMA_EXISTS=$(mongosh --host $MONGO_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')") &>> $LOGFILE

if [ $SCHEMA_EXISTS -lt 0 ]
then 
    echo "Schema does not exits...LOADING"
    mongosh --host $MONGO_HOST </app/schema/catalogue.js &>> $LOGFILE
    VALIDATE $? "Loading catalogue data"
else
    echo -e "schema already exists...$Y SKIPPING $N"
fi        