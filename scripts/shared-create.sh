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

