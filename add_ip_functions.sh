#!/bin/sh

##########################################################################
### add_ip_functions-17.sh
### Version 17 27/11/2017 ###

### Fixed bug where IPs are added just after the
### first 'remote' statement even if its been commented out.
### Now look for first remote statement with only white
### space before it.


############################################################################


write_to_table(){

local my_ip=$1
local my_config=$2
local myip_table=$3
local myip_table1=$4

[ $debug -eq 1 ] && echo "######################################################<br>"
[ $debug -eq 1 ] && echo "## Function write_to_table() ## <br>"
[ $debug -eq 1 ] && echo "my_ip=\"$my_ip\"<br>"
[ $debug -eq 1 ] && echo "my_config=\"$my_config\"<br>"
[ $debug -eq 1 ] && echo "myip_table=\"$myip_table\"<br>"
[ $debug -eq 1 ] && echo "myip_table1=\"$myip_table1\"<br>"
[ $debug -eq 1 ] && echo "$myip_table1 :-<br>"
[ $debug -eq 1 ] &&  cat $myip_table1  |  awk '{print $0"<br>"'}
[ $debug -eq 1 ] && echo "$myip_table :-<br>"
[ $debug -eq 1 ] &&  cat $myip_table  |  awk '{print $0"<br>"'}
[ $debug -eq 1 ] && echo "<br>"

[ $debug -eq 1 ] && echo "Updated my_config=\"$my_config\"<br>"


## If the metric has already been set use this value.
local my_config_awk=$(echo $my_config | sed -r 's/\|/\\|/g') ## escape the |'s so that awk doesnt try and use them.
local metric=$(awk '/^'$my_ip' '$my_config_awk' /{print $3}' $myip_table)
[ $debug -eq 1 ] && echo "metric=\$(awk '/^'$my_ip' '$my_config_awk'/{print $3}' $myip_table)<br>"


[ $metric -gt 0 ] || metric=50
[ $debug -eq 1 ] && echo "Checking metric for $my_ip in $my_config : Its $metric <br>"
[ $debug -eq 1 ] && echo "Current submitted data <br> my_ip: $my_ip. <br> my_config: $my_config<br>"

ls_config=$(echo $config | sed 's/|/ /g') ## Put back any spaces into the file name so it can be used in 'ls' command##


### Check that the ips and Configs are valid ###############
if [ "$config" == "none" ] 
  then
    echo "Error: Misssing config for $ip" >> /tmp/ip.log
    return 1

elif ! ls "/etc/vibe.conf.d/$ls_config" > /dev/null && [ $ls_config != "None" ]
  then
   echo "Configuration: \"$ls_config\" does not exist. <br><br>"
   return 1



elif [ $(echo $my_ip | tr -cd ^[.]| wc -c) -gt 5 ]; then
  echo "ip: \"$my_ip\" too large.<br><br>"
  return 1

elif grep '^'$my_ip' '$my_config' ' $myip_table1 >> /dev/null
   then
     echo "Duplicate Entry:  \"$my_ip $my_config\". Discarded.<br><br>"
     return 1

elif ! echo $my_ip |  grep '\.' >& /dev/null
  then
    echo " \"$my_ip\" is not a valid IP address / or subnet combination.<br><br>"
    return 1


elif echo $my_ip |  grep '\,' >& /dev/null
  then
    echo " \"$my_ip\" is not a valid address / subnet combination.<br><br>"
    return 1

else

  if echo "$my_ip $my_config $metric" >> $myip_table1
    then  
         [ $debug -eq 1 ] && echo "$1 has been added to $2<br>" >> /tmp/ip.log
         [ $debug -eq 1 ] && echo "<br>writting $my_ip $my_config $metric to $myip_table1<br>"
         
         update_config=1

  else echo "Cant write to $ip_table"
  
  fi

fi



}

########################################################################

apply_and_reload(){


local ip_table=$1

    if apply_config_changes $ip_table
       then 
       [ $debug -eq 1 ] && echo "Reloading configuration"
        /etc/init.d/vibe reload
         echo "<br>Configurations updated<br>"
         [ "$2" == "return_to_table" ] && echo "<button type='submit' name='apply_config' value='apply_config_back'><b>Return to ip table</b></button><br>"
          return
     else echo "Error Cant reload Configs"
          echo "<button type='submit' name='apply_config' value='apply_config_back'><b>Back</b></button><br>"

    fi
}
#########################################################################

check_matching_metrics(){ ## check for any matching ips and metrics in ips.table1

rm /tmp/check_matching_metrics.tmp >& /dev/null
rm /tmp/check_matching_metrics1.tmp >& /dev/null

##[ "$my_ip" == "0.0.0.0"] && echo "## Warning you are setting a default route.## <br>"


my_file=$1
[ $debug -eq 1 ] && echo "Function : check_matching_metrics <br> reading $my_file<br>"

 awk '
        $2 !~ /None/{ips[$1" "$3]++}
       
       END { for (y in ips){
              if ( ips[y] > 1 ){
               print y >> "/tmp/check_matching_metrics1.tmp";
              }
             }
            }
     ' $my_file

## remove the metric. Keep the ip.
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

#  check_matching_metrics /etc/custom/ips.table1



########################################################################################
## If there are any duplicate ips with the same metric the user needs to priorities them
## This function counts the number of occurances of ip and metric using a hash array.
## Array is called ulr. Key is ip and metric: ips[$1"-"$3]
## the updated values are written to the the file /tmp/update_metrics.txt

check_ips(){
  #    check_ips $ip_table $ip_table_previous
[ $debug -eq 1 ] && echo "Function: check_ips() $1<br>"

rm /tmp/update_metrics.txt >& /dev/null
rm /tmp/matching_ips.txt >& /dev/null
rm /tmp/get_ips2.txt >& /dev/null

[ $debug -eq 1 ] && echo "<p>Checking ips</p><br>"

local readfile=$1
local readpreviousfile=$2

[ $debug -eq 1 ] && echo "<br>cat $readfile<br>"
[ $debug -eq 1 ] && cat $readfile | awk '{print $0"<br>"}'
[ $debug -eq 1 ]  && [ -n "$readpreviousfile" ] && echo "<br>cat $readpreviousfile<br>"
[ $debug -eq 1 ]  && [ -n "$readpreviousfile" ] && cat $readpreviousfile | awk '{print $0"<br>"}'
[ $debug -eq 1 ] && echo "<br>"

## If any ips have matching metrics print out all 
## entries for that ip. Even the ones with a different metric.
## So basically count the number of new entries for each ip
## in the current table. Then count the number of old entries
## for each ip. If the number has gone up they need to be updated. 

if [ -n "$readpreviousfile" ] && [ -e $readpreviousfile ]
                                                        
 then

[ $debug -eq 1 ] && echo "Checking both $readfile $readpreviousfile<br>"

  awk ' NR==FNR && $2 !~ /None/{ips_new[$1]++; next} 
       
        { ips_old[$1]++ }
       
       END { for (y in ips_new){
              if (( ips_new[y] > ips_old[y]) && (ips_new[y] > 1)){ 
               print y >> "/tmp/matching_ips.txt"
              }
             }
          }
     '  $readfile $readpreviousfile

   [ -e "/tmp/matching_ips.txt" ] && {
      sort -u  /tmp/matching_ips.txt > /tmp/get_ips2.txt
      mv /tmp/get_ips2.txt /tmp/matching_ips.txt || echo "mv /tmp/get_ips2.txt /tmp/matching_ips.txt failed<br>"
   }


  else

    ### ## If the ip.table.previous doesnt exist (eg table was emptied or its a new one)
    ## Then just count the number of entries being add now.
    ## as not possible to compare to previous ones.

    [ $debug -eq 1 ] && echo "Checking only $readfile<br>"

      awk ' { ips[$1]++ }
       
       END { for (y in ips){
              if ( ips[y] > 1 ){ 
               print y >> "/tmp/matching_ips.txt"
              }
             }
          }
     '  $readfile

  fi

}

################################################################################

metric_update_form () {
### Now go through all entires of any ips which having matcing metrics with at least one other entry 

[ $debug -eq 1 ] && echo "<br>Function: metric_update_form<br>"
 rm /tmp/ip_count.txt >& /dev/null

local my_getips=$1
local read_file=$2
unset ip_count
unset line

[ $debug -eq 1 ] && echo "my_getips=\"$my_getips\"<br>"
[ $debug -eq 1 ] && echo "read_file=\"$read_file\"<br>"

if [ -e $my_getips ] 
  then

## Now add the count of ips entries to the file 
## (used in the range of values that can be selected in the form.)

## need to correct this tomorrow... not using $readfile.
 #awk '{ips[$1]++}END{for (x in ips){print x" "ips[x] >> "/tmp/ip_count.txt"}}'  /tmp/matching_ips.txt

 while read line 
   do 
    ip_count=$(grep -c '^'$line $read_file)
    [ $debug -eq 1 ] && echo "\"$line\" $ip_count >> /tmp/ip_count.txt<br>"
    echo $line" "$ip_count >> /tmp/ip_count.txt

 done < $my_getips



[ $debug -eq 1 ] && echo "cat /tmp/ip_count.txt<br>"
[ $debug -eq 1 ] && cat /tmp/ip_count.txt | awk '{print $0"<br>"}'
[ $debug -eq 1 ] && echo "cat $read_file<br>"
[ $debug -eq 1 ] && cat $read_file | awk '{print $0"<br>"}'



[ $debug -eq 1 ] && echo "Mutiple entries for :-"
[ $debug -eq 1 ] && cat $my_getips | awk '{print $0"<br>"}'
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
      
      NR==FNR{ips[$1] = $2; next} 
     
     { for (x in ips){
        if ($1 == x ) { form_name = "new_metric_"count++;
          print form_name" "$1" "$2" "ips[x] >> "/tmp/update_metrics.txt" 
          gsub(/\|/, " ", $2);
          print "<tr><td>"$1"</td><td>&nbsp;via&nbsp;</td><td>"$2"<td><td>&nbsp;priority&nbsp;<td><input type=\"number\" name=\""form_name"\" min=\"1\" max=\""ips[x]"\"></td></tr>";
          }
        }
     }
     END {print "</table id=\"metric_table\"><br>"
           print "<button type=\"submit\" name=\"metric_update\" value=\""count"\"><b>Submit</b></button><br>"

         }

  ' /tmp/ip_count.txt $read_file
 
 
cat << EOF
 </div class = settings>
 </div class = settings-content>
 <blockquote class = "settings-help" float:right>
   <h4> Selecting route order</h4>
   <p> The displayed ips have been slected  to route via more than one route. You must now select in which order the routes should be used. The highest priority is "1". Lower priority routes will only
be used if all higher priority routes are down. You must match the order count with the number of available routes i.e. if there are only two routes the order will be 1 then 2, 
entries above 2, or matching entries, will be ignored and you will have to re-enter. Similarly for other counts.  </p> 
 </blockquote>
 
EOF

  return 1

  
else  
  echo "File: $my_getips not found<br>"
  return 0  

fi

}





########################################################################################
update_metrics(){ 

## When the user has set the priorities then read
## the file /tmp/update_metrics.txt and write to ips.table1

 [ $debug -eq 1 ] && echo "Function: update_metrics<br>"

rm /tmp/update_metrics_output.txt >& /dev/null
local my_ip_table1=$1
my_ip_table_previous=$2

if [ $debug -eq 1 ] 
      then  
       echo "Now in update_metrics<br>"
       echo "update_metrics<br>"
       echo "cat /tmp/update_metrics.txt<br>"
       cat   /tmp/update_metrics.txt | awk '{print $0"<br>"}'
       echo "<br>cat /etc/custom/ips.table1<br>"
       cat /etc/custom/ips.table1  | awk '{print $0"<br>"}'
       echo "<br><br>"

fi


while read line
  do
local my_var=$(echo $line | awk '{print $1}')
local my_ip=$(echo $line | awk '{print $2}')
local my_config=$(echo $line | awk '{print $3}')
local my_range=$(echo $line | awk '{print $4}')
    
local temp_updated_metric=$(eval echo \$FORM_$my_var)  ## This is the value selected on the web page
                                                     ## eg FORM_new_metric_
    
    [ $debug -eq 1 ] && {
       echo "my_var=$my_var<br>"
       echo "my_ip=\"$my_ip\"<br>"
       echo "my_config=\"$my_config\"<br>"
       echo "my_range=\"$my_range\"<br>"
       echo "temp_updated_metric=\"$temp_updated_metric\"<br>"
    }


    if [ -n "$temp_updated_metric" ] ## Check that the user has set a value.

     then
        [ $debug -eq 1 ] && echo "temp_updated_metric : $temp_updated_metric. <br>"

        #my_file=$1
        
        ## calc the metric from the number of dots in ip minus the user added priority
        local temp_metric=$(calc_metric $my_ip)
        local temp_user_metric=$(($my_range - $temp_updated_metric))
        local updated_metric=$(($temp_metric - $temp_user_metric))

        [ $debug -eq 1 ] && echo "updated_metric=$updated_metric. <br>"
        [ $debug -eq 1 ] && echo "<br>sed -i 's/$my_ip $my_config .*$/'$my_ip $my_config $updated_metric/' /etc/custom/ips.table1<br><br>"
        

        sed -i 's/'$my_ip' '$my_config' .*$/'$my_ip' '$my_config' '$updated_metric'/' /etc/custom/ips.table1
        
        [ $debug -eq 1 ] && echo "/etc/custom/ips.table1 now contains:-"
        [ $debug -eq 1 ] && cat  /etc/custom/ips.table1 | awk '{print $0"<br>"}'
        [ $debug -eq 1 ] && echo "<br>"
  
        [ $debug -eq 1 ] && echo "$my_ip $my_config $updated_metric" >> /tmp/update_metrics_output.txt
      
        else
         echo "Value not set.<br><br>"
         return 1
        fi

 done < /tmp/update_metrics.txt

      [ $debug -eq 1 ] && echo "<br>cat /etc/custom/ips.table1<br>" 
      [ $debug -eq 1 ] && cat  /etc/custom/ips.table1 | awk '{print $0"<br>"}'
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


### Remove all the current urls so that the most recent changes to the URL table can be added.

   [ $debug -eq 1 ] && echo "Remove all ips networks from configs.<br>"

   SAVEIFS=$IFS
   IFS=$(echo -en "\n\b")

     for file in $(ls /etc/vibe.conf.d)
         do
          [ $debug -eq 1 ] && echo "file is : $file<br>"

          awk '   /^#VbREVISION/{$2++; print $0; next}
                 /^.*IP Auto Fill.*$/{next}{print}' "/etc/vibe.conf.d/$file" > "/etc/vibe.conf.d/${file}.temp"
               
         done
   IFS=$SAVEIFS


## if the ips table file exists then update ips in the config
if [ -e $my_file ]; then

  
    ### now go through the ips.table file and add in
    ### all the ips to network statements
    while read line

      do

       local my_ip=$(echo $line | awk '{ gsub(/-/, "/", $0); print $1}') # Dont need to Add a wildcard to the begining of the ip.
             #my_ip=$(echo $my_ip | awk '{$0=$0~/\//?$0:$0"/32"}END{print}')
             my_ip=$(echo $my_ip | awk '{$0=$0~/0.0.0.0/?$0"/0":$0~/\//?$0:$0"/32"}END{print}') ## If the ip doesnt have a '/'
                                                                                                ## then its a /32 so add that in.
       local my_config=$(echo $line | awk '{print $2}')
       local my_config=$(echo $my_config | sed 's/|/ /g') ## Put back any spaces into the file name so it can be listed##
       local my_metric=$(echo $line | awk '{print $3}')


        if [ "$my_config" != "None" ]; then
           [ $debug -eq 1 ] && echo "Adding the ulr $my_ip with metric $my_metric to $my_config<br>"

            ## Add the new ip to the config. Check for a 'remote' that is preceded only by white space ##
           awk ' BEGIN{count = 0}
              /^#VbREVISION/{$2++; print $0; next}
              /^[[:space:]]*remote/{found++;print $0; next}
              /^.*\{/ && (found){ if (count == 0) {
                          gsub($0,$0"\nnetwork '$my_ip' \{metric = '$my_metric'\} ## IP Auto Fill ##")
                          print; count++
                      }
                       else {print}
                       next
                  } 
                 {print}
                ' "/etc/vibe.conf.d/${my_config}.temp" > "/etc/vibe.conf.d/${my_config}.temp1"

            mv "/etc/vibe.conf.d/${my_config}.temp1" "/etc/vibe.conf.d/${my_config}.temp"
        
        else echo "Ignoring $my_ip assigned to $my_config <br><br>"

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
     newfile=$(echo $file | cut -f 1-3 -d .)
     [ $debug -eq 1 ] && echo "moving file '$file' to '$newfile'<br>"
     mv "$file" "$newfile"
  
  done
  IFS=$SAVEIFS

}

##############################################################################
## Used in write_to_table to work out the metric if not already been set ###

calc_metric() {

 local my_ip=$1
 local my_count=$(echo $my_ip | tr -cd ^[.]| wc -c)
 
 local my_count=$((my_count * 100))
 local my_count=$((500 - my_count))


 echo $my_count


}

##############################################################################

### Sort the table by ulr and priority of ip.
sort_table(){

  local my_ip_table=$1

[ $debug -eq 1 ] && echo "Function: sort_table $my_ip_table"

  [ ! -e /tmp/sort_table_dir ] && mkdir -p /tmp/sort_table_dir
  [ -e /tmp/sort_table_dir ] && rm /tmp/sort_table_dir/* >& /dev/null

  awk '{print $3" "$2" "$1 >> "/tmp/sort_table_dir/"$1}' $my_ip_table
  for sort_file in $(ls /tmp/sort_table_dir/*); do
      [ $debug -eq 1 ] && echo "sort -n /tmp/sort_table_dir/$(basename $sort_file) > /tmp/sort_table_dir/$(basename $sort_file).tmp"
        sort -n /tmp/sort_table_dir/$(basename $sort_file) > /tmp/sort_table_dir/$(basename $sort_file).tmp
    awk 'BEGIN{count=1}{print $3" "$2" "$1" "count++ }' /tmp/sort_table_dir/$(basename $sort_file).tmp >>  /tmp/sort_table_dir/ip.table.out
  
  done
  [ $debug -eq 1 ] && echo "cp -p /tmp/sort_table_dir/ip.table.out $my_ip_table"
  cp -p /tmp/sort_table_dir/ip.table.out $my_ip_table
[ $debug -eq 1 ] && echo "$file has been sorted now contain:-<br>"

[ $debug -eq 1 ] && echo "$file has been sorted now contain:-<br>"
[ $debug -eq 1 ] && cat $file | awk '{print $0"<br>"}'

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
                 /^.*IP Auto Fill.*$/{next}{print}' "/etc/vibe.conf.d/$file" > "/etc/vibe.conf.d/${file}.temp"
                 mv "/etc/vibe.conf.d/${file}.temp" "/etc/vibe.conf.d/$file"
         done
   IFS=$SAVEIFS

 echo "No Entries.<br>"
 [ $debug -eq 1 ] && echo "Reloading configuration"
  /etc/init.d/vibe reload


}

#########################################################################################################

check_default_route (){


echo "## Warning Default route. ##<br>"
echo "Are you sure? <br>"

cat << EOF
  <button class='btn btn-info' type='submit' name='defaultroute' value='yes'> <b>Yes</b> </button>  
  <button class='btn btn-info' type='submit' name='defaultroute' value='no'> <b>No</b> </button>
<br>
EOF


}

#########################################################################################################
### Create the HTML code to display the curent table. #####

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
                                                    ## ipS with spaces in are stored in ips.table
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
#sed -r 's/-/\//g' $file > $file"_mod"



## Sort the table into the correct names and
## calc the priorities from the metrics.
sort_table $file

[ $debug -eq 1 ] && echo "$file has been sorted now contain:-<br>"
[ $debug -eq 1 ] && cat $file | awk '{print $0"<br>"}'

local file_row_count=$(cat $file | wc -l)
cat << EOF

<div class = settings>

<h3><strong>Current IP Table</strong></h3>
 <div class = settings-content>
  
<table id="configtable" style="width:50%">
<th>IP</th>
<th>Route Used</th>
<th>&nbsp;Priority</th>
EOF

 

#valid_list="Australia|Europe|USA|Europe New"
#[ $debug -eq 1 ] && echo "valid_list: $valid_list<br>"

echo "</datalist>"


  awk -vfilecount=$file_row_count ' BEGIN {count = 1} ### filecount is the total number of rows taken from ips.table
      
       $2 ~ /'"$valid_list"'/{colour=(NR%2?"odd":"even"); 
                rowid = "row"count; 
                listid = "list"count; 
                ipid = "ip"count; 
                elementid = "ipid"count;
                configid ="configid"count; \
                gsub(/\|/, " ", $2); \
                gsub(/-/, "/", $1); \
                print "<tr class = \""colour"\" id =\""rowid"\"> \
                <td><input type=\"text\" id = \""elementid"\" name=\""ipid"\" value=\""$1"\" onfocusout=\"AddSubmit('\''"filecount"'\'',dropdown_options, '\''"elementid"'\'')\" placeholder=\"Enter a ip\"></td> \
               <td><select id =\""listid"\" name=\""configid"\" onfocus=\"AddSubmit('\''"filecount"'\'',dropdown_options)\" >\
                      drop_down_value:\""$2"\" \
                       </td> \
               <td style=\"text-align: center\">"$4"</td> \
               <td><input class=\"btn btn-info\" type=\"button\" value=\"Delete\" \
                        onClick=\" "rowid".outerHTML = '\'\''; delete "rowid"; AddSubmit('\''"filecount"'\'',dropdown_options) \"></td> \
               </tr>"; count++; next}
    
       ## If the ip is not in a valid config          ###
       ## (eg the name has been changed)               ###
       ## then add the ip but without a preset config ###

       {colour=(NR%2?"odd":"even"); rowid = "row"count; listid = "list"count; ipid = "ip"count; configid ="configid"count; \
        print "<tr class = \""colour"\" id =\""rowid"\"> \
        <td><input type=\"text\" id = \""elementid"\" name=\""ipid"\"  onfocusout=\"AddSubmit('\''"filecount"'\'','\''"ipid"'\'',dropdown_options,'\''"elementid"'\'')\" value=\""$1"\" placeholder=\"Enter a ip\"></td> \
      <td><select id =\""listid"\" name=\""configid"\" onfocus=\"AddSubmit('\''"filecount"'\'',dropdown_options)\"> \
           drop_down_value:\"None\" \
           </td> \
           <td style=\"text-align: center\">"$4"</td> \
      <td><input class=\"btn btn-info\" type=\"button\" value=\"Delete\" \
           onClick=\" "rowid".outerHTML = '\'\''; delete "rowid"; AddSubmit('\''"filecount"'\'',dropdown_options);\"></td> \
        </tr>"; count++;}
        ' $file > /tmp/awk_test1.out

## Add in the options string. Easier to do it this way than try and munge it into the awk script
sed "s/dropdown_options/'$options_string'/" /tmp/awk_test1.out > /tmp/awk_test.out

## In the previous awk command replace the line drop_down_value with the dropdowwn list
## and set the correct option to 'selected'.
    awk -vFS="\"" '  NR==FNR{ips[count++] = $0; next} 
           /drop_down_value/{ 
              if ($2 == "None") {
                          print "<option selected value=\"None\">None</option>"
                          for (y in ips){print "<option value=\""ips[y]"\">"ips[y]"</option>" }
              }
              else { for (y in ips){
                       if ($2 == ips[y]){print "<option selected value=\""ips[y]"\">"ips[y]"</option>"}
                       else {print "<option value=\""ips[y]"\">"ips[y]"</option>" }
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
   <input  class="btn btn-info" type="button" value="Add an IP" onClick="AddRowFunction(configtable,'$file_row_count','$options_string');">
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
  <h4> Adding IPs </h4>
  <p>Use this page to add IP addresses that should be routed via specific accelerated routes.<br>Add the IP Address and select the route to be used from the dropdown list. Traffic destined for IPs that match IP addresses in the table will then use the specified route. <br> \
<h4>Note</h4><p>IP Ranges may be entered by using the CIDR format. For example 1.2.3.0/24 However the IP entered MUST be a valid network IP for the range specified. If it is not, you will get an error message. For example \
X.X.X.0 is valid for /24 and both X.X.X.0 and X.X.X.128 are valid for /25 networks but X.X.X.128/24 is invalid.
 
The same IP address can be assigned to more than one route for redundancy purposes. For example IP address 1.2.3.4/32 could be assigned to two different routes so that a second route can be used if the first fails. If duplicate IPs via \
different routes are detected you will be given the option to choose the order that the routes should be used.  <br>
<h4> DO NOT DELIBERATELY ENTER BOTH A URL AND A MATCHING IP THAT THE URL RESOLVES TO as this will prevent traffic from routing. <br> <br></p>  

 </blockquote>

EOF
[ $debug -eq 1 ] && echo "options_string=" $options_string

##   <input class='btn btn-info' type='submit' value='submit' onClick="checkConfig(rowcounthidden.value)">



}

##       create_table /etc/custom/ips.table