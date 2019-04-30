#!/usr/bin/webif-page

<?
. /usr/lib/webif/webif.sh 
. /www/cgi-bin/webif/add_url_functions.sh
. /lib/vibe/webfuncs.sh

############################################################################
##avpn-addurl version 14
## 09/05/2018 ###
## Added warnings for mmissing DNS and internet connection.
## If no DNS, URLS are not checked but are printed in Orange
## 27-4-2018
## avpn-addurl version 13
## removed a line of debug which was duplicated.
##
## 29-8-2017
## avpn-addurl.sh Version 12
## Removed first char from usl and replace with wild card.
## Fix to remove last entry in the table.
##
############################################################################


header "Acceleration" "Add URLs" "@TR<<Add URLs to Accelerated Routes>>" '' "$SCRIPT_NAME"

#echo "<meta http-equiv=\"refresh\" content=\"20\" />"
#display_vibe_error


##header "Acceleration" "Add URL" "@TRAcceleartion" '' "$SCRIPT_NAME"
## need to check out 2.6.2 Parameter Expansion.###

cat << EOF
 <style>
    .Button-margin
    {
        margin:5px;
    }
</style>


<!-- <script type="text/javascript" src="/js/avpn-addurl.js"></script> -->

<script> 
var counter = 2;
var limit = 20;


// Add a row to the table by creating a row object //
function AddRowElement(mytable){
      var newRow = document.createElement("TR");
      newRow.className = "even";
      newRow.id = "test";
      mytable.appendChild(newRow);
      var newcell0 = document.createElement("TD");
      newcell0.innerHTML = rowind;
      newRow.appendChild(newcell0);

}



////////// Add the dropdown options for the url table

// options_string='Another Test Config', 'Australia', 'Europe', 'Europe New', 'USA', 'None';


function add_dropdown (my_row_number, dropdown_string){
  
  //Split the options string on the commas between config names.
  // Cant use spaces as the config names have spaces in them.

  var options_array = dropdown_string.split(",");
  cell_entry = "<select id = \"list" + my_row_number +"\" " + " name = \"configid" + my_row_number + "\">" +
               "<option value=\"\" disabled=\"disabled\" selected=\"selected\">Please Select</option>";

  for (i=0; i<options_array.length; i++) {              
     cell_entry = cell_entry + "<option value=\"" + options_array[i] + "\">" + options_array[i] + "</option>";
  }

  cell_entry = cell_entry + "</select>"
  return cell_entry
}


/////////// Add a row to the table using insertRow //
function AddRowFunction(table,row_number, my_options_string) {
    var row = table.insertRow(-1);
    row.id = "row" + ++row_number;


    var row_class = "odd";
    if (row_number % 2){ var row_class = "odd"} else { var row_class = "even"};
    row.className = row_class;
    var cell1 = row.insertCell(0);
    var cell2 = row.insertCell(1);
    var cell3 = row.insertCell(2);
    var cell4 = row.insertCell(3);
    var cell5 = row.insertCell(4);
    cell1.innerHTML = "<input name = \"url" + row_number + "\" type='text' placeholder='Enter a URL'>";
    
    cell2.innerHTML = add_dropdown(row_number, my_options_string);

    cell3.innerHTML = "";

    cell4.innerHTML = "<input class=\"btn btn-info\" type=\"button\" value=\"Delete\" \
           onClick=\"row" + row_number + ".outerHTML = ''; delete row" + row_number + ";\">"

    addbutton.innerHTML = " <input  class=\"btn btn-info\" type=\"button\" value=\"Add a URL\" \
        onClick=\"AddRowFunction(configtable," + row_number +",\'" + my_options_string + "\');\"> " +
        "<input  class='btn btn-info' type='submit' value='Confirm Changes' onClick=\"checkConfig(rowcounthidden.value)\">" + 
        "<br><br><br>"


    rowcountparam.innerHTML = "<input id = \"rowcounthidden\"  type=\"hidden\" name = \"rowcounttotal\" value = \"" + row_number + "\">";
}


// check if the config has been selected
// if not use previous value.
// This because you cant put a preset value in the
// input window without removing all other options
// from the pull down. (actually I think you can)
// So show what is in there using the placeholder
// instead then reload it as the value on submit
// if its not already been set.

function checkConfig(mycount){
 
 mycount++;

  for (var i =1 ; i <= mycount; i++){


      conf = document.getElementById("list"+i);

      if (conf != null){ // makesure row exist and not deleted.
        if (conf.value == ''){
          conf.value = conf.placeholder ;
        }
      }
   }


}

function AddSubmit(mycount, addsub_options_string){

    addbutton.innerHTML = " <input  class=\"btn btn-info\" type=\"button\" value=\"Add a URL\" \
                            onClick=\"AddRowFunction(configtable," + mycount + ",\'" + addsub_options_string + "\');\"> " +
        "<input  class='btn btn-info' type='submit' value='Confirm Changes' onClick=\"checkConfig(rowcounthidden.value)\">" +
        "<br><br><br>"

//logparam.innerHTML = "Count is : " + mycount
}


</script>	
EOF


############# Main Page #######################
#echo "<h3>Current Configurations</h3>"

#### Print out the url table for the selected config ######
url_table="/etc/custom/urls.table"
url_table1="/etc/custom/urls.table1"
url_table_previous="/etc/custom/urls.table.previous"

debug=0


 if [ "$WEBIF_PERMS" == "rw"  ] ##  If user has permisssion do stuff. ##
  then
  

    ## if the submit form has been clicked .... ######

    if [ $FORM_submit -eq 1 ] && ! [ $FORM_metric_update ] && ! [ $FORM_apply_config ]

     then

    [ $debug -eq 1 ] && echo "FORM_submit:  $FORM_submit<br>"
    [ $debug -eq 1 ] && echo "FORM_metric_update:  $FORM_metric_update<br>"
    [ $debug -eq 1 ] && echo "FORM_apply_config:  $FORM_apply_config<br>"


       # echo "<p>Submitting data</p><br>"
        [ $debug -eq 1 ] && echo "<p>Total row count is $FORM_rowcounttotal</p><br>"
          mv $url_table1  /etc/custom/url_table1.temp
          #mv $url_table url_table.temp
          rm /tmp/url.log

        [ $debug -eq 1 ] && echo "<br>cat /etc/custom/url_table1.temp<br>"
        [ $debug -eq 1 ] && cat  /etc/custom/url_table1.temp |  awk '{print $0"<br>"'}
        [ $debug -eq 1 ] && echo "<br>"


        
          

           count=1
           total=$((FORM_rowcounttotal + 1))
            #echo "Url $FORM_url1 has been added to $FORM_config1"

            ## Go through all $FORM_url* and $FORM_config* variables
            ## Write these to the table. Write all entries even if they already exist.
            ## This take into account any entries that have been deleted.
            ## So in effect all get deleted and the ones still in the form are put back.
            while [ $count -le $total ]
            do
             url=$(eval echo \$FORM_url$count)
             config=$(eval echo \$FORM_configid$count)
             
             [ $debug -eq 1 ] && echo "removing spaces from config"
             
             ### Replace Spaces in the config name with |'s'
             ### Spaces cause all sorts of problems so easier to get rid.
             config=$(echo $config | sed 's/ /|/g')
             [ $debug -eq 1 ] && echo "## config: $config<br>"

             [ $url ] && [ $config ] && write_to_table $url $config $url_table $url_table1
             [ $url ] && [ ! $config ] && echo "No configuration selected for '$url'<br>" && update_config=0
             [ $config ] && [ ! $url ] && echo "No URL selected for '$config'<br>" && update_config=0


             [ $debug -eq 1 ] && echo "<p>$count:  url: $url  </p><br>"
             [ $debug -eq 1 ] && echo "<p>config: $config</p><br>"

             count=$((count + 1))
            done

            

            ## Keep a copy of the current table for comparing url entrie against new ones.
            [ $debug -eq 1 ] && echo "cp $url_table  $url_table_previous<br>"
            cp $url_table  $url_table_previous      

            ### If the table is now empty table1 wont exist.
            ### This means a cp will fail and the main table wont
            ### get emptied. Therefore remove table and previous table if no table1
            
            if [ -e $url_table1 ]
               then
                [ $debug -eq 1 ] && echo "cp $url_table1 $url_table<br>"
                cp $url_table1 $url_table
              else rm $url_table $url_table_previous >& /dev/null
            fi
 
           
           [ $debug -eq 1 ] && echo "<br>cat /etc/custom/urls.table<br>"
           [ $debug -eq 1 ] && cat /etc/custom/urls.table 
            ## Check for any matching URLS.
            


            check_urls $url_table $url_table_previous
             ## If both files exists then check for urls with matching metrics in 
             ## the current table1 anyway as the tables can get out of sync
             ## and matching urls and metrics will get missed.
            [ $debug -eq 1 ] && echo "check_matching_metrics $readfile<br>"
            if check_matching_metrics $url_table
               then
                  [ $debug -eq 1 ] && echo "cat /tmp/check_matching_metrics.tmp >> /tmp/matching_urls.txt<br>"
                   [ -e "/tmp/check_matching_metrics.tmp" ]  && cat /tmp/check_matching_metrics.tmp >> /tmp/matching_urls.txt
            fi

            if [ -e "/tmp/matching_urls.txt" ]
            
             then
                   metric_update_form "/tmp/matching_urls.txt" $url_table

            else              

             #enter_url 
              update_button=1
              create_table $url_table
              echo "<br>"
              echo "<br><br>"
              [ -e $url_table ] || remove_all_entries
              cat /tmp/url.log
              unset FORM_submit

               #####################  Save changes to the Vibe Config #################### 
               if [  $update_config -eq 1 ] 
                then
                      apply_and_reload $url_table
                fi

               ##########################################################################

            fi

    ###################################################################################
    elif [ "$FORM_metric_update" == "updated" ]
      then
      [ $debug -eq 1 ] && echo "FORM_submit:  $FORM_submit<br>"
      [ $debug -eq 1 ] && echo "FORM_metric_update:  $FORM_metric_update<br>"
      [ $debug -eq 1 ] && echo "FORM_apply_config:  $FORM_apply_config<br>"
      [ $debug -eq 1 ] && echo "All updated"

      check_urls $url_table $url_table_previous  
      update_button=1  
      create_table $url_table

    ###################################################################################
    ### when the metrics have been updated and the submitted the value $FORM_metric_update gets set to
    ###  the last count in the awk function. The count is not now used but its 
    ### different from setting it to 'updated'. The variable  $FORM_metric_update is set to a count
    ### in metric_update_form 

    elif [ $FORM_metric_update ]
      then
        [ $debug -eq 1 ] && echo "FORM_submit:  $FORM_submit<br>"
        [ $debug -eq 1 ] && echo "FORM_metric_update:  $FORM_metric_update<br>"
        [ $debug -eq 1 ] && echo "FORM_apply_config:  $FORM_apply_config<br>"
       
     ## If any of the metrics have been overridden by user
     ## update these in table1 before copying over.
        if [ -e /tmp/update_metrics.txt ] ## created in metric_update_form function.
          then 
                update_metrics $url_table1 $url_table_previous

                [ $debug -eq 1 ] && echo "From FORM_metric_update: check_matching_metrics $readfile<br>"
                   
                   ## /tmp/matching_urls.txt is genereated in check_urls. Used by metric_update_form
                   [ $debug -eq 1 ] && echo "deleting /tmp/matching_urls.txt<br>"
                   rm  /tmp/matching_urls.txt >& /dev/null

                   if check_matching_metrics $url_table1
                    then
                     [ $debug -eq 1 ] && echo "cat /tmp/check_matching_metrics.tmp >> /tmp/matching_urls.txt<br>"
                     [ -e "/tmp/check_matching_metrics.tmp" ]  && cat /tmp/check_matching_metrics.tmp >> /tmp/matching_urls.txt
                     [ -e "/tmp/matching_urls.txt" ] && {
                       sort -u  /tmp/matching_urls.txt > /tmp/get_urls2.txt
                       mv /tmp/get_urls2.txt /tmp/matching_urls.txt || echo "mv /tmp/get_urls2.txt /tmp/matching_urls.txt failed<br>"
                     }
                   
                   fi


                   if [ -e "/tmp/matching_urls.txt" ]
                    then
                     metric_update_form "/tmp/matching_urls.txt" $url_table1

                   else
                      cp $url_table1 $url_table
                      cp  $url_table $url_table_previous
                      # echo "<p>Route order has been set.</p><br><button type=\"submit\" name=\"metric_update\" value=\"updated\"><b>Return to URL table<b> </button><br>"
                      [ $debug -eq 1 ] && echo "##Return to table button removed. check_ips then Apply config changes instead##"
                      check_urls $url_table $url_table_previous
                      apply_and_reload $url_table "return_to_table"

                    fi 

        else 
             echo "file /tmp/update_metrics.txt not found<br>"
        fi
       
    ###################################################################################
    elif [ "$FORM_apply_config" == "apply_config" ]
      then
        [ $debug -eq 1 ] && echo "FORM_submit:  $FORM_submit<br>"
        [ $debug -eq 1 ] && echo "FORM_metric_update:  $FORM_metric_update<br>"
        [ $debug -eq 1 ] && echo "FORM_apply_config:  $FORM_apply_config<br>"   
        ##[ $debug -eq 1 ] && env | awk '/FORM|POST/{print $1"<br>">}'
        #[ $debug -eq 1 ] && env | awk '{print $1"<br>">}'

        ##apply_config_changes $url_table
        if apply_config_changes $url_table
           then 
           [ $debug -eq 1 ] && echo "Reloading configuration"
            /etc/init.d/vibe reload
             echo "Configurations updated<br><br>"
             echo "<button type='submit' name='apply_config' value='apply_config_back'><b>Return to URL table</b></button><br>"

         else echo "Error Cant reload Configs"
              echo "<button type='submit' name='apply_config' value='apply_config_back'><b>Back</b></button><br>"

        fi

        update_button=0
    
    ###################################################################################
    else ## If form not submited and no metrics to update then print the table

      [ $debug -eq 1 ] && echo "FORM_submit:  $FORM_submit<br>"
      [ $debug -eq 1 ] && echo "FORM_metric_update:  $FORM_metric_update<br>"
      [ $debug -eq 1 ] && echo "FORM_apply_config:  $FORM_apply_config<br>"

          #enter_url
           create_table $url_table
           [ -e $url_table ] || remove_all_entries   ## print the current table. echo "<br>"
          echo "<br><br>"
          unset $FORM_metric_update

    fi
    echo "</form>"

else echo "<h2>Permission Denied</h2>"
fi ## End of if $WEBIF_PERMS

 ?>

 <!--
##WEBIF:name:Acceleration:310:Add URLs
-->

