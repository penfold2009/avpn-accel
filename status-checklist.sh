#!/usr/bin/webif-page
## elmailshite
<?
. /usr/lib/webif/webif.sh 
. /lib/vibe/webfuncs.sh

header "Acceleration" "Check Status" "@TR<<Configuration Status. >>" '' "$SCRIPT_NAME"

calc_month_number (){

 case $1 in
  "Jan") echo "1"
  ;;
  "Feb") echo "2"
  ;;
  "Mar") echo "3"
  ;;
  "Apr") echo "4"
  ;;
  "May") echo "5"
  ;;
  "Jun") echo "6"
  ;;
  "Jul") echo "7"
  ;;
  "Aug") echo "8"
  ;;
  "Sep") echo "9"
  ;;
  "Oct") echo "10"
  ;;
  "Nov") echo "11"
  ;;
  "Dec") echo "12"
  ;;
 esac
}


#####################################


if [ "$WEBIF_PERMS" == "rw"  ] ##  If user has permisssion do stuff. ##
  
  then
    

  cat << EOF
  <style>
  td {
    border: 1px solid black
  }

  </style>
  <div class = settings>
      <div class = settings-content>
      <br>
         <h3><strong>Internet Access Check List.</strong></h3>
      <br>
      <table id="configtable" style="width:90%">
      <tbody>
EOF
##

  ## check default gw ## 
    if route -n | grep -r '^0\.0\.0\.0' >& /dev/null ; then
    
      for ip in $(route -n | awk '/^0\.0\.0.0/ && !/vibe/{print $2}'); do

         if ping -c 1 -w 1 $ip  >& /dev/null; then

          echo "<tr><td bgcolor = 'lightgreen'>Default gateway $ip ok.</td></tr>"

         else echo "<tr><td bgcolor = 'tomato'>Failed to ping defaut gateway $ip </td></tr>"
         error_string="There is no connection to your default gateway<br>Check that the IP is correct."

        fi
      done

    else echo "<tr><td bgcolor = 'tomato'>Warning: No default route set"
        error_string="A default gateway has not been configured<br>Check the network settings in Network->Networks"

    fi  # end of check default gw ## 

    ## check dns . file exists and it not zero in size
    ## http://pubs.opengroup.org/onlinepubs/9699919799/utilities/test.html ##

    if [ -e  /etc/config/network -a -s  /etc/config/network ]; then

            for i in $(awk -vq="'" '/option dns/{gsub("option dns","");gsub(q,"");print}'  /etc/config/network )
               do 
                  if ping -c 1 -w 1 $i >& /dev/null ; then
                    
                    if  nslookup www.bbc.co.uk $i >& /dev/null ; then
                        ##echo "<tr><td bgcolor = 'lightgreen'>URLs resolve Ok.</td></tr>"
                        echo "<tr><td bgcolor = 'lightgreen'>DNS using $i resolves Ok.</td></tr>"
                    else 
                        echo "<tr><td bgcolor = '#ff9933'>Warning: Can't resolve URLs using DNS $i</td></tr>"
                        error_string=$error_string"<br>The DNS has been set to $i but it is not resolving URLs<br>"
                    fi

                  else echo "<tr><td bgcolor = '#ff9933'>Warning: Ping to DNS $i failed</td></tr>"
                        error_string=$error_string"<br>A DNS has been set as $i but it cannot be contacted.<br>Check this IP is correct.<br> \
                        Go to Network->Networks"

                  fi ## end of ping
               done

          else echo "<tr><td bgcolor = 'tomato'>DNS not set</td></tr>"


    fi  #end of -e -a -s

  echo "</tbody></table><br><br>"


 ## Check license ###


 cat << EOF 
           <h3><strong>AVPN Configuration Check List.</strong></h3>
           <table id="vibe" style="width:90%">
           <tbody>
EOF

  if [ -e /etc/vibe.lic ] ; then 
   
      if [ -e "/tmp/vibe.err" ]
           then
                    VIBE_ERR=`cat /tmp/vibe.err | awk '{ print $1 }'`
                    case $VIBE_ERR in
                    1)      echo "<tr><td bgcolor = 'tomato'>License Error.</td></tr>"
                            ping -c 3 -W 1  78.129.231.117 >& /dev/null  || echo "<tr><td bgcolor = '#ff9933'>Warning: Ping to validation server 78.129.231.117 Failed</td></tr>"
                            ping -c 3 -W 1  37.59.189.176 >& /dev/null   || echo "<tr><td bgcolor = '#ff9933'>Warning: Ping to validation server 37.59.189.176 Failed</td></tr>"

                            ;;
                    2)      echo "<tr><td bgcolor = 'tomato'>Configuration File Missing</td></tr>"
                            ;;
                    3)      echo "<tr><td bgcolor = 'tomato'>Configuration File Parse Error</td></tr>"
                            ;;
                    *)      echo "<tr><td bgcolor = 'tomato'>Unknown Error</td></tr>"
                            ;;
                    esac
      
      fi ## end of if vibe.err


      ### Check if the license has expired ###

      if vibe-stat l | grep 'License Expires' > /dev/null; then
        echo "<tr><td bgcolor = 'lightgreen' >License Key is valid</td></tr>"

        license_string=$(vibe-stat -l | awk '/License Expires/{$1=""; $2=""; $3=""; print}')

        lic_month=$(calc_month_number $(echo $license_string |awk '{print $1}'))
         lic_date=$(echo $license_string |awk '{print $2}')
         lic_year=$(echo $license_string |awk '{print $4}')
         lic_hour=$(echo $license_string |awk '{print $3}'| awk -vFS=":" '{print $1}')
          lic_min=$(echo $license_string |awk '{print $3}'| awk -vFS=":" '{print $2}')

      current_time=$(date +"%b %d %T %Y")
        host_month=$(date +"%m")
         host_date=$(date +"%d")
         host_year=$(date +"%Y")
         host_hour=$(date +"%H")
          host_min=$(date +"%M")


        ## If host and license years are equal check months if they're equal check date, then hours and mins
        if  [ $host_year -lt $lic_year ] ; then               status="in date"
        elif [ $host_year -gt $lic_year ]; then               status="Expired"
        else if [ $host_month -lt $lic_month ] ; then         status="in date"
             elif [ $host_month -gt $lic_month ]; then        status="Expired"
             else if [ $host_date -lt $lic_date ] ; then      status="in date"
                elif [ $host_date -gt $lic_date ] ; then      status="Expired" 
                else if [ $host_hour -lt $lic_hour ]; then    status="in date"
                     elif [ $host_hour -gt $lic_hour ]; then  status="Expired"
                     else if [ $host_min -lt host_min ]; then status="in date"
                            else status="Expired"
                            fi # end of check min
                     fi #end of check hour
                fi # end of check date
             fi ## end of check month
        fi ## end of check year


        if [ "$status" == "in date" ]; then
          echo "<tr><td bgcolor = 'lightgreen' >License in date</td></tr>"

        else echo "<tr><td bgcolor = 'tomato' >License Expired</td></tr>"
             echo "<tr><td bgcolor = 'tomato' >Current Time: $current_time</td></tr>"
             echo "<tr><td bgcolor = 'tomato' >License Time: $license_string</td></tr>"
        fi  

        #### Check can ping valuation server.  #####
        #Validation IP 78.129.231.117
        #Validation IP 37.59.189.176
       

      fi ## end of vibe-stat l | grep 'License Expires'



  else echo "<tr><td bgcolor = 'tomato'>No license key</td></tr>"
    
  fi ##  end of if -e vibe.lic


## Check is Vibe is running or not. test taken from avpn-status.sh
[ -e "/var/run/vibe.on" ] && echo "<tr><td bgcolor = 'lightgreen' >AVPN service is running</td></tr>" || echo "<tr><td bgcolor = 'tomato'>AVPN service is not running</td></tr>"


  ## check ping too server
   if [ -d /etc/vibe.conf.d ] 
     then
      grep -hE '^[[:space:]]*provision_server' /etc/vibe.conf.d/* /etc/vibe.conf | awk '{print $3}' > /tmp/provision_ip.txt

   else

      if  [ -e /etc/vibe.conf ]; then
         grep -hE '^[[:space:]]*provision_server' /etc/vibe.conf | awk '{print $3}' > /tmp/provision_ip.txt
      else echo "<tr><td bgcolor='#ff9933' >Warning /etc/vibe.conf does not exist</td></tr>"
      fi  
   fi

   if [ -s /tmp/provision_ip.txt ] ; then
       while  read provision_ip ; do

         route -n | egrep -i "^${provision_ip}" > /dev/null || echo "<tr><td bgcolor = '#ff9933' >Warning no static route for Server IP $provision_ip</td></tr>"

         #result=$(ping -q -c 50 -i 0.02 -w 3 $provision_ip | awk '/packets/{gsub(/\%/,"",$6); print $6}')
         result=$(ping -q -c 50 -i 0.02 -w 3 $provision_ip | awk -vFS="," '/packets/{print $(NF-1) }')

         
         if [ $result -gt 80 ]; then
           color="tomato"

         elif [ $result -gt 60 ]; then
           color="orange"

         elif [ $result -gt 40 ]; then
             color="lightorange"

         elif [ $result -gt 20 ]; then
             color="lightgreen"

         else  color="lightgreen"

         fi  
         
         echo "<tr><td bgcolor = '$color' > Ping Provision Server IP $provision_ip  - ${result}</td></tr>"

       done < /tmp/provision_ip.txt


    else echo "<tr><td>No provision server set</td></tr>"
    fi
  

  ## static routes for server IPs?
  #  while  read provision_ip ; do  
  #   route -n | grep -E "^$provision_ip" > /dev/null || echo "<tr><td bgcolor = 'tomato'>No static route to $provision_ip</td></tr>"
  #  done < /tmp/provision_ip.txt


 ## Tunnel status  ###
 vibe-stat san | sed -r 's/\(.+\)//' | awk -vFS="\t" '(NR!=1){ printf "<tr><td bgcolor ="; printf ($2~".*up"?"lightgreen":"tomato"); printf "> Link: \""$1"\" "$2 "</td></tr>\n"  }'
 

fi ## End of if [ "$WEBIF_PERMS" == "rw"  ]

## check firmware ###
 cat << EOF
        </tbody></table>
       </div class = settings-content>  <!-- <div > -->
       </div class = settings> <!-- <div > -->
       <blockquote class = "settings-help" float:right>
         <h4>AVPN Status Test Page.</h4>
         <p> This pages checks you network setup and connections.
            <br><br><h4> NOTE:</h4><p>$error_string</p>
      </blockquote>
EOF


?>

 <!--
##WEBIF:name:Acceleration:995:Check Status
-->


