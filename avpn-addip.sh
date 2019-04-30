#!/usr/bin/webif-page

<?

. /usr/lib/webif/webif.sh 
. /www/cgi-bin/webif/add_ip_functions.sh
. /lib/vibe/webfuncs.sh

### Version 16 29/8/17 ###


header "Acceleration" "Add IPs" "@TR<<Add IPs to Accelerated Routes>>" '' "$SCRIPT_NAME"

#echo "<meta http-equiv=\"refresh\" content=\"20\" />"
#display_vibe_error


## need to check out 2.6.2 Parameter Expansion.###

cat << EOF
 <style>
    .Button-margin
    {
        margin:5px;
    }
</style>


<!-- <script type="text/javascript" src="/js/avpn-addip.js"></script> -->

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



////////// Add the dropdown options for the ip table

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
    cell1.innerHTML = "<input id = \"ipid" + row_number + "\" name = \"ip" + row_number + "\" type='text' placeholder='Enter a ip' " +
                      "onfocusout=\"return ValidateIPaddress('ipid" + row_number + "', 'ip" + row_number + "')\"  >";
    
    cell2.innerHTML = add_dropdown(row_number, my_options_string);

    cell3.innerHTML = "";

    cell4.innerHTML = "<input class=\"btn btn-info\" type=\"button\" value=\"Delete\" \
           onClick=\"row" + row_number + ".outerHTML = ''; delete row" + row_number + ";\">"

    addbutton.innerHTML = " <input  class=\"btn btn-info\" type=\"button\" value=\"Add a ip\" \
        onClick=\"AddRowFunction(configtable," + row_number +",\'" + my_options_string + "\');\"> " +
        "<input   id = \"confirmbutton\" class='btn btn-info' type='submit' value='Confirm Changes' onClick=\"checkConfig(rowcounthidden.value)\">" + 
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

function AddSubmit(mycount, addsub_options_string, myid){
  console.log("now in AddSubmit");

  

   if (typeof myid == 'undefined') { // If selecting a dropdown menu add the cofirm button but dont check the IP is valid.
   addbutton.innerHTML = " <input  class=\"btn btn-info\" type=\"button\" value=\"Add an ip\" \
                             onClick=\"AddRowFunction(configtable," + mycount + ",\'" + addsub_options_string + "\');\"> " +
         "<input   id = \"confirmbutton\" class='btn btn-info' type='submit' value='Confirm Changes' onClick=\"checkConfig(rowcounthidden.value)\">" +
         "<br><br><br>"

  }

  else {

  var pattern_subnet = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/(3[0-2]?|2[0-9]?|1[0-9]?|[0-9])$/;
  var pattern = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;

   var ip = document.getElementById(myid);

           if (pattern.test(ip.value)) {

                addbutton.innerHTML = " <input  class=\"btn btn-info\" type=\"button\" value=\"Add an ip\" \
                                        onClick=\"AddRowFunction(configtable," + mycount + ",\'" + addsub_options_string + "\');\"> " +
                    "<input  id = \"confirmbutton\" class='btn btn-info' type='submit' value='Confirm Changes' onClick=\"checkConfig(rowcounthidden.value)\">" +
                    "<br><br><br>"
                    return (true)
            }
                 
            else if ( pattern_subnet.test(ip.value)) {

                if (check_subnet(ip.value))  {
                       addbutton.innerHTML = " <input  class=\"btn btn-info\" type=\"button\" value=\"Add an ip\" \
                                      onClick=\"AddRowFunction(configtable," + mycount + ",\'" + addsub_options_string + "\');\"> " +
                        "<input  id = \"confirmbutton\" class='btn btn-info' type='submit' value='Confirm Changes' onClick=\"checkConfig(rowcounthidden.value)\">" +
                        "<br><br><br>"
                         return (true)

                }
                else {
                        if (typeof(confirmbutton) != 'undefined'){ addbutton.removeChild(confirmbutton); }
//kb
                         alert(ip.value + " is not a valid IP address / subnet combination.")
                         return (false)
                }
            }
          

          else {
            if (typeof(confirmbutton) != 'undefined'){ addbutton.removeChild(confirmbutton); }
               //alert("You have entered an invalid IP address!")
//kb
               alert(ip.value + " is not a valid IP address")

                return (false)
         }

 } // end of else

}



// Check an IP address is valid
//http://www.w3resource.com/javascript/form/ip-address-validation.php
function ValidateIPaddress(myid, myname) {
  console.log("now in ValidateIPaddress");
  var ip = document.getElementById(myid);

    
      var pattern_subnet = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/(3[0-2]?|2[0-9]?|1[0-9]?|[0-9])$/;
      var pattern = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/;

      if (pattern.test(ip.value))  {      

           if ( typeof(confirmbutton) == 'undefined') {
              addbutton.innerHTML = addbutton.innerHTML +  
                    "<input  id = \"confirmbutton\" class='btn btn-info' type='submit' value='Confirm Changes' onClick=\"checkConfig(rowcounthidden.value)\">"
           }
              return (true)
      }


      else if (pattern_subnet.test(ip.value)) {    

            if (check_subnet(ip.value)) {

               if ( typeof(confirmbutton) == 'undefined') {
                  addbutton.innerHTML = addbutton.innerHTML +  
                        "<input  id = \"confirmbutton\" class='btn btn-info' type='submit' value='Confirm Changes' onClick=\"checkConfig(rowcounthidden.value)\">"
                   }
                return (true)
             }

            else { 
                 document.getElementById(myid).outerHTML = "<input id = \"" + myid + "\" name = \"" + myname + "\"  " +
                             " type='text' placeholder='INVALID IP/SUBNET' " +
                            "onfocusout=\"return ValidateIPaddress('" + myid + "')\"  >";

                if (typeof(confirmbutton) != 'undefined'){ addbutton.removeChild(confirmbutton); }
                 alert(ip.value + " is not a valid IP address / subnet combination.")
                 return (false)
            }
       }

      else {

            document.getElementById(myid).outerHTML = "<input id = \"" + myid + "\" name = \"" + myname + "\"  " +
                         " type='text' placeholder='INVALID IP' " +
                        "onfocusout=\"return ValidateIPaddress('" + myid + "')\"  >";

          if (typeof(confirmbutton) != 'undefined'){ addbutton.removeChild(confirmbutton); }
              alert(ip.value + " is not a valid IP address.")
              return (false)

      } 
}


function check_subnet (ip_string){
        console.log("now in check_subnet");

      //var ip_string = "192.168.72.128/25";
      var error = 0
      var ip2 = ip_string.split("/");
      var ip = ip2[0];
      var subnet = ip2[1];

      if (subnet > 32){ return(false)}

      var mask = subnet % 8 // % is modulo (remainder);
      var mask_inv = 8 - mask;
      var subnet_mask = 256 - Math.pow(2,mask_inv);

      var test_octet = Math.floor(subnet/8);
      var bytes = ip.split(".");
      var octet = bytes[Math.floor(subnet/8)]

      for (i = 0; i < 4; i++) { 
       
         if (i < test_octet ){
            
            var test_var = bytes[i]|255
            if (test_var > 255){
                error = 1;
            }
         }

         else if (i == test_octet ) {
          
          var test_var = bytes[i]|subnet_mask
          if (test_var > subnet_mask){
              error = 1;

            }
         }

         else if (i > test_octet ) {
        
              if (bytes[i] != 0){
                error = 1;

              }
         }
      }

      if (error) {
         return(false);
      }
      else  return(true);
}


</script>	
EOF


############# Main Page #######################
#echo "<h3>Current Configurations</h3>"

#### Print out the ip table for the selected config ######
ip_table="/etc/custom/ips.table"
ip_table1="/etc/custom/ips.table1"
ip_table_previous="/etc/custom/ips.table.previous"
df_del="/etc/custom/default_gw.txt"

debug=0


 if [ "$WEBIF_PERMS" == "rw"  ] ##  If user has permisssion do stuff. ##
  then
  

    ## if the Confirm Changes Button has been clicked .... ######

    if [ $FORM_submit -eq 1 ] && ! [ $FORM_metric_update ] && ! [ $FORM_apply_config ]  && ! [ $FORM_defaultroute ]

     then

    [ $debug -eq 1 ] && echo "FORM_submit:  $FORM_submit<br>"
    [ $debug -eq 1 ] && echo "FORM_metric_update:  $FORM_metric_update<br>"
    [ $debug -eq 1 ] && echo "FORM_apply_config:  $FORM_apply_config<br>"
    [ $debug -eq 1 ] && echo "FORM_defaultroute:  $FORM_defaultroute<br>"


      # ## If you click no to "are you sure about default route" then remove it.###
      #  if [ "$FORM_defaultroute" == "no" ] 
      #   then
      #     sed -i 's/^.*0\.0\.0\.0.*$//' $ip_table
      #     unset FORM_defaultroute
      #     [ $debug -eq 1 ] && echo "Deleting default route<br>"
      #     [ $debug -eq 1 ] && echo "FORM_defaultroute:  $FORM_defaultroute<br>"

      #  fi

        [ $debug -eq 1 ] && echo "<p>Total row count is $FORM_rowcounttotal</p><br>"
          mv $ip_table1  /etc/custom/ip_table1.temp
          #mv $ip_table ip_table.temp
          rm /tmp/ip.log

        [ $debug -eq 1 ] && echo "<br>cat /etc/custom/ip_table1.temp<br>"
        [ $debug -eq 1 ] && cat  /etc/custom/ip_table1.temp |  awk '{print $0"<br>"'}
        [ $debug -eq 1 ] && echo "<br>"


        
          

           count=1
           total=$((FORM_rowcounttotal + 1))
            #echo "ip $FORM_ip1 has been added to $FORM_config1"

            ## Go through all $FORM_ip* and $FORM_config* variables
            ## Write these to the table. Write all entries even if they already exist.
            ## This take into account any entries that have been deleted.
            ## So in effect all get deleted and the ones still in the form are put back.
            while [ $count -le $total ]
            do
               ip=$(eval echo \$FORM_ip$count)
               ip=$(echo $ip | sed -r 's/\//-/g') ## change '/'s to '-'s.
               config=$(eval echo \$FORM_configid$count)
               
               [ $debug -eq 1 ] && echo "removing spaces from config"
               
               ### Replace Spaces in the config name with |'s'
               ### Spaces cause all sorts of problems so easier to get rid.
               config=$(echo $config | sed 's/ /|/g')
               [ $debug -eq 1 ] && echo "## config: $config<br>"

               [ $ip ] && [ $config ] && write_to_table $ip $config $ip_table $ip_table1
               [ $ip ] && [ ! $config ] && echo "No configuration selected for '$ip'<br>" && update_config=0
               [ $config ] && [ ! $ip ] && echo "No ip selected for '$config'<br>" && update_config=0


               [ $debug -eq 1 ] && echo "<p>$count:  ip: $ip  </p><br>"
               [ $debug -eq 1 ] && echo "<p>config: $config</p><br>"

               count=$((count + 1))
            done

            ## Keep a copy of the current table for comparing ip entrie against new ones.
            [ $debug -eq 1 ] && echo "cp $ip_table  $ip_table_previous<br>"
            cp $ip_table  $ip_table_previous      

            ### If the table is now empty table1 wont exist.
            ### This means a cp will fail and the main table wont
            ### get emptied. Therefore remove table and previsous table if no table1
            
            if [ -e $ip_table1 ]
               then
                [ $debug -eq 1 ] && echo "cp $ip_table1 $ip_table<br>"
                cp $ip_table1 $ip_table
              else rm $ip_table $ip_table_previous >& /dev/null
            fi
 
           
           [ $debug -eq 1 ] && echo "<br>cat /etc/custom/ips.table<br>"
           [ $debug -eq 1 ] && cat /etc/custom/ips.table 
            ## Check for any matching ipS.
            


            check_ips $ip_table $ip_table_previous
             ## If both files exists then check for ips with matching metrics in 
             ## the current table1 anyway as the tables can get out of sync
             ## and matching ips and metrics will get missed.
            [ $debug -eq 1 ] && echo "check_matching_metrics $readfile<br>"
            if check_matching_metrics $ip_table
               then
                  [ $debug -eq 1 ] && echo "cat /tmp/check_matching_metrics.tmp >> /tmp/matching_ips.txt<br>"
                   [ -e "/tmp/check_matching_metrics.tmp" ]  && cat /tmp/check_matching_metrics.tmp >> /tmp/matching_ips.txt
            fi

            if [ -e "/tmp/matching_ips.txt" ]
            
             then
                   metric_update_form "/tmp/matching_ips.txt" $ip_table

            else              

               ## Check to see if there are any default routes
               #if egrep '0.0.0.0' $ip_table >& /dev/null 
               #if  [ "$ip" == "0.0.0.0" ]
                
            
              rm -f $df_del >& /dev/null
              
              awk -vdf_del="$df_del" 'FNR==NR && /0\.0\.0\.0/{route[$2]++}
                    FNR!=NR && /0\.0\.0\.0/{route2[$2]++}

                    END { for (i in route) {
                           if (!route2[i]) {
                                print i > df_del}
                         }
                     }

                   ' $ip_table $ip_table_previous


               [ $debug -eq 1 ] && echo "Checking ip for defaut route: new_default = $new_default<br>"

            # if  [ !  -z $new_default ] 
              if  [ -e $df_del ]

                then
                 
                  check_default_route

                else
                   ### enter_ip 
                    update_button=1
                    create_table $ip_table
                    echo "<br>"
                    echo "<br><br>"
                    ## If the table doesnt exist then remove all routes from the configsmor 
                    [ -e $ip_table ] || remove_all_entries
                    cat /tmp/ip.log
                    unset FORM_submit


                        #####################  Save changes to the Vibe Config #################### 
                     if [  $update_config -eq 1 ] 
                      then
                            apply_and_reload $ip_table
                      fi

                         ##########################################################################
              fi
            fi

    ###############################################################################


    ### Defaut route. If  'No' is clicked in answer to "are you sure you want a default route"
    ### then remove the defalt route then carry on with the rest of the table update.

    elif [ -n "$FORM_defaultroute"   ]
        then
        [ $debug -eq 1 ] && echo "Checking default route<br>"
          if [ "$FORM_defaultroute" == "no" ]
           then
              while read conf
                do
                  echo "Removing default route for $conf<br><br>"
                  sed -i 's/^0\.0\.0.\0 $line.*$/d' $ip_table
              done  < $df_del
          fi



          update_button=1
          create_table $ip_table
          echo "<br>"
          echo "<br><br>"
          [ -e $ip_table ] || remove_all_entries
          cat /tmp/ip.log
          unset FORM_submit
          unset FORM_defaultroute

        [ $debug -eq 1 ] && echo "update_config = $update_config<br>"

                  apply_and_reload $ip_table
        



    ###################################################################################
    elif [ "$FORM_metric_update" == "updated" ]
      then
      [ $debug -eq 1 ] && echo "FORM_submit:  $FORM_submit<br>"
      [ $debug -eq 1 ] && echo "FORM_metric_update:  $FORM_metric_update<br>"
      [ $debug -eq 1 ] && echo "FORM_apply_config:  $FORM_apply_config<br>"
      [ $debug -eq 1 ] && echo "All updated"

      check_ips $ip_table $ip_table_previous  
      update_button=1  
      create_table $ip_table

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
                update_metrics $ip_table1 $ip_table_previous

                [ $debug -eq 1 ] && echo "From FORM_metric_update: check_matching_metrics $readfile<br>"
                   
                   ## /tmp/matching_ips.txt is genereated in check_ips. Used by metric_update_form
                   [ $debug -eq 1 ] && echo "deleting /tmp/matching_ips.txt<br>"
                   rm  /tmp/matching_ips.txt >& /dev/null

                   if check_matching_metrics $ip_table1
                    then
                     [ $debug -eq 1 ] && echo "cat /tmp/check_matching_metrics.tmp >> /tmp/matching_ips.txt<br>"
                     [ -e "/tmp/check_matching_metrics.tmp" ]  && cat /tmp/check_matching_metrics.tmp >> /tmp/matching_ips.txt
                     [ -e "/tmp/matching_ips.txt" ] && {
                       sort -u  /tmp/matching_ips.txt > /tmp/get_ips2.txt
                       mv /tmp/get_ips2.txt /tmp/matching_ips.txt || echo "mv /tmp/get_ips2.txt /tmp/matching_ips.txt failed<br>"
                     }
                   
                   fi


                   if [ -e "/tmp/matching_ips.txt" ] 
                    then
                     metric_update_form "/tmp/matching_ips.txt" $ip_table1

                   else
                      cp $ip_table $ip_table_previous
                      cp $ip_table1 $ip_table
                      ##echo "<p>Route order has been set.</p><br><button type=\"submit\" name=\"metric_update\" value=\"updated\"><b>Return to ip table</b> </button><br>"
                      [ $debug -eq 1 ] && echo "##Return to table button removed. check_ips then Apply config changes instead##"
                      check_ips $ip_table $ip_table_previous
                      
                         ### Check if there are  any default routes #### 
                        rm -f $df_del >& /dev/null
                        
                        awk -vdf_del="$df_del" 'FNR==NR && /0\.0\.0\.0/{route[$2]++}
                              FNR!=NR && /0\.0\.0\.0/{route2[$2]++}

                              END { for (i in route) {
                                     if (!route2[i]) {
                                          print i > df_del}
                                   }
                               }

                             ' $ip_table $ip_table_previous


                         [ $debug -eq 1 ] && echo "Checking ip for defaut route: new_default<br>"

                      # if  [ !  -z $new_default ] 
                        if  [ -e $df_del ]

                          then
                 
                            check_default_route

                         else  apply_and_reload $ip_table "return_to_table"
                        fi

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

        ##apply_config_changes $ip_table
        if apply_config_changes $ip_table
           then 
           [ $debug -eq 1 ] && echo "Reloading configuration"
            /etc/init.d/vibe reload
             echo "Configurations updated<br><br>"
             echo "<button type='submit' name='apply_config' value='apply_config_back'><b>Return to ip table</b></button><br>"

         else echo "Error Cant reload Configs"
              echo "<button type='submit' name='apply_config' value='apply_config_back'><b>Back</b></button><br>"

        fi

        update_button=0
    
    ###################################################################################
    else ## If form not submited and no metrics to update then print the table

      [ $debug -eq 1 ] && echo "FORM_submit:  $FORM_submit<br>"
      [ $debug -eq 1 ] && echo "FORM_metric_update:  $FORM_metric_update<br>"
      [ $debug -eq 1 ] && echo "FORM_apply_config:  $FORM_apply_config<br>"

          #enter_ip
           create_table $ip_table
           [ -e $ip_table ] || remove_all_entries   ## print the current table. echo "<br>"
          echo "<br><br>"
          unset $FORM_metric_update

    fi
    echo "</form>"

else echo "<h2>Permission Denied</h2>"
fi ## End of if $WEBIF_PERMS

 ?>

 <!--
##WEBIF:name:Acceleration:311:Add IPs
-->

