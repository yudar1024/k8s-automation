#apt-get install -y wget
# INSTALL GO DEV ENV
wget https://studygolang.com/dl/golang/go1.15.6.linux-amd64.tar.gz
tar -xf go1.15.6.linux-amd64.tar.gz
mv go /usr/local
mkdir -p /goworkspace/src
touch /etc/profile.d/go-env.sh
cat >> /etc/profile.d/go-env.sh <<EOF
export GOROOT=/usr/local/go
export GOPATH=/goworkspace
export PATH=$GOROOT/bin/:$PATH
export GO111MODULE=on
GOPROXY=https://goproxy.io,direct
EOF
source /etc/profile

# INSTALL KUBEBUILDER
apt-get install -y conntrack make gcc
read -p "Do you want install kubebuilder ? 1 yes ,2 no :"  res
if [ "$res" = "" ];then
echo "go dev env installed"
exit 0
fi
if [ "$res" -eq 1 ]; then
os=$(go env GOOS)
arch=$(go env GOARCH)

# download kubebuilder and extract it to tmp
curl -L https://go.kubebuilder.io/dl/2.3.1/${os}/${arch} | tar -xz -C /tmp/

# move to a long-term location and put it on your path
# (you'll need to set the KUBEBUILDER_ASSETS env var if you put it somewhere else)
mv /tmp/kubebuilder_2.3.1_${os}_${arch} /usr/local/kubebuilder
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
mv kustomize /usr/local/kubebuilder/bin
export PATH=$PATH:/usr/local/kubebuilder/bin
fi
if [ "$res" -eq 2 ]; then
echo "go dev env installed"
exit 0
fi