#!/bin/bash
# dg - jun 19, 2014
# script to get current tx/rx of e4200 router

#which interface to poll
interface=2

username=${1-admin}
password=${2-changeme1}
router=${3-192.168.1.1}

if [ ! -e /tmp/check_bw_e4200.tmp ];then
  bandwidth1=`wget -O - -q "http://${username}:${password}@${router}/CBT_SystemOthers.asp"|sed 's/<script>document.write(special_char_trans("/\n/g'|grep 'RX bytes'|head -${interface}|tail -1|tr ':' ' '|awk '{print $3" "$8}'`
  if [ $? -eq 0 ];then
    echo "$bandwidth1" > /tmp/check_bw_e4200.tmp
    date +"%s" >> /tmp/check_bw_e4200.tmp
  fi
  exit
else
  bandwidth1=`cat /tmp/check_bw_e4200.tmp`
fi

if [ $? -ne 0 ];then
  echo "Failed to get net data!"
  exit 3
fi


bandwidth2=`wget -O - -q "http://${username}:${password}@${router}/CBT_SystemOthers.asp"|sed 's/<script>document.write(special_char_trans("/\n/g'|grep 'RX bytes'|head -${interface}|tail -1|tr ':' ' '|awk '{print $3" "$8}'`

if [ $? -ne 0 ];then
  echo "Failed to get net data!"
  exit 3
fi

#no bandwidth usage?
if [ "`echo \"$bandwidth1\"|head -1`" == "`echo \"$bandwidth2\"`" ];then
  recvbps=0
  sendbps=0
  
else
  
  olddate=`echo "${bandwidth1}"| tail -n1`
  newdate=`date +"%s"`
  secs=`echo "${newdate}-${olddate}"|bc`
  
  
  oldrecv=`echo "${bandwidth1}"|head -1|awk '{print $1}'`
  oldsend=`echo "${bandwidth1}"|head -1|awk '{print $2}'`
  
  newrecv=`echo "${bandwidth2}"|head -1|awk '{print $1}'`
  newsend=`echo "${bandwidth2}"|head -1|awk '{print $2}'`
  
  recvbps=`echo "((${newrecv}-${oldrecv})/${secs})/1024"|bc`
  sendbps=`echo "((${newsend}-${oldsend})/${secs})/1024"|bc`
  
fi

echo "Recv: ${recvbps}kB/sec Trans: ${sendbps}kB/sec|recvkbytes_s=${recvbps} transkbytes_s=${sendbps}"


#write new usage to temp file
echo "$bandwidth2" > /tmp/check_bw_e4200.tmp
date +"%s" >> /tmp/check_bw_e4200.tmp


exit 0
