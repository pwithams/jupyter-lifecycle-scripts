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

# shutdown after 20mins idle time
IDLE_TIME=1200

echo "Fetching the autostop script"
wget https://raw.githubusercontent.com/aws-samples/amazon-sagemaker-notebook-instance-lifecycle-config-samples/master/scripts/auto-stop-idle/autostop.py

echo "Starting the SageMaker autostop script in cron"

#(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/bin/python $PWD/autostop.py --time $IDLE_TIME --ignore-connections") | crontab -

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

#-------- reset kernels -----#

mkdir /tmp/unused-kernels/ && ls /home/ec2-user/anaconda3/envs | grep -v JupyterSystemEnv | grep -v python3 | xargs -I {} mv /home/ec2-user/anaconda3/envs/{} /tmp/unused-kernels

#-------- copy persistant files to non persistent home directory -------#

mkdir -p /home/ec2-user/SageMaker/persistent-files
echo "Place files and directories here (like .zshrc, .ssh) to have them synced to ~/ on startup" > /home/ec2-user/SageMaker/persistent-files/README
echo "Run `bash ~/sync-files.sh` to sync them now" >> /home/ec2-user/SageMaker/persistent-files/README
echo "
# if using zsh, can use *(D) to include dotfiles in glob
shopt -s dotglob
cp -r /home/ec2-user/SageMaker/persistent-files/* /home/ec2-user
shopt -u dotglob
" > /home/ec2-user/sync-files.sh
chown -R ec2-user /home/ec2-user/SageMaker/persistent-files
chown ec2-user /home/ec2-user/sync-files.sh
bash /home/ec2-user/sync-files.sh
chmod +x /home/ec2-user/sync-files.sh

#-------- create command to sync specific files back to persistent-files -------#

touch /home/ec2-user/SageMaker/persistent-files.txt
chown ec2-user /home/ec2-user/SageMaker/persistent-files.txt
echo "
cat ~/SageMaker/persistent-files.txt | xargs -I {} cp -r ~/{} ~/SageMaker/persistent-files
" > /home/ec2-user/persist-files.sh
chown ec2-user /home/ec2-user/persist-files.sh
chmod +x /home/ec2-user/persist-files.sh


#--------- create /opt/ml/ directories for simulating containers --------#

mkdir -p /opt/ml/data/input
mkdir -p /opt/ml/data/output
mkdir -p /opt/ml/models

chown -R ec2-user /opt/ml

#-------- init conda as ec2-user -------#

su ec2-user -c "/home/ec2-user/anaconda3/bin/conda init zsh"

#-------- restart server once all configuration complete ----------#

echo "Restarting sever..."
initctl restart jupyter-server --no-wait
