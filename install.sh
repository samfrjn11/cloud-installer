#!/bin/bash

# Exit when any command fails
set -e

# Get the scripts path: the path where this file is located.
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# -lt 1 ]; then
	echo "${PREFIX}Usage: $0 <path to install to>"
	echo "${PREFIX}Example: $0 ~/crownstone-cloud"
	exit 1
fi

# Make sure the install dir is an absolute path, so we can always cd to it.
INSTALL_DIR="$( realpath "$1" )"
echo "${PREFIX}Installing to: $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Make this and cloud dir unreadable by other users on the system.
chmod go-rwx "$THIS_DIR" "$INSTALL_DIR"

source "${THIS_DIR}/shared.sh"


install_mongo() {
	echo "${PREFIX}Installing MongoDB"
 	echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list
	sudo apt-get update
	sudo apt-get install libssl1.1
	sudo apt install -y gnupg
	wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -

	# Find out what the OS codename is
	CODENAME="$( lsb_release -a | grep Codename: | awk '{print $NF}' )"

	# Use Ubuntu 20 (focal) by default.
	if [ "$CODENNAME" == "" ]; then
		CODENAME="focal"
	fi

	echo "${PREFIX}Using packages for Ubuntu $CODENAME"
	echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu ${CODENAME}/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list

	sudo apt update
	sudo apt install -y mongodb-org

	# Optional: don't auto update:
	#echo "mongodb-org hold" | sudo dpkg --set-selections
	#echo "mongodb-org-server hold" | sudo dpkg --set-selections
	#echo "mongodb-org-shell hold" | sudo dpkg --set-selections
	#echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
	#echo "mongodb-org-tools hold" | sudo dpkg --set-selections

	echo "${PREFIX}Start MongoDB"
	# Ensure mongod config is picked up:
	sudo systemctl daemon-reload

	# Tell systemd to run mongod on reboot:
	sudo systemctl enable mongod

	# Start up mongod!
	sudo systemctl start mongod

	sudo rm /etc/apt/sources.list.d/focal-security.list

 	# Optionally: create an admin user (via mongo shell) and enable authorization (in mongo config file).
	echo "${PREFIX}Done installing MongoDB"
}


install_nvm() {
	echo "${PREFIX}Installing nvm"
 	sudo apt update
	sudo apt install -y curl
	curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.2/install.sh | bash
	echo "${PREFIX}Done installing nvm"
}


echo "${PREFIX}The cloud server uses MongoDB to store data."
echo "${PREFIX}If it's already installed, you can skip this step."
while :; do
	echo "${PREFIX}Install MongoDB (requires sudo)? [y/n]"
	read answer
	if [ "$answer" == "y" ]; then
		install_mongo
		break
	elif [ "$answer" == "n" ]; then
		break
	else
		echo "${PREFIX}Type \"y\" or \"n\" and then press enter."
	fi
done

# Insert MongoDB initial data.
if [ ! -f "${THIS_DIR}/${MONGO_DB_ARGS_FILE_NAME}" ]; then
	echo "${PREFIX}Using template MongoDB arguments file."
	cp "${THIS_DIR}/${MONGO_DB_ARGS_TEMPLATE_FILE_NAME}" "${THIS_DIR}/${MONGO_DB_ARGS_FILE_NAME}"
fi
if [ ! -f "${THIS_DIR}/${MONGODB_INIT_SCRIPT_FILE_NAME}" ]; then
	echo "${PREFIX}Using template MongoDB script to insert initial data."
	cp "${THIS_DIR}/${MONGODB_INIT_SCRIPT_TEMPLATE_FILE_NAME}" "${THIS_DIR}/${MONGODB_INIT_SCRIPT_FILE_NAME}"
fi
echo "${PREFIX}MongoDB script file: ${THIS_DIR}/${MONGODB_INIT_SCRIPT_FILE_NAME}"
echo "${PREFIX}Edit it to make sure all values are correct."
echo "${PREFIX}Is the MongoDB script correct? [y/N]"
read answer
if [ "$answer" != "y" ]; then
	echo "${PREFIX}Installation canceled."
	exit 1
fi
echo "${PREFIX}Running MongoDB script to insert initial data."
mongo $( head -n 1 "${THIS_DIR}/${MONGO_DB_ARGS_FILE_NAME}" ) "${THIS_DIR}/${MONGODB_INIT_SCRIPT_FILE_NAME}"
echo "${PREFIX}Done running MongoDB script to insert initial data."

echo "${PREFIX}Node Version Manager (nvm) is used to install different versions of Node.js and Node Package Manager (npm)."
echo "${PREFIX}If it's already installed, you can skip this step."
echo "${PREFIX}Install nvm? [Y/n]"
read answer
if [ "$answer" != "n" ]; then
	install_nvm
fi

# Generate tokens
SSE_TOKEN="$( openssl rand -hex 128 )"
AGGREGATION_TOKEN="$( openssl rand -hex 128 )"
SANITATION_TOKEN="$( openssl rand -hex 128 )"
SESSION_SECRET="$( openssl rand -hex 128 )"
CROWNSTONE_USER_ADMIN_KEY="$( openssl rand -hex 128 )"
DEBUG_TOKEN="nosecret"

# Make a copy of the template env vars, and fill in generated tokens.
# $1 = repo
install_env_vars() {
	cd "${THIS_DIR}/repos/${repo}"
	cp "template-environment-variables.sh" "environment-variables.sh"
	sed -i -re "s;CROWNSTONE_CLOUD_SSE_TOKEN=.*;CROWNSTONE_CLOUD_SSE_TOKEN=${SSE_TOKEN};g" "environment-variables.sh"
	sed -i -re "s;SSE_TOKEN=.*;SSE_TOKEN=${SSE_TOKEN};g" "environment-variables.sh"
	sed -i -re "s;AGGREGATION_TOKEN=.*;AGGREGATION_TOKEN=${AGGREGATION_TOKEN};g" "environment-variables.sh"
	sed -i -re "s;SANITATION_TOKEN=.*;SANITATION_TOKEN=${SANITATION_TOKEN};g" "environment-variables.sh"
	sed -i -re "s;SESSION_SECRET=.*;SESSION_SECRET=${SESSION_SECRET};g" "environment-variables.sh"
	sed -i -re "s;CROWNSTONE_USER_ADMIN_KEY=.*;CROWNSTONE_USER_ADMIN_KEY=${CROWNSTONE_USER_ADMIN_KEY};g" "environment-variables.sh"
	sed -i -re "s;DEBUG_TOKEN=.*;DEBUG_TOKEN=${DEBUG_TOKEN};g" "environment-variables.sh"
}

echo "${PREFIX}Installing dbus"
sudo apt install dbus-user-session

echo "${PREFIX}Installing repos"

installed_repos=""
for repo in $GIT_REPOS ; do
	# Optional repo to install
	if [ "$repo" == "crownstone-cloud-bridge" ]; then
		echo "${PREFIX}Install ${repo}? [Y/n]"
		read answer
		if [ "$answer" == "n" ]; then
			echo "${PREFIX}Skipping $repo"
			continue
		fi
	fi

	if [ -e "${INSTALL_DIR}/${repo}" ]; then
		echo "${PREFIX}${INSTALL_DIR}/${repo} already exists, overwrite? [y/N]"
		read answer
		if [ "$answer" != "y" ]; then
			echo "${PREFIX}Skipping $repo"
			continue
		fi
	fi

	clone_and_checkout "$repo"
	build "$repo"
	install_env_vars "$repo"

	if [ -f "${THIS_DIR}/repos/${repo}/run.sh" ]; then
		install_service "$repo"
		start "$repo"
	fi

	save_tag "$repo"

	if [ -f "${THIS_DIR}/repos/${repo}/cron.sh" ]; then
		timing="0 4 * * *"
		if [ -f "${THIS_DIR}/repos/${repo}/cron.txt" ]; then
			timing="$( cat "${THIS_DIR}/repos/${repo}/cron.txt" )"
		fi

		install_cron "${timing}" "${THIS_DIR}/repos/${repo}/cron.sh ${INSTALL_DIR}/${repo}"
	fi

	installed_repos="${installed_repos} $repo"
done

# Ensure the services don't get stopped on logout.
loginctl enable-linger $USER

echo "${PREFIX}Installing self update script"
install_cron "* * * * *" "${THIS_DIR}/crownstone-cloud-update.sh ${INSTALL_DIR} > ${THIS_DIR}/update.log 2>&1"

# Save installed tag
cd ${THIS_DIR}
get_latest_tag "self"
save_tag "self"

echo "${PREFIX}Install all done! Installed: $installed_repos"
