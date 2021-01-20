#!/usr/bin/env bash
# preset start
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v]  k8sversion golangversion [arg2...]

this script can only be used in centos or ubuntu

Available options:

-h, --help      Print this help and exit
-v, --verbose   Print script debug info
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  # tag=1.20.1
  # param=''

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    -v | --verbose) set -x ;;
    --no-color) NO_COLOR=1 
    # -t | --flag) flag=${1-} ;; # example flag
    # -p | --param) # example named parameter
      # param="${2-}"
      shift
      ;;
    -?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    shift
  done

  args=("$@")

  # check required params and arguments
  # [[ -z "${param-}" ]] && die "Missing required parameter: param"
  [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments please input golang version"

  return 0
}

parse_params "$@"
setup_colors

#preset end

#script logic here
#apt-get install -y wget
# INSTALL GO DEV ENV
if [ -f "/etc/ubuntu-release" ]; then 
apt install wget git conntrack make gcc
fi
if [ -f "/etc/centos-release" ]; then 
# yum gourp install "Development Tools"
yum install wget git conntrack make gcc
fi
wget "https://studygolang.com/dl/golang/go${args[0]}.linux-amd64.tar.gz"
tar -xf "go${args[0]}.linux-amd64.tar.gz"
mv go /usr/local
mkdir -p /goworkspace/src
echo "export GOROOT=/usr/local/go" >> /etc/profile
echo "export GOPATH=/goworkspace" >> /etc/profile
echo "export PATH=$GOROOT/bin/:$PATH" >> /etc/profile
echo "export GO111MODULE=on" >> /etc/profile
echo "export GOPROXY=https://goproxy.io,direct" >> /etc/profile
source /etc/profile

# INSTALL KUBEBUILDER
# apt-get install -y conntrack make gcc
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


# show msg
msg "${RED}Read parameters:${NOFORMAT}"
msg "- tag: ${tag}"
# msg "- param: ${param}"
msg "- arguments: ${args[*]-}"