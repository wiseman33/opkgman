#!/bin/ash

upgrade () {
	opkg update
	packages=$( opkg list-upgradable | cut -f1 -d ' ' )
	if [ -z "$packages" ]; 	then
		echo -e "\nNothing to upgrade: $packages"
		return
	fi

	for package in $packages 
	do
		echo -e "\nUpgrading $package ..."
		opkg upgrade $package
	done
}

adblock () {
	/etc/init.d/adblock reload
	/etc/init.d/dnsmasq restart
}

printinfo() {
	# $1 - package's name
	# $2 - when package was installed
	# $3 - package's version
	# $4 - package's size
	# $5 - package dependens on
	# $6 - package is dependency for
	# @ - space filled column
	# - - dash filled column
	printf "\n"

	local i=1
	for param in $@; do
		if [ "$param" = "@" ]; then
			if [ "$i" -eq 1 ] || [ "$i" -eq 2 ]  || [ "$i" -eq 5 ] || [ "$i" -eq 6 ]; then
				# width 30
				printf "%-30s|" "                              "
			elif [ "$i" -eq 3 ]; then
				# width 50
				printf "%-50s|" "                                                  "
			elif [ "$i" -eq 4 ]; then
				# width 10
				printf "%-10s|" "          "
			fi 
		else
			if [ "$param" = "-" ]; then
				if [ "$i" -eq 1 ] || [ "$i" -eq 2 ] || [ "$i" -eq 5 ] || [ "$i" -eq 6 ]; then    
                                	# width 30                              
                                	printf "%-30s|" "------------------------------"                
                        	elif [ "$i" -eq 3 ]; then                          
                                	# width 50                              
                                	printf "%-50s|" "--------------------------------------------------"                
                        	elif [ "$i" -eq 4 ]; then      
                                	# width 10                              
                                	printf "%-10s|" "----------"                
	                        fi 
			else
				if [ "$i" -eq 1 ] || [ "$i" -eq 2 ] || [ "$i" -eq 5 ] || [ "$i" -eq 6 ]; then    
                           		# width 30                              
                                	printf "%-30s|" "$param"                
 		                elif [ "$i" -eq 3 ]; then                          
                                	# width 50                              
                                	printf "%-50s|" "$param"                
                        	elif [ "$i" -eq 4 ]; then                         
                                	# width 10                              
                                	printf "%-10s|" "$param"                
                        	fi 			
			fi
		fi

		i=$((i + 1))
	done
}

information () {
	all_packages=$( opkg list-installed | cut -f1 -d ' ' )

	printinfo "-" "-" "-" "-" "-" "-"
	printinfo "Name" "Installed" "Version" "Size" "Depends" "Dependecy"
	printinfo "-" "-" "-" "-" "-" "-"

	for package in $all_packages
	do
		VERSION="@"
		SIZE="@"
		INSTALLED="@"

		IFS='
'
		set -f
		for line in $(opkg info $package); do
			case $line in
				*Version:*)
  					VERSION=$( echo $line | cut -f2 -d ' ' )
					;;
				*Size:*)
					SIZE=$( echo $line | cut -f2 -d ' ' )
					;;
				*Installed-Time:*)
					INSTALLED=$( echo $line | cut -f2 -d ' ' | xargs date "+%Y-%m-%d/%H:%M:%S")
			esac
		done
		deps=$( opkg depends $package | tail +2 | cut -f1 -d ' ' )
		whatdeps=$( opkg whatdepends $package | tail +4 | cut -f1 -d ' ' )
		
		set +f
		unset IFS

		first=1
		
		while [ ! -z "$deps" ] || [ ! -z "$whatdeps" ]; do
			dep=$(echo -ne "$deps" | head -n 1)
			wdep=$(echo -ne "$whatdeps" | head -n 1)
			
			if [ "$first" -eq 1 ]; then
				if [ ! -z "$dep" ] && [ ! -z "$wdep" ]; then                                                                                                             
                                	printinfo "$package" "$INSTALLED" "$VERSION" "$SIZE" "$dep" "$wdep"                                                                                                             
                        	elif [ -z "$dep" ]; then                                                                                                                                 
                                	printinfo "$package" "$INSTALLED" "$VERSION" "$SIZE" "@" "$wdep"                                                                                                                
                        	elif [ -z "$wdep" ]; then                                                                                                                                
                                	printinfo "$package" "$INSTALLED" "$VERSION" "$SIZE" "$dep" "@"                                                                                                                 
                        	fi 
				
				first=0
			else
				if [ ! -z "$dep" ] && [ ! -z "$wdep" ]; then
					printinfo "@" "@" "@" "@" "$dep" "$wdep"
				elif [ -z "$dep" ]; then
					printinfo "@" "@" "@" "@" "@" "$wdep"
				elif [ -z "$wdep" ]; then
					printinfo "@" "@" "@" "@" "$dep" "@"
				fi
			fi

			deps=$(echo -ne "$deps" | tail +2)
			whatdeps=$(echo -ne "$whatdeps" | tail +2)
		done 		

		printinfo "-" "-" "-" "-" "-" "-"
	done

	echo -ne "\n"
}

if [ $# -eq 0 ] || [ $# -gt 1 ] 
then
	echo 'Usage:'
	echo '	upgrade - to upgrade all packages'
	echo '	info - to print all packages info'
	echo '	noads - to reload adblock lists'
else
	case $1 in
		upgrade) 
			echo 'Upgrading...'
			upgrade
			;;
		info)
			information
			;;
		noads)
			adblock
			;;
	esac
fi
