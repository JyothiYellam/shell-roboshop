#!/bin/bash

cartID=$(id -u)
LOGS_FOLDER="/var/log/shell-script"
LOGS_FILE="/var/log/shell-script/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
B="\e[34m"
N="\e[0m"
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.jyothiy.online

if [ $cartID -ne 0 ]; then 
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
dnf install maven    -y &>>$LOGS_FILE
VALIDATE $? "Installing Maven"

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOGS_FILE
    VALIDATE $? "Creating System user"
else 
    echo -e "Roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating App"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOGS_FILE
VALIDATE $? "Downloading code"

cd /app 
VALIDATE $? "Moving to app dire4ctory"

rm -rf /app/* &>>$LOGS_FILE
VALIDATE $? "Removing existing code"

unzip /tmp/shipping.zip &>>$LOGS_FILE 
VALIDATE $? "Unzipping code"

cd /app
mvn clean package &>>$LOGS_FILE
VALIDATE $? "Installing Dependencies"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Moving and Renaming Shipping"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Created systemctl service"

dnf install mysql -y &>>$LOGS_FILE
VALIDATE $? "Installing Mysql"

mysql -h $MYSQL_HOST -uroot -pRoboshop@1 -e 'use cities'
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOGS_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOGS_FILE
else
    echo -e "data is already loaded ...$Y SKIPPING $N"
fi 

systemctl enable shipping 
systemctl start shipping
VALIDATE $? "Enable and Start Shipping"