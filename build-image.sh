#!/bin/bash


usage() {
	echo "build-image.sh [options]"
	echo
	echo "Options and equivalent environment variables:"
	echo "  -pp or --pam-public <path>            VISA_PAM_PUBLIC_KEY      set the PAM module public key location"
	echo "  -rp or --root-password <password>     VISA_ROOT_PASSWORD       set the root password for the VM"
	echo "  -hp or --http-proxy <URL>             VISA_HTTP_PROXY          set the HTTP proxy URL"
	echo "  -np or --no-proxy <no proxy hosts>    VISA_NO_PROXY_HOSTS      set the HTTP no proxy hosts"
	echo "  -nh or --notheadless                                           set build process not to be headless"
}

export headless=true
PACKER_HTTP_PROXY="\"\""
PACKER_NO_PROXY_HOSTS="localhost"

# Parse command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-rp|--root-psasword)
	VISA_ROOT_PASSWORD="$2"
	shift
	shift
	;;

	-pp|--pam-public)
	VISA_PAM_PUBLIC_KEY="$2"
	shift
	shift
	;;

	-hp|--http-proxy)
	VISA_HTTP_PROXY="$2"
	PACKER_HTTP_PROXY="$2"
	shift
	shift
	;;

	-np|--no-proxy)
	VISA_NO_PROXY_HOSTS="$2"
	PACKER_NO_PROXY_HOSTS="$2"
	shift
	shift
	;;

	-nh|--not-headless)
 	headless=false
	shift
	;;

	*)
	break
	;;
esac
done

# Verify PAM public/private keys parameters
if [ -z "$VISA_ROOT_PASSWORD" ]; then
	echo "You need to specify a root password for the VM"
	usage
	exit
fi

# Verify root password is set
if [ ! -z "$VISA_PAM_PUBLIC_KEY" ]; then
	if [[ ! -z "$VISA_PAM_PUBLIC_KEY" && ! -f "$VISA_PAM_PUBLIC_KEY" ]]; then
		echo "VISA PAM public key not found at $VISA_PAM_PUBLIC_KEY"
		exit
	fi
else
	echo "You need to specify the VISA PAM public key location"
	usage
	exit
fi

# Set the packer environment variables
export root_password=$VISA_ROOT_PASSWORD

# Modify the files accordingly for the proxy
sed -e "s|{http_proxy}|$PACKER_HTTP_PROXY|g" -e "s|{no_proxy}|$PACKER_NO_PROXY_HOSTS|g"  templates/system-base/environment.yml.tlt > templates/system-base/environment.yml

if [ ! -z "$VISA_HTTP_PROXY" ]; then
	sed -e "s|{http_proxy}|$VISA_HTTP_PROXY|g" -e "s|{https_proxy}|$VISA_HTTP_PROXY|g" -e "s|{no_proxy}|$VISA_NO_PROXY_HOSTS|g"  templates/system-base/system/etc/environment.tlt > templates/system-base/system/etc/environment
else
	echo "" > templates/system-base/system/etc/environment
fi

# Copy PAM file
echo "Copying PAM module public key from $VISA_PAM_PUBLIC_KEY"
cp "$VISA_PAM_PUBLIC_KEY" templates/visa-base/system/etc/visa/public.pem


VENV_DIR=.venv_packme
rm -rf $VENV_DIR
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate

echo "Installing packme"
pip3 install wheel
pip3 install packme

export PACKER_LOG=1
# Run packme
packme --templates-base-dir templates --debug -l --input config.yml -c -r

deactivate
rm -rf $VENV_DIR
