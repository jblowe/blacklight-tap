while true; do
  nohup rails s -b 0.0.0.0 -p $1 >> server.log 2>&1
  echo "$(date): server crashed. Restarting in 5s..." >> server.log
  sleep 5
done

