# ansible

Playbooks to create:
- playbook to set system time to Europe/Brussels
- frigate config back-up
- install netdata
- deploy UptimeKuma backup/transfert

ansible directory structure:
- /home/user/ansible # ainsible home directory
- /home/user/ansible.cfg # ainsible configuration file
- /home/user/ansible/inventory # inventory directory
- /home/user/ansible/inventory/group_vars # 
- /home/user/ansible/inventory/host_vars # 
- /home/user/ansible/inventory/hosts.ini # list of hosts
- /home/user/ansible/<playbook directories>
- each playbook directory contains the yml playbook and directory structure needed for the playbook eg files, tasks, templates, vars and a symlink to /home/user/ansible.cfg
