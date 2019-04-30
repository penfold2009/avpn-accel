#!/bin/sh

##########################################################################
### add_url_function-15.sh
### Version 19
### Added warnings for mmissing DNS and internet connection.
### If no DNS, URLS are not checked but are printed in Orange
###
### add_url_functions-14.sh 
### Version 18 27/4/2018 ###
### Removed the Wildcard from the URL and added single quotes.
### Version 17 27/11/2017 ###

### Fixed bug where IPs are added just after the
### first 'remote' statement even if its been commented out.
### Now look for first remote statement with only white
### space before it.

############################################################################


write_to_table(){

local my_url=$1
local my_config=$2
local myurl_table=$3
local myurl_table1=$4

[ $debug -eq 1 ] && echo "######################################################<br>"
[ $debug -eq 1 ] && echo "## Function write_to_table() ## <br>"
[ $debug -eq 1 ] && echo "my_url=\"$my_url\"<br>"
[ $debug -eq 1 ] && echo "my_config=\"$my_config\"<br>"
[ $debug -eq 1 ] && echo "myurl_table=\"$myurl_table\"<br>"
[ $debug -eq 1 ] && echo "myurl_table1=\"$myurl_table1\"<br>"
[ $debug -eq 1 ] && echo "$myurl_table1 :-<br>"
[ $debug -eq 1 ] &&  cat $myurl_table1  |  awk '{print $0"<br>"'}
[ $debug -eq 1 ] && echo "$myurl_table :-<br>"
[ $debug -eq 1 ] &&  cat $myurl_table  |  awk '{print $0"<br>"'}
[ $debug -eq 1 ] && echo "<br>"

[ $debug -eq 1 ] && echo "Updated my_config=\"$my_config\"<br>"


## If the metric has already been set use this value.
local my_config_awk=$(echo $my_config | sed -r 's/\|/\\|/g') ## escape the |'s so that awk doesnt try and use them.
local metric=$(awk '/^'$my_url' '$my_config_awk' /{print $3}' $myurl_table)
[ $debug -eq 1 ] && echo "metric=\$(awk '/^'$my_url' '$my_config_awk'/{print $3}' $myurl_table)<br>"


#If metric is not set then calculate it from the number of dots in the url.
[ $metric -gt 0 ] || metric=$(calc_metric $my_url)
[ $debug -eq 1 ] && echo "Checking metric for $my_url in $my_config : Its $metric <br>"
[ $debug -eq 1 ] && echo "Current submitted data <br> my_url: $my_url. <br> my_config: $my_config<br>"

ls_config=$(echo $config | sed 's/|/ /g') ## Put back any spaces into the file name so it can be used in 'ls' command##


### Check that the URLs and Configs are valid ###############
if [ "$config" == "none"] 
  then
    echo "Error: Misssing config for $url" >> /tmp/url.log
    return 1

elif ! ls "/etc/vibe.conf.d/$ls_config" > /dev/null && [ $ls_config != "None" ]
  then
   echo "Configuration: \"$ls_config\" does not exist. <br><br>"
   return 1

elif [ $(echo $my_url | tr -cd ^[.]| wc -c) -gt 5 ]; then
  echo "Url: \"$my_url\" too large.<br><br>"
  return 1

elif grep '^'$my_url' '$my_config' ' $myurl_table1 >> /dev/null
   then
     echo "Duplicate Entry:  \"$my_url $my_config\". Discarded.<br><br>"
     return 1

elif ! echo $my_url |  grep '\.' >& /dev/null
  then
    echo " \"$my_url\" is not a valid URL.<br><br>"
    return 1


elif echo $my_url |  grep '\,' >& /dev/null
  then
    echo " \"$my_url\" is not a valid URL.<br><br>"
    return 1

else

  if echo "$my_url $my_config $metric" >> $myurl_table1
    then  
         [ $debug -eq 1 ] && echo "$1 has been added to $2<br>" >> /tmp/url.log
         [ $debug -eq 1 ] && echo "<br>writting $my_url $my_config $metric to $myurl_table1<br>"

           update_config=1

  else echo "Cant write to $url_table"
  
  fi

fi



}

########################################################################

apply_and_reload(){


local url_table=$1

    if apply_config_changes $url_table
       then 
       [ $debug -eq 1 ] && echo "Reloading configuration"
        /etc/init.d/vibe reload
         echo "<br>Configurations updated<br>"
         [ "$2" == "return_to_table" ] && echo "<button type='submit' name='apply_config' value='apply_config_back'><b>Return to url table</b></button><br>"
          return
     else echo "Error Cant reload Configs"
          echo "<button type='submit' name='apply_config' value='apply_config_back'><b>Back</b></button><br>"

    fi
}

#########################################################################

check_matching_metrics(){ ## check for any matching urls and metrics in urls.table1

rm /tmp/check_matching_metrics.tmp >& /dev/null
rm /tmp/check_matching_metrics1.tmp >& /dev/null



my_file=$1
[ $debug -eq 1 ] && echo "Function : check_matching_metrics <br> reading $my_file<br>"

 awk '
        $2 !~ /None/{urls[$1" "$3]++}
       
       END { for (y in urls){
              if ( urls[y] > 1 ){
               print y >> "/tmp/check_matching_metrics1.tmp";
              }
             }
            }
     ' $my_file

## remove the metric. Keep the url.
 [ -e "/tmp/check_matching_metrics1.tmp" ]  &&  awk '{print $1}' /tmp/check_matching_metrics1.tmp > /tmp/check_matching_metrics.tmp

[ $debug -eq 1 ] && echo "cat /tmp/check_matching_metrics.tmp<br>"
[ $debug -eq 1 ] && cat /tmp/check_matching_metrics.tmp | awk '{print $0"<br>}'
[ $debug -eq 1 ] && echo "<br>"

 if [ -e "/tmp/check_matching_metrics.tmp" ]
   then
    # echo "Please ensure all priorites are different.<br><br><br>"
     return 0
   else
     [ $debug -eq 1 ] && echo "Metrics Ok.<br>"
     return 1
 fi  

}

#  check_matching_metrics /etc/custom/urls.table1



########################################################################################
## If there are any duplicate URLs with the same metric the user needs to priorities them
## This function counts the number of occurances of url and metric using a hash array.
## Array is called ulr. Key is url and metric: urls[$1"-"$3]
## the updated values are written to the the file /tmp/update_metrics.txt

check_urls(){
  #    check_urls $url_table $url_table_previous
[ $debug -eq 1 ] && echo "Function: check_urls() $1<br>"

rm /tmp/update_metrics.txt >& /dev/null
rm /tmp/matching_urls.txt >& /dev/null
rm /tmp/get_urls2.txt >& /dev/null

[ $debug -eq 1 ] && echo "<p>Checking URLs</p><br>"

local readfile=$1
local readpreviousfile=$2

[ $debug -eq 1 ] && echo "<br>cat $readfile<br>"
[ $debug -eq 1 ] && cat $readfile | awk '{print $0"<br>"}'
[ $debug -eq 1 ]  && [ -n "$readpreviousfile" ] && echo "<br>cat $readpreviousfile<br>"
[ $debug -eq 1 ]  && [ -n "$readpreviousfile" ] && cat $readpreviousfile | awk '{print $0"<br>"}'
[ $debug -eq 1 ] && echo "<br>"

## If any urls have matching metrics print out all 
## entries for that url. Even the ones with a different metric.
## So basically count the number of new entries for each url
## in the current table. Then count the number of old entries
## for each url. If the number has gone up they need to be updated. 

if [ -n "$readpreviousfile" ] && [ -e $readpreviousfile ]
                            
                            
 then

[ $debug -eq 1 ] && echo "Checking both $readfile $readpreviousfile<br>"

  awk ' NR==FNR && $2 !~ /None/{urls_new[$1]++; next} 
       
        { urls_old[$1]++ }
       
       END { for (y in urls_new){
              if (( urls_new[y] > urls_old[y]) && (urls_new[y] > 1)){ 
               print y >> "/tmp/matching_urls.txt"
              }
             }
          }
     '  $readfile $readpreviousfile

   [ -e "/tmp/matching_urls.txt" ] && {
      sort -u  /tmp/matching_urls.txt > /tmp/get_urls2.txt
      mv /tmp/get_urls2.txt /tmp/matching_urls.txt || echo "mv /tmp/get_urls2.txt /tmp/matching_urls.txt failed<br>"
   }


  else

    ### ## If the url.table.previous doesnt exist (eg table was emptied or its a new one)
    ## Then just count the number of entries being add now.
    ## as not possible to compare to previous ones.

    [ $debug -eq 1 ] && echo "Checking only $readfile<br>"

      awk ' { urls[$1]++ }
       
       END { for (y in urls){
              if ( urls[y] > 1 ){ 
               print y >> "/tmp/matching_urls.txt"
              }
             }
          }
     '  $readfile

  fi

}

################################################################################

metric_update_form () {
### Now go through all entires of any URLs which having matcing metrics with at least one other entry 

[ $debug -eq 1 ] && echo "<br>Function: metric_update_form<br>"
 rm /tmp/url_count.txt >& /dev/null

local my_geturls=$1
local read_file=$2
unset url_count
unset line

[ $debug -eq 1 ] && echo "my_geturls=\"$my_geturls\"<br>"
[ $debug -eq 1 ] && echo "read_file=\"$read_file\"<br>"

if [ -e $my_geturls ] 
  then

## Now add the count of urls entries to the file 
## (used in the range of values that can be selected in the form.)

## need to correct this tomorrow... not using $readfile.
 #awk '{urls[$1]++}END{for (x in urls){print x" "urls[x] >> "/tmp/url_count.txt"}}'  /tmp/matching_urls.txt

 while read line 
   do 
    url_count=$(grep -c '^'$line $read_file)
    [ $debug -eq 1 ] && echo "\"$line\" $url_count >> /tmp/url_count.txt<br>"
    echo $line" "$url_count >> /tmp/url_count.txt

 done < $my_geturls



[ $debug -eq 1 ] && echo "cat /tmp/url_count.txt<br>"
[ $debug -eq 1 ] && cat /tmp/url_count.txt | awk '{print $0"<br>"}'
[ $debug -eq 1 ] && echo "cat $read_file<br>"
[ $debug -eq 1 ] && cat $read_file | awk '{print $0"<br>"}'



[ $debug -eq 1 ] && echo "Mutiple entries for :-"
[ $debug -eq 1 ] && cat $my_geturls | awk '{print $0"<br>"}'
[ $debug -eq 1 ] && echo "<br>"

cat << EOF

<div class = settings>
 <div class = settings-content>

  <table id=\"metric_table\" style=\"width:50%\">
     <tr>
       <h3>Please select the order that these routes should be used.</h3>
     </tr>


EOF

  awk ' BEGIN{count = 1}
      
      NR==FNR{urls[$1] = $2; next} 
     
     { for (x in urls){
        if ($1 == x ) { form_name = "new_metric_"count++;
          print form_name" "$1" "$2" "urls[x] >> "/tmp/update_metrics.txt" 
          gsub(/\|/, " ", $2);
          print "<tr><td>"$1"</td><td>&nbsp;via&nbsp;</td><td>"$2"<td><td>&nbsp;priority&nbsp;<td><input type=\"number\" name=\""form_name"\" min=\"1\" max=\""urls[x]"\"></td></tr>";
          }
        }
     }
     END {print "</table id=\"metric_table\"><br>"
           print "<button type=\"submit\" name=\"metric_update\" value=\""count"\"><b>Submit</b></button><br>"

         }

  ' /tmp/url_count.txt $read_file
 
 
cat << EOF
 </div class = settings>
 </div class = settings-content>
 <blockquote class = "settings-help" float:right>
   <h4> Selecting route order</h4>
   <p> The displayed URLs have been slected  to route via more than one route. You must now select in which order the routes should be used. The highest priority is "1". Lower priority routes will only
be used if all higher priority routes are down. You must match the order count with the number of available routes i.e. if there are only two routes the order will be 1 then 2, 
entries above 2, or matching entries, will be ignored and you will have to re-enter. Similarly for other counts.  </p> 
 </blockquote>
 
EOF

  return 1

  
else  
  echo "File: $my_geturls not found<br>"
  return 0  

fi

}





########################################################################################
update_metrics(){ 

## When the user has set the priorities then read
## the file /tmp/update_metrics.txt and write to urls.table1

 [ $debug -eq 1 ] && echo "Function: update_metrics<br>"

rm /tmp/update_metrics_output.txt >& /dev/null
local my_url_table1=$1
my_url_table_previous=$2

if [ $debug -eq 1 ] 
      then  
       echo "Now in update_metrics<br>"
       echo "update_metrics<br>"
       echo "cat /tmp/update_metrics.txt<br>"
       cat   /tmp/update_metrics.txt | awk '{print $0"<br>"}'
       echo "<br>cat /etc/custom/urls.table1<br>"
       cat /etc/custom/urls.table1  | awk '{print $0"<br>"}'
       echo "<br><br>"

fi


while read line
  do
local my_var=$(echo $line | awk '{print $1}')
local my_url=$(echo $line | awk '{print $2}')
local my_config=$(echo $line | awk '{print $3}')
local my_range=$(echo $line | awk '{print $4}')
    

local temp_updated_metric=$(eval echo \$FORM_$my_var)  ## This is the value selected on the web page
                                                     ## eg FORM_new_metric_
    
    [ $debug -eq 1 ] && {
       echo "my_var=$my_var<br>"
       echo "my_url=\"$my_url\"<br>"
       echo "my_config=\"$my_config\"<br>"
       echo "my_range=\"$my_range\"<br>"
       echo "temp_updated_metric=\"$temp_updated_metric\"<br>"
    }


    if [ -n "$temp_updated_metric" ] ## Check that the user has set a value.

     then
        [ $debug -eq 1 ] && echo "temp_updated_metric : $temp_updated_metric. <br>"

        #my_file=$1
        
        ## calc the metric from the number of dots in url minus the user added priority
        local temp_metric=$(calc_metric $my_url)
        local temp_user_metric=$(($my_range - $temp_updated_metric))
        local updated_metric=$(($temp_metric - $temp_user_metric))

        [ $debug -eq 1 ] && echo "updated_metric=$updated_metric. <br>"
        [ $debug -eq 1 ] && echo "<br>sed -i 's/$my_url $my_config .*$/'$my_url $my_config $updated_metric/' /etc/custom/urls.table1<br><br>"
        

        sed -i 's/'$my_url' '$my_config' .*$/'$my_url' '$my_config' '$updated_metric'/' /etc/custom/urls.table1
        
        [ $debug -eq 1 ] && echo "/etc/custom/urls.table1 now contains:-"
        [ $debug -eq 1 ] && cat  /etc/custom/urls.table1 | awk '{print $0"<br>"}'
        [ $debug -eq 1 ] && echo "<br>"
  
        [ $debug -eq 1 ] && echo "$my_url $my_config $updated_metric" >> /tmp/update_metrics_output.txt
      
        else
         echo "Value not set.<br><br>"
         return 1
        fi

      done < /tmp/update_metrics.txt

      [ $debug -eq 1 ] && echo "<br>cat /etc/custom/urls.table1<br>" 
      [ $debug -eq 1 ] && cat  /etc/custom/urls.table1 | awk '{print $0"<br>"}'
      [ $debug -eq 1 ] && echo "<br>"


      cp -p /tmp/update_metrics.txt /tmp/update_metrics.temp
      rm /tmp/update_metrics.txt  >& /dev/null
     return 0

  
}

################################################################################################

apply_config_changes (){

local my_file=$1

  [ $debug -eq 1 ] && echo "Going to update configs<br>"
  [ $debug -eq 1 ] && echo "my_file=$my_file<br>"


   [ $debug -eq 1 ] && echo "Remove all urls networks from configs.<br>"



### Remove all the current urls so that the most recent changes to the URL table can be added.
   SAVEIFS=$IFS
   IFS=$(echo -en "\n\b")

     for file in $(ls /etc/vibe.conf.d)
         do
         [ $debug -eq 1 ] &&  echo "file is : $file<br>"

          awk '   /^#VbREVISION/{$2++; print $0; next}
                 /^.*Auto URL Fill.*$/{next}{print}' "/etc/vibe.conf.d/$file" > "/etc/vibe.conf.d/${file}.temp"
               
         done
   IFS=$SAVEIFS


## if the urls table file exists then update urls in the config
if [ -e $my_file ]; then


    ### now go through the urls.table file and add in
    ### all the urls to network statements
    while read line

      do

       ## local my_url=$(echo $line | awk '{print "*"$1}') # Add a wildcard to the begining of the url.
       
       ###############################################################################################################################
       # The awk substr option removes the initial first char from $1.                                                               #
       # substr(s, a, b) : it returns b number of chars from string s, starting at position a. The parameter b is optional.          #
       # Therefore substr($1,2) prints all chars in $1 from the 2nd char onwards.                                                    #
       # reason for this is because searching for *www.bbc.co.uk means that the url lookup will never search for just www.bbc.co.uk  #
       # as the wildcard does not include no char. Therefore to search for the string plus any other additions remove the first      #
       # char and leave the wildcard.                                                                                                #
       ###############################################################################################################################

#       local my_url=$(echo $line | awk '{print "*"substr($1,2);}') ## Wildcards are no longer needed.
       #local my_url=$(echo $line | awk '{print $1}')
       local my_url="'"${line/ */}"'"

       local my_config=$(echo $line | awk '{print $2}')
       local my_config=$(echo $my_config | sed 's/|/ /g') ## Put back any spaces into the file name so it can be listed##
       local my_metric=$(echo $line | awk '{print $3}')


        if [ "$my_config" != "None" ]; then
           [ $debug -eq 1 ] && echo "Adding the ulr $my_url with metric $my_metric to $my_config<br>"

            ## Add the new URL to the config. Check for a 'remote' that is preceded only by white space ##
           awk ' BEGIN{count = 0}
              /^#VbREVISION/{$2++; print $0; next}
              /^[[:space:]]*remote/{found++;print $0; next}
              /^.*\{/ && (found){ if (count == 0) {
                          gsub($0,$0"\nnetwork '$my_url' \{metric = '$my_metric'\} ## Auto URL Fill ##")
                          print; count++
                      }
                       else {print}
                       next
                  } 
                 {print}
                ' "/etc/vibe.conf.d/${my_config}.temp" > "/etc/vibe.conf.d/${my_config}.temp1"

            mv "/etc/vibe.conf.d/${my_config}.temp1" "/etc/vibe.conf.d/${my_config}.temp"
        
        else echo "Ignoring $my_url assigned to $my_config <br><br>"

        fi
      done < "$my_file"
fi



  ## Move the temp files back to the oriiginal names ##
  ## Changing the field separator solves the problem with 'ls /etc/vibe.conf.d/*.temp'
  SAVEIFS=$IFS
   IFS=$(echo -en "\n\b")

  for file in $(ls /etc/vibe.conf.d/*.temp)
    do 
     [ $debug -eq 1 ] && echo "file: $file<br>"
     #newfile=$(echo $file | cut -f 1-3 -d .)
     ## CP 29/5/19. above line removes any chars following dots eg .68
     newfile=${file%%.temp} ## just .temp should be removed.     
     [ $debug -eq 1 ] && echo "moving file '$file' to '$newfile'<br>"
     mv "$file" "$newfile"
  
  done
  IFS=$SAVEIFS

}

##############################################################################
## Used in write_to_table to work out the metric if not already been set ###

calc_metric() {

 local my_url=$1
 local my_count=$(echo $my_url | tr -cd ^[.]| wc -c)
 
 local my_count=$((my_count * 100))
 local my_count=$((500 - my_count))


 echo $my_count


}

##############################################################################

### Sort the table by ulr and priority of url.
sort_table(){

  local my_url_table=$1

[ $debug -eq 1 ] && echo "Function: sort_table $my_url_table"

  [ ! -e /tmp/sort_table_dir ] && mkdir -p /tmp/sort_table_dir
  [ -e /tmp/sort_table_dir ] && rm /tmp/sort_table_dir/* >& /dev/null

  awk '{print $3" "$2" "$1 >> "/tmp/sort_table_dir/"$1}' $my_url_table
  for sort_file in $(ls /tmp/sort_table_dir/*); do
      [ $debug -eq 1 ] && echo "sort -n /tmp/sort_table_dir/$(basename $sort_file) > /tmp/sort_table_dir/$(basename $sort_file).tmp"
        sort -n /tmp/sort_table_dir/$(basename $sort_file) > /tmp/sort_table_dir/$(basename $sort_file).tmp
    awk 'BEGIN{count=1}{print $3" "$2" "$1" "count++ }' /tmp/sort_table_dir/$(basename $sort_file).tmp >>  /tmp/sort_table_dir/url.table.out
  
  done
  [ $debug -eq 1 ] && echo "cp -p /tmp/sort_table_dir/url.table.out $my_url_table"
  cp -p /tmp/sort_table_dir/url.table.out $my_url_table

[ $debug -eq 1 ] && echo "sort_table: $file has been sorted now contain:-<br>"
[ $debug -eq 1 ] && cat $file | awk '{print $0"<br>"}'

}





########################################################################################################

lookup_urls (){

rm /tmp/file_link_tests.table >& /dev/null

if ping -c 1 www.bbc.co.uk >& /tmp/ping.test
 then  internet=1
else 
    if grep -iq 'Network unreachable' /tmp/ping.test >& /dev/null
      then 
        echo "<h3 style = 'color:red'>Warning: No public internet connection.</h2>"
        echo "Please check your internet connection."
        internet=1  ## If theres  no internet you may still have a local dns, so dont change the URLS to Oranage.
    elif grep -iq 'unknown host' /tmp/ping.test ; then
        echo "<h3 style = 'color:red'>Warning: Unable to resolve URLs.</h2>"
        echo "Please check your internet connection."

        internet=0
    fi
fi 

while read line 
   do 
     local url=$(echo $line | awk '{print $1}')
     [ $debug -eq 1 ] && echo "lookup_urls:  checking $url<br>"
     [ $debug -eq 1 ] && echo "internet: $internet<br>"
     if [ "$internet" -eq 1 ]
         then 
           $(nslookup $url | grep -qi 'address 1:') && echo "$line black" >> /tmp/file_link_tests.table || echo "$line red" >> /tmp/file_link_tests.table
     else echo "$line orange" >> /tmp/file_link_tests.table
    fi
   
   done < $1

}


#########################################################################################################



remove_all_entries(){

 [ $debug -eq 1 ] && echo "Table is empty remove all configs.<br>"

### If the table is empty remove all the url entries.
   SAVEIFS=$IFS
   IFS=$(echo -en "\n\b")

     for file in $(ls /etc/vibe.conf.d)
         do
         [ $debug -eq 1 ] &&  echo " removing entries from: $file<br>"

          awk '   /^#VbREVISION/{$2++; print $0; next}
                 /^.*Auto URL Fill.*$/{next}{print}' "/etc/vibe.conf.d/$file" > "/etc/vibe.conf.d/${file}.temp"
                 mv "/etc/vibe.conf.d/${file}.temp" "/etc/vibe.conf.d/$file"
         done
   IFS=$SAVEIFS

 echo "No Entries.<br>"
[ $debug -eq 1 ] && echo "Reloading configuration"
  
  /etc/init.d/vibe reload


}
#########################################################################################################
create_table (){

local valid=""

rm /tmp/drop_down_options >& /dev/nul


### Get the configuration names for the dropdown list.
### the names can contain spaces hence the need to change the
### IFS for this part then change it back again.
SAVEIFS=$IFS
   IFS=$(echo -en "\n\b")

  for listfile in $(egrep -l 'remote' /etc/vibe.conf.d/*); do
  [ -e ${listfile}@exclude ] && [ $(cat ${listfile}@exclude) -eq 1 ] || {
      echo $(basename $listfile) >> /tmp/drop_down_options
        valid=$valid"\$|^"$(basename $listfile)
      

  }
done

IFS=$SAVEIFS
 
##echo "None" >> /tmp/drop_down_options

local valid_list=$(echo $valid | sed -r 's/^\$\|+//; s/$/\$/') ## remove first '|' ##
local valid_list=$(echo $valid_list | sed -r 's/ /\\|/g') ## now replace  spaces with an escaped |
                                                    ## URLS with spaces in are stored in urls.table
                                                    ## wth a | in place of a space.
                                                    ## Valid list is now a full pattern matching
                                                    ## string which AWK can use to create the table rows.

[ $debug -eq 1 ] && echo "valid_list=\"$valid_list\"<br>" 

## create the array options_string.This is passed to the javascript
## to create the dropdown table.
lines=$(wc -l /tmp/drop_down_options | awk '{print $1}')
local options_string=$(awk -vlastline=$lines  '
                    {if (NR == lastline){printf "%s",$0} 
                     else {printf "%s, ",$0} }
                      ' /tmp/drop_down_options)


local file=$1



## Sort the table into the correct names and
## calc the priorities from the metrics.
sort_table $file

[ $debug -eq 1 ] && echo "create_table: $file has been sorted now contain:-<br>"
[ $debug -eq 1 ] && cat $file | awk '{print $0"<br>"}'


## Check the urls and add appropriate colours for if it is valid or not.
lookup_urls $file

local file_row_count=$(cat $file | wc -l)
cat << EOF

<div class = settings>

<h3><strong>Current URL Table</strong></h3>
 <div class = settings-content>
  
<table id="configtable" style="width:50%">
<th>URL</th>
<th>Route Used</th>
<th>&nbsp;Priority</th>
EOF

 

#valid_list="Australia|Europe|USA|Europe New"
#[ $debug -eq 1 ] && echo "valid_list: $valid_list<br>"

echo "</datalist>"


  awk -vfilecount=$file_row_count ' BEGIN {count = 1} ### filecount is the total number of rows taken from urls.table
      
       $2 ~ /'"$valid_list"'/{colour=(NR%2?"odd":"even"); 
                rowid = "row"count; 
                listid = "list"count; 
                urlid = "url"count; 
                configid ="configid"count; \
                gsub(/\|/, " ", $2); \
                print "<tr class = \""colour"\" id =\""rowid"\"> \
                <td><input type=\"text\" style=\"color:"$5"\" name=\""urlid"\" onfocusout=\"AddSubmit('\''"filecount"'\'',dropdown_options)\" value=\""$1"\" placeholder=\"Enter a URL\"></td> \
               <td><select id =\""listid"\" name=\""configid"\" onfocus=\"AddSubmit('\''"filecount"'\'',dropdown_options)\" >\
                      drop_down_value:\""$2"\" \
                       </td> \
               <td style=\"text-align: center\">"$4"</td> \
               <td><input class=\"btn btn-info\" type=\"button\" value=\"Delete\" \
                        onClick=\" "rowid".outerHTML = '\'\''; delete "rowid"; AddSubmit('\''"filecount"'\'',dropdown_options) \"></td> \
               </tr>"; count++; next}
    
       ## If the url is not in a valid config          ###
       ## (eg the name has been changed)               ###
       ## then add the url but without a preset config ###

       {colour=(NR%2?"odd":"even"); rowid = "row"count; listid = "list"count; urlid = "url"count; configid ="configid"count; \
        print "<tr class = \""colour"\" id =\""rowid"\"> \
        <td><input type=\"text\" name=\""urlid"\"  onfocusout=\"AddSubmit('\''"filecount"'\'',dropdown_options)\" value=\""$1"\" placeholder=\"Enter a URL\"></td> \
      <td><select id =\""listid"\" name=\""configid"\" onfocus=\"AddSubmit('\''"filecount"'\'',dropdown_options)\"> \
           drop_down_value:\"None\" \
           </td> \
           <td style=\"text-align: center\">"$4"</td> \
      <td><input class=\"btn btn-info\" type=\"button\" value=\"Delete\" \
           onClick=\" "rowid".outerHTML = '\'\''; delete "rowid"; AddSubmit('\''"filecount"'\'',dropdown_options);\"></td> \
        </tr>"; count++;}
        ' /tmp/file_link_tests.table > /tmp/awk_test1.out

## Add in the options string. Easier to do it this way than try and munge it into the awk script
sed "s/dropdown_options/'$options_string'/" /tmp/awk_test1.out > /tmp/awk_test.out

## In the previous awk command replace the line drop_down_value with the dropdowwn list
## and set the correct option to 'selected'.
    awk -vFS="\"" '  NR==FNR{urls[count++] = $0; next} 
           /drop_down_value/{ 
              if ($2 == "None") {
                          print "<option selected value=\"None\">None</option>"
                          for (y in urls){print "<option value=\""urls[y]"\">"urls[y]"</option>" }
              }
              else { for (y in urls){
                       if ($2 == urls[y]){print "<option selected value=\""urls[y]"\">"urls[y]"</option>"}
                       else {print "<option value=\""urls[y]"\">"urls[y]"</option>" }
                      }
              }

            next 
           }
           { print }

         ' /tmp/drop_down_options /tmp/awk_test.out > /tmp/awk.out
       


        cat /tmp/awk.out

## Pass the row count total to bash in the $FORM_rowcounttotal variable ##
## Also gets updated in the javascript AddRowFunction ##
cat << EOF
 </table>
 <br>
  <div id ="rowcountparam"><input id = "rowcounthidden" type="hidden" name = "rowcounttotal" value ='$file_row_count'></div>
  <div id = "addbutton">
   <input  class="btn btn-info" type="button" value="Add a URL" onClick="AddRowFunction(configtable,'$file_row_count','$options_string');">
   <br><br><br>
EOF

# if [  $update_button -eq 1 ]
#   then
#    cat << EOF
#    <button class='btn btn-info' type='submit' name='apply_config' value='apply_config'> <b>Save Changes</b> </button>
# EOF
# fi


cat << EOF
  </div>
 </div class = settings-content>  <!-- <div > -->
 </div class = settings> <!-- <div > -->
 <blockquote class = "settings-help" float:right>
  <h4> Adding URLs </h4>
  <p>Use this page to add URLs that should be routed via specific accelerated routes.<br>Add the URL and select the route to be used from the dropdown list. URLS that match the entered URL will then use the specified route. <br><br> \
Note that entering "mysite.com" will only match the URL "mysite.co.uk". To do a global match you can use "*"  for instance *.co.uk would route "anything".co.uk via the specified route. \
However, a more specific URL route will be used in  preference to a less specific one. This means that if "support.mysite.co.uk" \
is assigned to route 2 and "*.co.uk" is assigned to route 1, traffic for "support.mysite.co.uk" WILL use route 2. Note: Regular expressions are also supported. Please contact support for more details if required. <br><br>  \
The same URL can be added to more than one route for redundancy purposes. For example "mysite.com" could be routed via routes to North America and South America if both of those routes have similar final hop latencies. If duplicate URLS via \
different routes are detected you will be given the option to choose the order that the routes should be used.  <br><br> <b> Changes are not saved until you click on the "Save Changes" button. </b></p>  

 </blockquote>

EOF

[ $debug -eq 1 ] && echo "options_string=" $options_string

##   <input class='btn btn-info' type='submit' value='submit' onClick="checkConfig(rowcounthidden.value)">



}

##       create_table /etc/custom/urls.table
