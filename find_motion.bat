del hosts
for /F "tokens=1 delims=: " %%V in (list2) do nbtstat -a %%V >> hosts grep "MOT" hosts > motion.txt
