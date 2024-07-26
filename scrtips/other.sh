vim .profile
kunlun_env(){

#export KUNLUNBASE=/home/kunlun/klustron
#export KUNLUNVERSION=1.3.1

KUNLUNBASE=/home/kunlun/klustron
KUNLUNVERSION=1.3.1
if [[ -f $KUNLUNBASE/env.sh ]];then

        if  grep -q 'envtype="${envtype:-no}"' $KUNLUNBASE/env.sh;then
                sed -ri 's!\$\{envtype:-no\}!all!g'  $KUNLUNBASE/env.sh
        fi

fi

source $KUNLUNBASE/env.sh

}


kunlun_env



