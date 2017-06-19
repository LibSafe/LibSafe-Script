#!/bin/bash

# LibSafe

# Links
# * Array from `find` > https://stackoverflow.com/questions/23356779/how-can-i-store-find-command-result-as-arrays-in-bash

## Return
FOLDER=$1
RETURN=0
PROTOCOL_REGEX="/(?<=\@protocol).*?([a-zA-Z0-9_-][a-zA-Z0-9_-]*)(?=\s*:)/g"
INTERFACE_REGEX="/(?<=\@interface).*?([a-zA-Z0-9_-][a-zA-Z0-9_-]*)(?=\s*:)/g"
LIBSAFE_HEADER_FILE=""

if [ -z "$FOLDER" ]; then
    echo "No argument supplied"
    echo "Usage: $ ./LibSafe.sh folder-to-make-lib-safe"
    exit -1
fi

function randomString() 
{
	RETURN=`cat /dev/random | LC_CTYPE=C tr -dc "[:alpha:]" | head -c 16`
}

function forEach() # $1 array, $2 function to apply an element of the array to $3-$6 extra args to pass to $2
{
	ARR=("${!1}")
	FUNC=$2
	RESULT=()

	## now loop through the array
	for i in "${ARR[@]}"
	do
		## Call function $2 with current array element as argument.
		$FUNC "${i}" $3 $4 $5 $6; RESULT+=("${RETURN[@]}")
	done

	RETURN=("${RESULT[@]}");
}

function findLibSafeHeader()
{
	## Tried using $RETURN variable here but if was not working outside the scope of the method?!
	LIBSAFE_HEADER_FILE="$(find ${FOLDER} -type f -name 'LibSafe-Header.h')"
}

function getAllHeaderFiles() 
{
	ARRAY=()
	while IFS=  read -r -d $'\0'; do
	    ARRAY+=("$REPLY")
	done < <(find ${FOLDER} -type f -name $'*.h' -print0)
	RETURN=("${ARRAY[@]}")
}

function getAllImplementationFiles() 
{
	ARRAY=()
	while IFS=  read -r -d $'\0'; do
	    ARRAY+=("$REPLY")
	done < <(find ${FOLDER} -type f -name $'*.m' -print0)
	RETURN=("${ARRAY[@]}")
}

function getAllObjectiveCFiles()
{	
	getAllHeaderFiles; HEADERS=("${RETURN[@]}")
	getAllImplementationFiles; IMPLEMENTATIONS=("${RETURN[@]}")
	RETURN=("${HEADERS[@]}" "${IMPLEMENTATIONS[@]}") # Combine the arrays
}

function getProtocolsInFile() # $1 file
{
	#RESULTS=("CASSampleProtocol" "CASSampleProtocol2")
	RESULTS=(`cat "${1}" | perl -wnE'say for /(?<=\@protocol).*?([a-zA-Z0-9_-][a-zA-Z0-9_-]*)(?=\s*<)/g'`)
	# | grep -oP "$PROTOCOL_REGEX"`)
	echo "Found the following protocols: ${RESULTS[@]}"
	RETURN=("${RESULTS[@]}")
}

function getInterfacesInFile() # $1 file
{
	RESULTS=(`cat "${1}" | perl -wnE'say for /(?<=\@interface).*?([a-zA-Z0-9_-][a-zA-Z0-9_-]*)(?=\s*:)/g'`)
	echo "Found the following interfaces: ${RESULTS[@]}"
	RETURN=("${RESULTS[@]}")
}

function scopeProtocolsAndInterfacesInFile() # $1 file, $2 scope 
{
	echo -e "\n\nProcessing file: '$1'"

	echo -e "\nRemoving any existing LibSafe defines from file...\n"
	sed -i "" '/\/\* LibSafe definition START \*\//,/\/\* LibSafe definition END \*\//d' "${1}"

	# Add LibSafe define wrapper
	#sed -i -e '1i\/* LibSafe definition START */\n/* LibSafe */' $1


	## Get all protocol names `...@protocol _ANY_ :...` in $1 (file)
	## Avoid rescoping protocol extensions `@protocol _ANY_ ()`
	getProtocolsInFile "${1}"; PROTOCOLS=("${RETURN[@]}")
	getInterfacesInFile "${1}"; INTERFACES=("${RETURN[@]}")

	PROTOCOLS_AND_INTERFACES=("${PROTOCOLS[@]}" "${INTERFACES[@]}")
	DEFINES=()
	TOP_INSERT="/* LibSafe definition START */

/**
 *  LibSafe adds defines to your classes with random names so that your code 
 *  can be imported multiple times without symbol conflicts.
 *
 *  Thanks to LibSafe and the generated defines below you can use this class 
 *  in your closed source library even if someone else has included the same 
 *  exact class.
 *
 *  Read more at: https://github.io/libsafe
 */
"
	echo ""
	## Append the $2 (scope) to the end of the protocol name
	for i in "${PROTOCOLS_AND_INTERFACES[@]}"
	do
		## Append the 
		DEFINE_STRING="#define ${i} ${i}${2}"
		DEFINES+=($DEFINE_STRING)
		## Add a #define for each protocol `#define _ORIGINAL_NAME_ _SCOPED_NAME_` to top of $1 (file)
		echo -e "Add define string: \n'${DEFINE_STRING}'"

		## Insert the define string at the top of the file
		# sed -i -e "2i\ 
		# ${DEFINE_STRING}
		# " $1
		TOP_INSERT+="${DEFINE_STRING}\n"
	done

	TOP_INSERT+="\n/* LibSafe definition END */\n"

	## Write to file if we have defines
	if ! [ ${#DEFINES[@]} -eq 0 ]; then
		echo -e "${TOP_INSERT}$(cat "${1}")" > "${1}"
	fi

	RETURN=("${DEFINES[@]}");
}

function replaceLibSafeHeader() 
{	
	## Do not continue if no header file as $1
	if [ -z "$LIBSAFE_HEADER_FILE" ]; then
		return 0
	fi

	## We have the header, replace the contents with generated content
	echo ""
	echo "Found LibSafe-Header.h"
	echo "Replacing contents in LibSafe Header... (${LIBSAFE_HEADER_FILE})"
	HEADER_CONTENT="/* LibSafe Auto Generated Header */

/**
 *  LibSafe adds defines to your classes with random names so that your code 
 *  can be imported multiple times without symbol conflicts.
 *
 *  Thanks to LibSafe and the generated defines below you can use this class 
 *  in your closed source library even if someone else has included the same 
 *  exact class.
 *
 *  Read more at: https://github.io/libsafe
 */

 /**
  *  The unique random string used to scope your classes. 
  *  
  *  You can use this define to scope your folder/file names when you write 
  *  to disk to make sure you are not conflicting with other implementations 
  *  of the same (your) code.
  */
 #define LIBSAFE_RANDOM @\"${RANDOM_STRING}\"
"
	echo -e "${HEADER_CONTENT}" > "${LIBSAFE_HEADER_FILE}"
}

randomString; RANDOM_STRING="${RETURN}"
echo "Generated random scope string to use: ${RANDOM_STRING}"

getAllObjectiveCFiles; FILES=("${RETURN[@]}")
echo "Number of files to scope: ${#FILES[@]}"

# Print all files on separate lines
printf '%s\n' "${FILES[@]}"


## Scope the name of all protocols and interfaces in all files
forEach FILES[@] scopeProtocolsAndInterfacesInFile "_libsafe_${RANDOM_STRING}"; RESULT=("${RETURN[@]}")

## Get LibSafe Header
findLibSafeHeader

## Write to the LibSafe Header
replaceLibSafeHeader


echo -e "\n\nDone!"

