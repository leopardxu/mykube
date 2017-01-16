#!/bin/bash

dir="./release_tars/"

RECHOST="localhost:5000"

if [ ! -d "${dir}" ]; then
    echo -e Folder "\033[31m${dir}\033[0m does not exist, please make sure your image tar exist under ${dir}"
    exit
fi
IMAGEMIN=1
num=1
for LINE in `ls ${dir}`
do
    extension="${LINE##*.}"
    if [ "$extension"x = "tar"x  ]; then
      echo -e Import "\033[37m$LINE  \033[0m... ($num/34)"

      rm -rf ${dir}repositories
      tar -x -C ${dir} -f ${dir}${LINE}  repositories  >/dev/null 2>&1

      MSG=`cat ${dir}repositories`
      MSG1=${MSG%:*}
      NAC=${MSG1%:*}

      NAL=${NAC:2}
      NAF=${NAL%\"*}

      TAGR=${MSG1%\"*}
      TAGF=${TAGR##*\"}

      URL=${NAF%%/*}
      IMNA=${NAF#*/}

      INDEX=0

      while [ $INDEX -lt 5 ]
      do

          docker load -i ${dir}$LINE >> pushSuiteImages.log  >/dev/null 2>&1

          docker rmi $RECHOST/$IMNA:$TAGF >> pushSuiteImages.log  >/dev/null 2>&1

          docker tag $URL/$IMNA:$TAGF $RECHOST/$IMNA:$TAGF >> pushSuiteImages.log  >/dev/null 2>&1

          docker push $RECHOST/$IMNA:$TAGF >> pushSuiteImages.log  >/dev/null 2>&1
          if [ $? -eq 0 ]; then
              echo -e Import $LINE "\033[32m complete \033[0m"
              echo -e Import $LINE "\033[32m complete \033[0m"  >> pushSuiteImages.log
              break;
          else
              echo "$LINE failed, retry in 2 seconds ..." >> pushSuiteImages.log
              INDEX=`expr $INDEX + 1`
              sleep 2
          fi
      done
      IMAGEMIN=`expr $IMAGEMIN + 1`
      if [ $INDEX -ge 5 ]  ; then
        echo ${dir}$LINE push "\033[31m failed \033[0m"
        array[$IMAGEMIN]=$LINE
      else
        array1[$IMAGEMIN]=$LINE
      fi

    fi
  num=`expr $num + 1`
done

echo -e "\033[32m Success tars: \033[0m"
for succimg in ${array1[@]}
do
  echo -e "\033[32m ${succimg} \033[0m"
done
echo

echo -e "\033[31m Failed tars: \033[0m"
if [ ${#array[@]} -eq 0 ]; then
    echo -e "\033[32m No Error \033[0m"
else
  for failimg in ${array[@]}
  do
    echo -e "\033[31m ${failimg} \033[0m"
  done
fi
