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

curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash &>> $LOGFILE
VALIDATE $? "Erlang scripts installtion"

curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>> $LOGFILE
VALIDATE $? "Server scripts installation"

dnf install rabbitmq-server -y &>> $LOGFILE
VALIDATE $? "Installing Rabbitmq server"

systemctl enable rabbitmq-server &>> $LOGFILE
VALIDATE $? "Enabling Rabbitmq server"

systemctl start rabbitmq-server &>> $LOGFILE
VALIDATE $? "Starting Rabbitmq server"

rabbitmqctl add_user roboshop roboshop123 &>> $LOGFILE
VALIDATE $? "Adding user group"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOGFILE
VALIDATE $? "Setting permissions"