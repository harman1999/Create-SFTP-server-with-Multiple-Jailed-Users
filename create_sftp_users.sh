#!/bin/bash

################################################################################################################
####           This script automatically creates SFTP Account and allow only access to Home Directory       ####
################################################################################################################

#################################### Check user name supplied or not ###########################################

echo "Please enter sftp username"
user=$(python3 -c "print(input())")
if [ -n "$user" ]; then
    newuser=$user
else
    echo "Please enter sftp username"
    exit 1
fi

#################################### Check if username already exist ############################################

if id "$newuser" >/dev/null 2>&1; then
         echo "Username Exists"
          echo "Use different username"
           exit
fi

#################################### Set  password for SFTP #####################################################

echo "Please enter sftp user $newuser passowrd otherwise script will generate random password automatically "
passwd=$(python3 -c "print(input())")
if [ -n "$passwd" ]; then
  randompw=$passwd
else  
  randompw=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)
fi

################################################# Create or SFTP Group ##############################################

echo "Please check sftp Group is 'sftp_users' if ok then press enter to continue or Press Ctrl+c exit the script and update the variable on line number '39' 'sftpgroup=sftp_users'"

sftpgroup=$(python3 -c "print(input())")

if [ -n "$sftpgroup" ]; then
  echo "please update the variable on line number '39' 'sftpgroup=sftp_users'"
else  
  sftpgroup=sftp_users
fi

################################################# Check sftpgroup exists ##########################################

if grep -ow $sftpgroup /etc/group;
then
  echo "group exists"
else
  addgroup $sftpgroup
fi

################################################# Set User HomePath ###############################################

echo "Please enter sftp $newuser full HomePath eg:'/home/username' otherwise HomePath is /home/$newuser"
home=$(python3 -c "print(input())")

if [ -n "$home" ]; then
  mkdir $home
  home_path=$(cd $home && pwd )
else
  home_path=/home/$newuser
fi

################################################# Add username and password #########################################

useradd $newuser
sudo usermod -G $sftpgroup $newuser
usermod -d $home_path $newuser
echo "$newuser:$randompw" | chpasswd

################################################# Set directory permission ########################################

echo "Please wait Applying Permission and setting Incoming Directory "
mkdir -p $home_path/sftp
chown root:$sftpgroup $home_path
sleep 4
chown $newuser:$newuser $home_path/sftp

############################################## Check or add config of SFTP #############################################

if cat /etc/ssh/sshd_config | tr -d ' ' | grep -ow "MatchGroup$sftpgroup";
then
  echo "exists"
else
 echo -e "Match Group $sftpgroup\n  ChrootDirectory %h\n  ForceCommand internal-sftp\n  AllowTCPForwarding no\n  X11Forwarding no\n  PasswordAuthentication yes" >> /etc/ssh/sshd_config
fi

############################################### Show Username and Password ####################################################

echo "User:$newuser"
echo "Pass:$randompw"
sleep 2

############################################## Restart Ssh Service #######################################################

service ssh restart

##########################################################################################################################
