#!/bin/bash

sync_time_zone() {
    if [ -z ${time_zone:=} ];then
        echo "env time_zone not set,use default time zone."
        #return 1
    else
        # timezone must be installed 
        # link the time zone file to /etc/lcoaltime
        sudo ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
        if [ $? -eq 0 ];then
            echo "time zone updated successfully."
        else
            echo "time zone update fail."
        fi
    fi
}

