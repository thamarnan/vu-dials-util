# 
# Utility to control streacom vu dial from console
# Author: Roderick
# Updated: jan 2024 with v0 api
# Requirement: whiptail, wget, curl, jq


#-----------------------------
# user parameter
#-----------------------------
url="http://localhost:5340"
apikey=enteryourapikeyhere1234
#-----------------------------

tmp_json_file="tmp_vudialjson.txt"
cmd_preview_pause=1

while :; do

    FULLURL="$url/api/v0/dial/list?key=$apikey"
    wget -O- -q "$FULLURL" > tmp_vudialjson.txt
    mapfile -t uid_list < <(cat tmp_vudialjson.txt | jq -r '.data[].uid' )
    mapfile -t dial_name < <(cat tmp_vudialjson.txt | jq -r '.data[].dial_name')
    choices=();
    for key in "${!uid_list[@]}";
    do
         choices+=("$key" "${uid_list[$key]} ${dial_name[$key]}");
    done;

    choices+=("a" "All Dials")

    uid_choice=$(
      whiptail --title "Streacom VU-DIAL Utilities"  --menu "Select VU-Dial devices:" 15 55 5 \
    	"${choices[@]}" \
        	3>&1 1>&2 2>&3 3>&- # Swap stdout with stderr to capture returned dialog text
    )
    if [ $? -eq 0 ]; then
      echo "---"
    else
      echo "exit"
      break
      exit
    fi

    if  [[ $uid_choice == "a" ]] ; then
	a_menu=$(
      	whiptail --title "Control All VU Dial" --menu "Select option to control all dials" 0 0 0 \
        "1" "Broadcast Value to All Dial" \
        "2" "Identify Dials" \
        "3" "Update backlights RGB" \
        "4" "Update backlights Preset" \
        "5" "Simulate Zero to 100 Step" \
	"6" "Simulate Zero 100 to 0 Sweep" \
	"7" "Simulate Random Gauge" \
        3>&1 1>&2 2>&3 3>&-
    	)
    	case "$a_menu" in
	1) echo  "Broadcast Value to All Dial"
		#tbd
		;;
	2) echo "Identify Dials"
		#tbd
		;;
	4) echo "Update backlights preset"

		presetcolor=$(
            whiptail --title "select update menu" --menu "${data}" 0 0 0 \
            "red=0&green=0&blue=0"       " Off" \
            "red=20&green=0&blue=0"      " RED 20"\
            "red=100&green=0&blue=0"     " RED 100" \
            "red=0&green=20&blue=0"      " GREEN 20" \
            "red=0&green=100&blue=0"     " GREEN 100" \
            "red=0&green=0&blue=20"      " BLUE 20" \
            "red=0&green=0&blue=100"     " BLUE 100" \
            "red=5&green=5&blue=5"       " WHITE 5" \
            "red=20&green=20&blue=20"    " WHITE 20" \
            "red=100&green=100&blue=100" " WHITE 100" \
            "red=20&green=5&blue=0"    " AMBER 20" \
            "red=100&green=50&blue=0"     " AMBER 100"\
            3>&1 1>&2 2>&3 3>&-
         )
        if [ $? -eq 0 ]; then
		for i in "${!uid_list[@]}";
                do
			        FULLURL="$url/api/v0/dial/${uid_list[$i]}/backlight?key=$apikey&$presetcolor"
            			echo $FULLURL
            			wget -O- -q "$FULLURL"; echo ""
				sleep 0.5
		done
	fi
	;;
	5) echo "Simulate Zero to 100 Step"
		
	   for j in `seq 0 10 100`; do

		for i in "${!uid_list[@]}";
    		do
			inputVal=${j}
         		echo "$j $i" "${uid_list[$i]} ${dial_name[$i]}";
  			FULLURL="$url/api/v0/dial/${uid_list[$i]}/set?key=$apikey&value=$inputVal"
        		echo $FULLURL
        		wget -O- -q "$FULLURL";echo ""
		done
		sleep 5
	   done
		;;

	6) echo "Simulate 100 to 0 sweep"
		echo "...Set all to value 100"
		for i in "${!uid_list[@]}";
                do
                        inputVal=${j}
                        echo "$j $i" "${uid_list[$i]} ${dial_name[$i]}";
                        FULLURL="$url/api/v0/dial/${uid_list[$i]}/set?key=$apikey&value=100"
                        echo $FULLURL
                        wget -O- -q "$FULLURL";echo ""
                done	  
		
		echo "wait 10s for needle to rest"
		sleep 10

		for ((j=100;j>0;j-=2)) ; do

                for i in "${!uid_list[@]}";
                do
                        inputVal=${j}
                        echo "$j $i" "${uid_list[$i]} ${dial_name[$i]}";
                        FULLURL="$url/api/v0/dial/${uid_list[$i]}/set?key=$apikey&value=$inputVal"
                        echo $FULLURL
                        wget -O- -q "$FULLURL";echo ""
			sleep 0.3
                done
                sleep 0.3
        

	   	done
		;;
	7) echo "Random value"
		for i in "${!uid_list[@]}";
                do
                        inputVal=$(( ( RANDOM % 100 )  + 1 ))
                        echo "$inputVal" "${uid_list[$i]} ${dial_name[$i]}";
                        FULLURL="$url/api/v0/dial/${uid_list[$i]}/set?key=$apikey&value=$inputVal"
                        echo $FULLURL
                        wget -O- -q "$FULLURL";echo ""
                        sleep 0.2
                done
	esac
	
    else
	# if choice is a number, one of the device select 
    	data=`cat tmp_vudialjson.txt | jq --arg uid_choice $uid_choice ' .data[$ARGS.named.uid_choice|tonumber]'`
    	uid=`cat tmp_vudialjson.txt | jq -r --arg uid_choice $uid_choice ' .data[$ARGS.named.uid_choice|tonumber].uid'`
    	#echo $data

    

    update_dial_choice=$(
      whiptail --title "select update menu" --menu "${data}" 0 0 0 \
    	"1" "Update dial_name" \
    	"2" "Update value" \
    	"3" "Update backlight RGB" \
    	"4" "Update backlight preset" \
    	"5" "Update image" \
    	3>&1 1>&2 2>&3 3>&-
    )

    case "$update_dial_choice" in
    1) 
        echo "Update dial_name"

        inputVal=$(whiptail --inputbox "Enter Value" 8 39  3>&1 1>&2 2>&3)
        FULLURL="$url/api/v0/dial/$uid/name?key=$apikey&name=${inputVal}"
        echo $FULLURL
        wget -O- -q "$FULLURL";echo ""
        sleep 1
        ;;
    2) 
        echo "Update value"
        inputVal=$(whiptail --inputbox "Enter Value" 8 39  3>&1 1>&2 2>&3)
        FULLURL="$url/api/v0/dial/$uid/set?key=$apikey&value=$inputVal"
        echo $FULLURL
        wget -O- -q "$FULLURL";echo ""
        sleep 1
        ;;
    3)
        echo "Update backlight"
        redVal=$(whiptail --inputbox "Enter RED" 8 39  3>&1 1>&2 2>&3)
        greenVal=$(whiptail --inputbox "Enter GREEN" 8 39  3>&1 1>&2 2>&3)
        blueVal=$(whiptail --inputbox "Enter BLUE" 8 39  3>&1 1>&2 2>&3)

        FULLURL="$url/api/v0/dial/$uid/backlight?key=$apikey&red=$redVal&green=$greenVal&blue=$blueVal"
        echo $FULLURL
        wget -O- -q "$FULLURL";echo ""

        sleep 1
        ;;

    4)
        echo "Update backlight preset"
        presetcolor=$(
            whiptail --title "select update menu" --menu "${data}" 0 0 0 \
            "red=0&green=0&blue=0"       " Off" \
	    "red=20&green=0&blue=0"      " RED 20"\
            "red=100&green=0&blue=0"     " RED 100" \
	    "red=0&green=20&blue=0"      " GREEN 20" \
            "red=0&green=100&blue=0"     " GREEN 100" \
	    "red=0&green=0&blue=20"      " BLUE 20" \
            "red=0&green=0&blue=100"     " BLUE 100" \
	    "red=5&green=5&blue=5"       " WHITE 5" \
	    "red=20&green=20&blue=20"	 " WHITE 20" \
            "red=100&green=100&blue=100" " WHITE 100" \
            "red=20&green=5&blue=0"    " AMBER 20" \
	    "red=100&green=50&blue=0"     " AMBER 100"\
            3>&1 1>&2 2>&3 3>&-
         )
        if [ $? -eq 0 ]; then
            FULLURL="$url/api/v0/dial/$uid/backlight?key=$apikey&$presetcolor"
            echo $FULLURL
            wget -O- -q "$FULLURL"; echo ""

            sleep 1
            fi
        ;;
    5)
    	echo "Update image"
    	upfilename=$(whiptail --inputbox "Enter full filename" 8 39  3>&1 1>&2 2>&3)
        if [ $? -eq 0 ]; then
            FULLURL="$url/api/v0/dial/$uid/image/set?key=$apikey&imgfile=$upfilename"
            echo $FULLURL
            curl -F "imgfile=@$upfilename" "$FULLURL"
            sleep 1
        fi
    	;;

    esac

    fi

done
