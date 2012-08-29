for file in $(find . \( ! -name . -prune \) -name *.flo); do
 newname=`basename $file .flo`.pic
 LaTeXFloToPic $file > $newname 2>/dev/null
done

if [ -d flowCharts ]; then
 cd flowCharts
 for file in $(find . \( ! -name . -prune \) -name *.flo); do
  newname=`basename $file .flo`.pic
  LaTeXFloToPic $file > $newname 2>/dev/null
 done
fi
