# Use a base image
FROM ubuntu:latest

RUN UBUNTU_CODENAME=$(lsb_release -c | awk '{print $2}')
# RUN curl -s "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo tee -a /usr/share/keyrings/ansible-archive-keyring.gpg >/dev/null
# RUN sudo wget "https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=get&search=0x6125E2A8C77F2818FB7BD15B93C4A3FD7BB9C367" | sudo gpg --dearmour -o /usr/share/keyrings/ansible-archive-keyring.gpg
# RUN echo "deb [signed-by=/usr/share/keyrings/ansible-archive-keyring.gpg] http://ppa.launchpad.net/ansible/ansible/ubuntu $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/ansible.list
# RUN sudo apt update && sudo apt install ansible

RUN apt-get update && apt-get install -y software-properties-common
RUN add-apt-repository --yes --update ppa:ansible/ansible
RUN apt-get update && apt-get install -y ansible
