## Leer archivos listados (`cat` masivo)
```bash
# Resultados paginados con less
$ find . -name ".bash_history" 2>/dev/null -exec cat {} + | less

# Saber de que archivo viene:
#	==> ./Sam/.bash_history <==
#	comando1
#	comando2
find . -name ".bash_history" 2>/dev/null -exec awk 'FNR==1{print "\n==> " FILENAME " <=="} {print}' {} +
```