#!/usr/bin/webif-page


<?
. /usr/lib/webif/webif.sh 
# . /www/cgi-bin/webif/add_ip_functions.sh
. /www/cgi-bin/webif/add_url_functions.sh
. /lib/vibe/webfuncs.sh

#################################################################
## version 2 09/05/2018                                        ##
##   Added warnings for missing DNS and internet connection   ##
##   Unresolved URLs are now displayed in red                  ##
##                                                             ##
## version 1 25/07/2017                                        ##
#################################################################


header "Acceleration" "Check URLs" "@TR<<URL Check. >>" '' "$SCRIPT_NAME"

print_table () {

  if  [ -e $url_table ]
    then 
        cat << EOF
         <h3><strong>Currently Configured URLs.</strong></h3>
         <table id="url_table" style="width:50%">

         <th>URL</th>
         <th>Returned IP count </th>
EOF
 
        ## Check all the URLs in the current table. ##
        my_count=1;
        for my_url in $(awk '{print $1}' $url_table); do 
     
            [ $(($my_count%2)) -eq 0 ] && my_class="even" || my_class="odd"
                  nslookup $my_url 2> /dev/null | awk -vAwkClass=$my_class -vAwkURL=$my_url -vquote="'" \
                        '$3 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ && NR >= 5 { urls[++count] = $3} \
                         END { if (count) { print "<tr class = "quote AwkClass quote"><td>"AwkURL"</td><td>"count"</td>" }  \
                               else print "<tr class = "quote AwkClass quote" style = "quote"color:red"quote"><td>"AwkURL"</td><td>None</td>" 
                          }'

              my_count=$(($my_count + 1))
              echo "</tr>"
              my_class=$(($my_class + 1))     
        done

        echo "</table>"
        echo "<br>"
        echo "<button type='submit' name='Update' value='Update'><b>Refresh Table</b></button><br><br>"

  else  echo "No entries.<br><br><button type='submit' name='Update' value='Update'><b>Refresh Table</b></button><br><br>"


  fi
}



test_url(){
 ### Do stuff here ###
          echo "<br>Checking $FORM_url.<br><br>"
          echo "<table style='width:50%'>"
#          nslookup $FORM_url |awk '$3 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ && NR >= 5 {urls[++count] = $3} \
          nslookup $FORM_url 2> /dev/null |awk '$3 ~ /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/ && $1 =="Address" {urls[++count] = $3} \
                  END { \
                     if(count){\
                       print count" IP addresses : <br><br>"; \
                       for (i = 1; i <= count; ++i){ \
                         colour=(i%2?"odd":"even"); \
                         print "<tr class = "colour"><td>"i"</td><td>"urls[i]"</td></tr>" \
                        } 
                     }\
                     else print "No IP addresses for this URL. <br><br>"}'
          
          echo "</table><br>" 
          echo "<button type='submit' name='back' value='go_back'><b>Clear</b></button><br><br>"
}



print_page(){


        cat << EOF
          <div class = settings>
          <div class = settings-content>
          <br>
             <h3><strong>URL lookup test.</strong></h3>
          <br>

          <input style="color:black" type="text" name="url" value="" placeholder="Enter a URL">
          <input  class='btn btn-info' type='submit' name="check" value='Check'>
          <br>
          <br>
                   
EOF
          if [ $FORM_submit -eq 1 ]; then

             if [ $FORM_check ]; then
                 test_url
            
            elif [ $FORM_Update ];then
               print_table > $current_urls
            fi
          fi

         cat $current_urls
cat << EOF
       </div class = settings-content>  <!-- <div > -->
       </div class = settings> <!-- <div > -->
       <blockquote class = "settings-help" float:right>
         <h4> URL Check</h4>
         <p> The URL checker carries out an nslookup of the URLS in the URL table to see if they return any 
             IP addresses. If they do the number of IPs returned is listed. If you get a very large number 
             of returns you should consider whether you have selected the correct URL. There ia also an 
             option to look up an individual URL to see if there is a DNS entry for it. 
             The individual check lists all of the IP addresses returned. 
             <br><br><h4> NOTE:</h4><p> If you have entered part of a URL, for example just "mysite.com" 
             because you wanted to match "anythingmysite.com" then you are likely to get either a different 
             IP address to the one you might be expecting or possibly no IP address at all.  This is not necessarily 
             a failure. Only fully qualified names should definitely return IPs.   </p>
      </blockquote>
EOF


}





debug=0
url_table="/etc/custom/urls.table"
current_urls="/etc/custom/url_check.html"
[ -e "$current_urls" ]   || print_table > $current_urls

 if [ "$WEBIF_PERMS" == "rw"  ] ##  If user has permisssion do stuff. ##
  
  then

# echo "FORM_submit:  $FORM_submit<br>"
# echo "FORM_back:  $FORM_back<br>"
# echo "FORM_Update: $FORM_Update<br>"
# echo "FORM_check: $FORM_check<br>"

    if ping -c 1 -w 2 $pingtestserver >& /tmp/ping.test
    ## if  ping -c 1 www.bbc.co.uk >& /tmp/ping.test
     then print_page
     
    elif grep -iq 'unknown host' /tmp/ping.test ; then
        echo "<h3 style = 'color:red'>Error: Unable to resolve URLs.</h2>"
                echo "Please check your internet connection."


    else echo "<h3 style = 'color:red'>Warning: No public internet connection</h2>"
        echo "Please check your internet connection."
      print_page
    fi ## end of if ping


 fi ## if [ "$WEBIF_PERMS" == "rw"  ] 

 

?>

 <!--
##WEBIF:name:Acceleration:311:Check URLs
-->

