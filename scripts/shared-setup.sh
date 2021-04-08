#!/bin/bash

#------------- shutdown idle notebooks ---------------#

set -e

# OVERVIEW
# This script stops a SageMaker notebook once it's idle for more than 1 hour (default time)
# You can change the idle time for stop using the environment variable below.
# If you want the notebook the stop only if no browsers are open, remove the --ignore-connections flag
#
# Note that this script will fail if either condition is not met
#   1. Ensure the Notebook Instance has internet connectivity to fetch the example config
#   2. Ensure the Notebook Instance execution role permissions to SageMaker:StopNotebookInstance to stop the notebook 
#       and SageMaker:DescribeNotebookInstance to describe the notebook.
#

# PARAMETERS
IDLE_TIME=3600

echo "Fetching the autostop script"
wget https://raw.githubusercontent.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/auto-stop-idle/autostop.py

echo "Starting the SageMaker autostop script in cron"

(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/bin/python $PWD/autostop.py --time $IDLE_TIME --ignore-connections") | crontab -

#------------ install zsh ------------------#

echo "Installing zsh..."
yum install zsh -y

echo "Downloading ohmyzsh..."
wget https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh

echo "Installing ohmyzsh as ec2-user..."
su -c "bash install.sh --unattended" ec2-user

echo "Cleaning up installation files..."
touch install.sh && rm install.sh

echo "Setting theme..."
echo "export ZSH_THEME=awesomepanda" >> /etc/profile.d/jupyter-env.sh

#------------ change shell -----------------#

echo "Adding shell config..."
echo "export SHELL=/bin/zsh" >> /etc/profile.d/jupyter-env.sh

#------------ change default theme -----------#

echo "Changing default theme..."
sed 's/"default": "JupyterLab Light"/"default": "JupyterLab Dark"/g' \
-i /home/ec2-user/anaconda3/share/jupyter/lab/schemas/\@jupyterlab/apputils-extension/themes.json

echo "Changing theme in user override settings..."
mkdir -p /home/ec2-user/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/
echo '{
    "theme": "JupyterLab Dark"
}' >> /home/ec2-user/.jupyter/lab/user-settings/@jupyterlab/apputils-extension/themes.jupyterlab-settings

#-------- restart server once all configuration complete ----------#

echo "Restarting sever..."
initctl restart jupyter-server --no-wait
