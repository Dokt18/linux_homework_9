lockfile=/tmp/check_lock_file
if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; then
    trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT
else
    echo "Can't get file lock, $(basename "$0") already running" >&2
    exit 1
fi

#Get last start time
last_start=$(grep check.sh /var/log/syslog | tail -1 | cut -d ' ' -f 3)

echo "Previous start time is " >> mail.txt
echo $last_start >> mail.txt

file="/home/dok/Documents/otus/bash/access-4560-644067.log"

while read -r line; do
    time=$(echo "$line" | cut -d ' ' -f 4 | grep -o ':[0-9][0-9]:[0-9][0-9]:[0-9][0-9]' | sed 's/^://')
    if [[ "$time" > "$last_start" ]]; then
        echo "$line" >> tmp_file
    fi
done < $file

#Select Ips
echo -e "\nList of Ips" >> mail.txt
echo "Count  IP" >> mail.txt
echo "----------------" >> mail.txt
cut -d ' ' -f 1 tmp_file | sort | uniq -c | sort -nr | head | grep -oE '[0-9]+\s[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >> mail.txt
#Select endpoints
echo -e "\nList of endpoints" >> mail.txt
echo "Count  Endpoint" >> mail.txt
echo "----------------" >> mail.txt
cut -d ' ' -f 7 tmp_file | sed '/\//p' | sort | uniq -c | sort -nr | head | grep -oE '[0-9]+\s.*' >> mail.txt
#Select http codes
echo -e "\nList of http codes" >> mail.txt
echo "Count  Code" >> mail.txt
echo "----------------" >> mail.txt
grep -o ' [1-5][0-5][0-5] ' tmp_file | sort | uniq -c | sort -nr | head | grep -oE '[0-9]+\s.*' >> mail.txt

cat mail.txt | ssmtp dok18@proton.me

rm tmp_file
rm mail.txt
