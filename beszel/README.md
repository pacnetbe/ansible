# Usage
From /home/user/ansible/beszel/:
  > ansible-playbook -i ../inventory/hosts.ini deploy-beszel.yml
> ansible-playbook   -i ../inventory/hosts.ini   deploy-beszel.yml   --limit pserver04   --check   --diff   -vv
> 
or
> ansible-playbook\
>    -i ../inventory/hosts.ini\
>    deploy-beszel.yml\
>    --limit pserver04\
>    --check\
>    --diff\
>    -vv


beszel account:beszel@pacnet.be|skatteverket
