C=0
touch tmp
while IFS= read -r line
do
  if [[ $line == "---" && "$C" -eq 0 ]]; then
      ((C++))
      line="<pre>"
  fi
    if [[ $line == "---" && "$C" -eq 1 ]]; then
        ((C++))
        line="</pre>"
    fi
  echo "$line" >> tmp
done < "$1"

mv tmp $1