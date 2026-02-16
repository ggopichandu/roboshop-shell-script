#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

MYSQL_HOST="mysql.gopichand.online"

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

dnf install maven -y &>> $LOGFILE
VALIDATE $? "Installing Maven"


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


curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>> $LOGFILE
VALIDATE $? "Downloading shipping application"

cd /app &>> $LOGFILE
VALIDATE $? "Moving to app directory"

unzip /tmp/shipping.zip &>> $LOGFILE
VALIDATE $? "Extracting shipping application"

mvn clean package &>> $LOGFILE
VALIDATE $? "Packaging shiiping"

mv target/shipping-1.0.jar shipping.jar &>> $LOGFILE
VALIDATE $? "Renaming the artifact"

cp /home/ec2-user/roboshop-shell-script/shipping.service /etc/systemd/system/shipping.service &>> $LOGFILE
VALIDATE $? "Copying service file"

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable shipping &>> $LOGFILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>> $LOGFILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>> $LOGFILE
VALIDATE $? "Installing MYSQL"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e "use cities" &>> $LOGFILE
if [ $? -ne 0 ]
then 
    echo "Schema is...LOADING"
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOGFILE
    VALIDATE $? "Loading schema"
else
    echo -e "Schema already exits... $Y SKIPPING $N"  
fi