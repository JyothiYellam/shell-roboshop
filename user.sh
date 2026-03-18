#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="/var/log/shell-script/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.jyothiy.online

if [ $USERID -ne 0 ]; then 
 echo -e "$R please run this script with root user access $N" | tee -a $LOGS_FILE
 exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
   if [ $1 -ne 0 ]; then
     echo -e "$2....$R failure $N" | tee -a $LOGS_FILE
     exit 1
   else
     echo -e "$2 ...$G success $N" | tee -a $LOGS_FILE
   fi

}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling Nodejs"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing Nodejs"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating System user"
else 
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating App"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading code"

cd /app 
VALIDATE $? "Moving to app dire4ctory"

rm -rf /app/*
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping code"

npm install &>>$LOGS_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Created systemctl service"

systemctl daemon-reload
systemctl enable user  &>>$LOGS_FILE
systemctl start user
VALIDATE $? "Starting and Enabling user"

















