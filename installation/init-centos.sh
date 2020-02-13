if [ `whoami` != 'root' ]
then
    echo 'you must run this script as root'
    exit 0
fi
yum install -y epel-release

version =`cat /etc/centos-release | awk '{print $4}' | cut -d . -f1`
if [[ version ==  8 ]]; then

    cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
    cp /etc/yum.repos.d/CentOS-AppStream.repo /etc/yum.repos.d/CentOS-AppStream.repo.bak
    cp /etc/yum.repos.d/CentOS-Extras.repo /etc/yum.repos.d/CentOS-Extras.repo.bak


    sed -i 's/mirrorlist=/#mirrorlist=/g' /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-AppStream.repo /etc/yum.repos.d/CentOS-Extras.repo
    sed -i 's/#baseurl=/baseurl=/g' /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-AppStream.repo /etc/yum.repos.d/CentOS-Extras.repo
    sed -i 's/http:\/\/mirror.centos.org/https:\/\/mirrors.aliyun.com/g' /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-AppStream.repo /etc/yum.repos.d/CentOS-Extras.repo


    cp /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.bak
    cp /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.bak
    cp /etc/yum.repos.d/epel-playground.repo /etc/yum.repos.d/epel-playground.repo.bak

    sed -i 's/metalink=/#metalink=/g' /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-playground.repo
    sed -i 's/#baseurl=/baseurl=/g' /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-playground.repo
    sed -i 's/https:\/\/download.fedoraproject.org\/pub/https:\/\/mirrors.aliyun.com/g' /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-playground.repo

fi
if [[ version == 7 ]]; then
    mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
    mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.backup
    mv /etc/yum.repos.d/epel-testing.repo /etc/yum.repos.d/epel-testing.repo.backup
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
fi


yum install -y  vim zsh git lrzsz wget

systemctl stop firewalld
systemctl disable firewalld

# 关闭selinux
setenforce 0
# 永久关闭
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/sysconfig/selinux
sed -i "s/^SELINUX=permissive/SELINUX=disabled/g" /etc/selinux/config

mkdir ~/.pip
touch ~/.pip/pip.conf
cat > ~/.pip/pip.conf <<-EOF
[global]
index-url = http://mirrors.aliyun.com/pypi/simple/

[install]
trusted-host=mirrors.aliyun.com
EOF
read -p "请输入hostname 名称 :" host
hostnamectl --static set-hostname $host

# install oh my zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cat > ~/.oh-my-zsh/themes/myrobbyrussell.zsh-theme <<-EOF

PROMPT='%{$fg_bold[red]%}-> %{$fg_bold[magenta]%}%n%{$fg_bold[cyan]%}@%{$fg[green]%}%m %{$fg_bold[green]%}%p%{$fg[cyan]%}%~ %{$fg_bold[blue]%}\$(git_prompt_info)%{$fg_bold[blue]%}% %{$fg[magenta]%}%(?..%?%1v)%{$fg_bold[blue]%}? %{$fg[yellow]%}# '


ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg_bold[blue]%}git:(%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%} "
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[blue]%}) %{$fg[yellow]%}✗"
ZSH_THEME_GIT_PROMPT_CLEAN="%{$fg[blue]%})"
EOF
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="myrobbyrussell"/g' ~/.zshrc
# chsh -s /usr/bin/zsh 更换使用的shell 程序为zsh
