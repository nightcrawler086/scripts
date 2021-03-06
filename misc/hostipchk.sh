#/bin/bash
#script to check to see if ip/hostname are not reserved
MDATE=`date '+%H:%M_%m%d%y'`
FILERS=/tmp
user=`who|awk '{print $1}'`
echo "Provide the CIFS/NFS server short name that the business would use: gtdvnasnfsp0036"
read srv
echo "
Choose domainname you wish to run query against "
echo "======================================"
echo "1: nam.nsroot.net "
echo "2: lac.nsroot.net"
echo "3: eur.nsroot.net"
echo "4: apac.nsroot.net"
echo "5: sti.lava"
echo "6: prod.lava"
echo "7: dmz.lava"
echo " Enter option from above COB tests requests you wish to process :"
read -e NUMBER
echo "Provide the PROD IP: IP1"
read prdip
echo "Provide the COB IP: IP2 "
read cbip
echo "Please wait script is processing ............."
rm -rf $FILERS/ipcheck_$MDATE
ncheck()
{
srvchk()
{
srv1=`echo $srv`
srv2=`echo $srv|sed 's/nas/naz/g'`
srv3=`echo $srv-dr`
srv4=`echo $srv-dr|sed 's/nas/naz/g'`
srv5=`echo $srv-pr`
srv6=`echo $srv-pr|sed 's/nas/naz/g'`
srv7=`echo $srv'_1'`
srv8=`echo $srv'_1'|sed 's/nas/naz/g'`
srv9=`echo $srv'_1'-dr`
srv10=`echo $srv'_1'-dr|sed 's/nas/naz/g'`
srv11=`echo $srv'_1'-pr`
srv12=`echo $srv'_1'-pr|sed 's/nas/naz/g'`
n=1
while [ $n -le 12 ]
do
for srv0 in  $srv1 $srv2 $srv3 $srv4 $srv5 $srv6 $srv7 $srv8 $srv9 $srv10 $srv11 $srv12
do
chk=`echo "CHECK $n"`
/usr/bin/nslookup $srv0 |grep Name: > /dev/null
         if [ $? -eq 0 ]
        then
                echo "$chk nslookup $srv0.................................................FAIL
                                                                     " >> $FILERS/ipcheck_$MDATE
        else
                echo "$chk nslookup $srv0 ................................................PASS
                                                                      " >> $FILERS/ipcheck_$MDATE
fi
  n=$(( $n + 1 ))
done
done
}
domchk()
{
if [ $NUMBER -eq 1 ]
then
dom=`echo "nam.nsroot.net"`
elif [ $NUMBER -eq 2 ]
then
dom=`echo "lac.nsroot.net"`
elif  [ $NUMBER -eq 3 ]
then
dom=`echo "eur.nsroot.net"`
elif  [ $NUMBER -eq 4 ]
then
dom=`echo "apac.nsroot.net"`
elif  [ $NUMBER -eq 5 ]
then
dom=`echo "sti.lava"`
elif [ $NUMBER -eq 6 ]
then
dom=`echo "prod.lava"`
elif [ $NUMBER -eq 7 ]
then
dom=`echo "dmz.lava"`
else
echo "Domain not found"
fi
#srv=`echo $srv.$dom`
srv1=`echo $srv.$dom`
srv2=`echo $srv.$dom|sed 's/nas/naz/g'`
srv3=`echo $srv-dr.$dom`
srv4=`echo $srv-dr.$dom|sed 's/nas/naz/g'`
srv5=`echo $srv-pr.$dom`
srv6=`echo $srv-pr.$dom|sed 's/nas/naz/g'`
srv7=`echo $srv'_1'.$dom`
srv8=`echo $srv'_1'.$dom|sed 's/nas/naz/g'`
srv9=`echo $srv'_1'-dr.$dom`
srv10=`echo $srv'_1'-dr.$dom|sed 's/nas/naz/g'`
srv11=`echo $srv'_1'-pr.$dom`
srv12=`echo $srv'_1'-pr.$dom|sed 's/nas/naz/g'`
srv13=`echo $prdip`
srv14=`echo $cbip`
n=13
while [ $n -le 26 ]
do
for srv0 in  $srv1 $srv2 $srv3 $srv4 $srv5 $srv6 $srv7 $srv8 $srv9 $srv10 $srv11 $srv12 $srv13 $srv14
do
chk=`echo "CHECK $n"`
/usr/bin/nslookup $srv0 |grep Name: > /dev/null
         if [ $? -eq 0 ]
        then
                echo "$chk nslookup $srv0  ..............FAIL
                                                                     " >> $FILERS/ipcheck_$MDATE
        else
                echo "$chk nslookup $srv0 ............PASS
                                                                      " >> $FILERS/ipcheck_$MDATE
fi
n=$(( $n + 1 ))
done
break
done
}
prdipchk()
{
n=27
while [ $n -le 27 ]
do
chk=`echo "CHECK $n"`
/bin/ping -c 1 $prdip > /dev/null
         if [ $? -eq 0 ]
        then
                echo "$chk ping $prdip .................................FAIL
                                                                     " >> $FILERS/ipcheck_$MDATE
        else
                echo "$chk ping $prdip .................................PASS
                                                                      " >> $FILERS/ipcheck_$MDATE
fi
break
done
}
cobipchk()
{
if [ -z $cbip ]
then
echo "=========================================="
echo "COB IP not valid NA/Not Applicable/blank"
echo "
               Skipping COB IP Check 26,28 ....."
echo "=========================================="
else
n=28
while [ $n -le 28 ]
do
chk=`echo "CHECK $n"`
/bin/ping -c 1 $cbip > /dev/null
         if [ $? -eq 0 ]
        then
                echo "$chk ping $cbip    ...................................FAIL
                                                                     " >> $FILERS/ipcheck_$MDATE
        else
                echo "$chk ping $cbip   ....................................PASS
                                                                      " >> $FILERS/ipcheck_$MDATE
fi
break
done
fi
}
srv_ping()
{
#srv=`echo $srv`
#srv=`echo $srv`
srv1=`echo $srv`
srv2=`echo $srv|sed 's/nas/naz/g'`
srv3=`echo $srv-dr`
srv4=`echo $srv-dr|sed 's/nas/naz/g'`
srv5=`echo $srv-pr`
srv6=`echo $srv-pr|sed 's/nas/naz/g'`
srv7=`echo $srv'_1'`
srv8=`echo $srv'_1'|sed 's/nas/naz/g'`
srv9=`echo $srv'_1'-dr`
srv10=`echo $srv'_1'-dr|sed 's/nas/naz/g'`
srv11=`echo $srv'_1'-pr`
srv12=`echo $srv'_1'-pr|sed 's/nas/naz/g'`
n=29
while [ $n -le 40 ]
do
for srv0 in  $srv1 $srv2 $srv3 $srv4 $srv5 $srv6 $srv7 $srv8 $srv9 $srv10 $srv11 $srv12
do
chk=`echo "CHECK $n"`
/bin/ping -c 1 $srv0 &>/dev/null
         if [ $? -eq 0 ]
        then
                echo "$chk ping $srv0 ...................FAIL
                                                                     " >> $FILERS/ipcheck_$MDATE
        else
                echo "$chk ping $srv0 ...................PASS
                                                                    " >> $FILERS/ipcheck_$MDATE
fi
n=$(( $n + 1 ))
done
break
done
}
srv_ping_full()
{
if [ $NUMBER -eq 1 ]
then
dom=`echo "nam.nsroot.net"`
elif [ $NUMBER -eq 2 ]
then
dom=`echo "lac.nsroot.net"`
elif  [ $NUMBER -eq 3 ]
then
dom=`echo "eur.nsroot.net"`
elif  [ $NUMBER -eq 4 ]
then
dom=`echo "apac.nsroot.net"`
elif  [ $NUMBER -eq 5 ]
then
dom=`echo "sti.lava"`
elif [ $NUMBER -eq 6 ]
then
dom=`echo "prod.lava"`
elif [ $NUMBER -eq 7 ]
then
dom=`echo "dmz.lava"`
else
echo "Domain not found"
fi
#srv=`echo $srv.$dom`
#srv=`echo $srv`
srv1=`echo $srv.$dom`
srv2=`echo $srv.$dom|sed 's/nas/naz/g'`
srv3=`echo $srv-dr.$dom`
srv4=`echo $srv-dr.$dom|sed 's/nas/naz/g'`
srv5=`echo $srv-pr.$dom`
srv6=`echo $srv-pr.$dom|sed 's/nas/naz/g'`
srv7=`echo $srv'_1'.$dom`
srv8=`echo $srv'_1'.$dom|sed 's/nas/naz/g'`
srv9=`echo $srv'_1'-dr.$dom`
srv10=`echo $srv'_1'-dr.$dom|sed 's/nas/naz/g'`
srv11=`echo $srv'_1'-pr.$dom`
srv12=`echo $srv'_1'-pr.$dom|sed 's/nas/naz/g'`
n=41
while [ $n -le 52 ]
do
for srv0 in  $srv1 $srv2 $srv3 $srv4 $srv5 $srv6 $srv7 $srv8 $srv9 $srv10 $srv11 $srv12
do
chk=`echo "CHECK $n"`
/bin/ping -c 1 $srv0 &>/dev/null
         if [ $? -eq 0 ]
        then
                echo "$chk ping $srv0 ...................FAIL
                                                                     " >> $FILERS/ipcheck_$MDATE
        else
                echo "$chk ping $srv0 ...................PASS
                                                                    " >> $FILERS/ipcheck_$MDATE
fi
n=$(( $n + 1 ))
done
break
done
}
srvchk
domchk
prdipchk
cobipchk
srv_ping
srv_ping_full
}
ncheck

echo "Please check output of file $FILERS/ipcheck_$MDATE ............."