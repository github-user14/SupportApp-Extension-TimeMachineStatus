#!/bin/zsh

# 2024-01-31: Tested with macOS Sonoma 14.3

# Support App Extension - Time Machine Status
#
# Support App Extension to get the Time Machine status and publish to Extension A.
# Must be run as root.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO
# EVENT SHALL I BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


# Variables

# Should be 2 or more! 0 or 1 breaks the script!
WARN_IF_BACKUP_OLDER_THAN_DAYS=7

TM_PLIST_FILE="/Library/Preferences/com.apple.TimeMachine.plist"

OUTPUT_WHILE_LOADING="Searching for a backup"
OUTPUT_TM_PLIST_DOES_NOT_EXIST="Error: TM.plist not found"
OUTPUT_TM_AUTO_BACKUP_DISABLED="Not configured!"
OUTPUT_TM_BACKUP_PENDING="Pending"
OUTPUT_TM_BACKUP_TODAY="Today"
OUTPUT_TM_BACKUP_YESTERDAY="Yesterday"
OUTPUT_TM_BACKUP_RUNNING="In progress..."
OUTPUT_UNKNOWN_ERROR="Unexpecteed Error!"
OUTPUT_BACKUP_VOLUME_DISCONNECTED="Drive not connected!"
OUTPUT_BACKUP_VOLUME_NOT_ENCRYPTED="Not encrypted!"
# OUTPUT_TM_BACKUP_AGE_IN_DAYS="vor $days_since_last_tm_backup Tagen" is configured within the script because otherwise the variable $days_since_last_tm_backup returns as empty!

# log file for troubleshooting
exec &> /Users/Shared/tm_status_log.txt


# Support App Configuration
# Start spinning indicator
defaults write /Library/Preferences/nl.root3.support.plist ExtensionLoadingA -bool true

# Show placeholder value while loading
defaults write /Library/Preferences/nl.root3.support.plist ExtensionValueA -string "$OUTPUT_WHILE_LOADING"

echo "Checking if the file $TM_PLIST_FILE exists..."
if [ -e "$TM_PLIST_FILE" ]; then
    echo "SUCCESS: File $TM_PLIST_FILE exists."
    
    # Read Time Machine AutoBackup status from the plist
	tm_auto_backup_enabled=$(defaults read "/Library/Preferences/com.apple.TimeMachine.plist" AutoBackup 2>/dev/null)
	echo "Variable tm_auto_backup_enabled: $tm_auto_backup_enabled"
			
	echo "Checking if AutoBackup is enabled..."
	if [ "$tm_auto_backup_enabled" = "1" ]; then				
		echo "SUCCESS: AutoBackup is enabled."				
		echo "Checking if a backup was ever completed..."
				
		# Reading the array of Time Machine SnapshotDates if "SnapshotDates" is found in the plist, and formating it as YYYY-MM-DD. Any error is ignored resulting in an empty variable
		if [[ -n $(defaults read /Library/Preferences/com.apple.TimeMachine.plist | grep SnapshotDates) ]]; then	
			last_tm_backup_date=$(defaults read /Library/Preferences/com.apple.TimeMachine.plist 2>/dev/null | grep -oE '2[0-9]{3}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \+0000' | awk -F ' ' '{print $1}' | sort -r | head -n 1)
			echo "Variable last_tm_backup_date: $last_tm_backup_date"	
		else
			echo "WARNING: No SnapshotDate found. Backup was never completed."
		fi
		
		#last_tm_backup_date=$(defaults read /Library/Preferences/com.apple.TimeMachine.plist | grep -oE '2[0-9]{3}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} \+0000' | awk -F ' ' '{print $1}' | sort -r | head -n 1)
		echo "Variable last_tm_backup_date: $last_tm_backup_date"
		
		echo "Checking if last_tm_backup_date is in a valid format (YYYY-MM-DD)..."				
		if [[ "$last_tm_backup_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then			
			echo "SUCCESS: last_tm_backup_date was found and is in the correct Format."
			
			# Backup encryption status
			tm_backup_encryption_status=$(defaults read "/Library/Preferences/com.apple.TimeMachine.plist" Destinations 2>/dev/null | grep -m1 LastKnownEncryptionState | awk '{print $3}' | tr -d '";' | awk -F';' '{print $1}')
			echo "Variable tm_backup_encryption_status: $tm_backup_encryption_status"
			
			# Last known backup volume
			tm_backup_last_known_volume=$(defaults read "/Library/Preferences/com.apple.TimeMachine.plist" Destinations 2>/dev/null | grep -m1 LastKnownVolumeName | sed 's/.* = "\(.*\)";/\1/')
			echo "Variable tm_backup_last_known_volume: $tm_backup_last_known_volume"
			
			echo "Calculating how many days ago the last_tm_backup_date is..."			
			days_since_last_tm_backup=$(( ($(date "+%s") - $(date -jf "%Y-%m-%d" "$last_tm_backup_date" "+%s")) / 86400 ))

			echo "Days since last backup: $days_since_last_tm_backup"		
				
# CONFIG	# Configure the OUTPUT_TM_BACKUP_AGE_IN_DAYS text here
			OUTPUT_TM_BACKUP_AGE_IN_DAYS="Vor $days_since_last_tm_backup Tagen"
			echo "Checking how long ago the backup was completed..."
			
			if [ "$days_since_last_tm_backup" -gt "$WARN_IF_BACKUP_OLDER_THAN_DAYS" ]; then
				echo "Backup is older than $WARN_IF_BACKUP_OLDER_THAN_DAYS days"
				output="$OUTPUT_TM_BACKUP_AGE_IN_DAYS"
				warn="true"
			elif [ "$days_since_last_tm_backup" -eq "1" ]; then
				echo "Backup completed 1 day ago (yesterday)"
				output="$OUTPUT_TM_BACKUP_YESTERDAY"
				warn="false"				
			elif [ "$days_since_last_tm_backup" -eq "0" ]; then			
				echo "Backup completed 0 days ago (today)"
				output="$OUTPUT_TM_BACKUP_TODAY"
				warn="false"				
			elif [[ "$days_since_last_tm_backup" =~ ^[0-9]+$ ]]; then
				echo "Backup completed $days_since_last_tm_backup days ago"
				output="$OUTPUT_TM_BACKUP_AGE_IN_DAYS"
				warn="false"				
			else
			# AutoBackup is enabled but something went wrong with the calculation of backup age	
			output="$OUTPUT_UNKNOWN_ERROR"
			warn="true"
			fi
		else
		    echo "WARNING: AutoBackup is enabled but last_tm_backup_date is not in a valid Format or does not exist."
		    output="$OUTPUT_TM_BACKUP_PENDING"
		    warn="true"
		fi
	else
		echo "WARNING: Time Machine AutoBackup is disabled"
		output="$OUTPUT_TM_AUTO_BACKUP_DISABLED"
		warn="true"	   
	fi   
else	
	echo "WARNING: TimeMachine.plist does not exist"
	output="$OUTPUT_TM_PLIST_DOES_NOT_EXIST"
	warn="true"    
fi


echo "Checking if the Time Machine Backup is currently running..."
tm_backup_active=$(tmutil status | awk -F'[=;]' '/Running/ {gsub(/ /, "", $2); print $2}')
echo "tm_backup_active: $tm_backup_active"

if [ "$tm_backup_active" = "1" ]; then
	
	echo "INFO: Backup is currently running"
	output="$output ($OUTPUT_TM_BACKUP_RUNNING)"	

else
	
	echo "Backup is not running."
	echo "Checking if the backup volume is connected..."
	if [ -e "/Volumes/${tm_backup_last_known_volume}" ] && [[ -n "$tm_backup_last_known_volume" ]]; then
	
		echo "SUCCESS: Backup volume is connected."
		
	elif [ "$tm_auto_backup_enabled" = "1" ] && [ ! -e "/Volumes/${tm_backup_last_known_volume}" ] && [[ -n "$tm_backup_last_known_volume" ]]; then
		
		echo "WARNING: Backup volume not connected!"
		output="$output ($OUTPUT_BACKUP_VOLUME_DISCONNECTED)"
		warn="true"
	
	fi
	
	# Stop spinning indicator after waiting 0.5 seconds
	sleep 0.5
	defaults write /Library/Preferences/nl.root3.support.plist ExtensionLoadingA -bool false
	
fi

echo "Checking if the backup volume is encrypted (if a backup was ever created)"
if [ ! "$tm_backup_encryption_status" = "Encrypted" ] && [[ "$last_tm_backup_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then

	echo "WARNING: Backup volume not encrypted! (Date: $last_tm_backup_date)" 
	output="$output ($OUTPUT_BACKUP_VOLUME_NOT_ENCRYPTED)"
	warn="true"

elif [ "$tm_backup_encryption_status" = "Encrypted" ] && [[ "$last_tm_backup_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
	
	echo "SUCCESS: Back is encrypted (Date: $last_tm_backup_date)"

elif [ ! "$tm_backup_encryption_status" = "Encrypted" ] && ! [[ "$last_tm_backup_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then

	echo "INFO: It appears that no backup was ever created"

else

fi

# Write output to Support App preference plist
defaults write /Library/Preferences/nl.root3.support.plist ExtensionValueA -string "$output"
echo "OUTPUT: $output"
		    
# Write warning (true/false) to Support App preference plist
defaults write /Library/Preferences/nl.root3.support.plist ExtensionAlertA -bool $warn	   
echo "WARN: $warn"
