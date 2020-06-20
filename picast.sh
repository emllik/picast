in="in"
rm $in
mkfifo $in

host=pi@192.168.3.13
id=666

echo "
    ssh        _____________
     |        |  YouTube    |
     |        |     -----   |
    rpi------>|_____________|
              _/           \_
 "

session='export DBUS_SESSION_BUS_ADDRESS=`cat "/tmp/omxplayerdbus.${USER:-root}"` && export DBUS_SESSION_BUS_PID=`cat "/tmp/omxplayerdbus.${USER:-root}.pid"` '

pause="echo '$session && dbus-send --print-reply=literal --session --dest=org.mpris.MediaPlayer2.omxplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Action int32:16 >/dev/null' > $in"
prev="echo '$session && dbus-send --print-reply=literal --session --dest=org.mpris.MediaPlayer2.omxplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Seek int64:-30000000 >/dev/null' > $in"
next="echo '$session && dbus-send --print-reply=literal --session --dest=org.mpris.MediaPlayer2.omxplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Seek int64:30000000 >/dev/null' > $in"
stop="echo '$session && dbus-send --print-reply=literal --session --dest=org.mpris.MediaPlayer2.omxplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Action int32:15 >/dev/null' > $in"

notification () 
{ 
termux-notification --button1 '<' --button1-action "$prev" --button2 '||' --button2-action "$pause" --button3 '>' --button3-action "$next" --title "$1" --on-delete "$stop" --id $id --type="media" 
}

#++++++++
echo Connecting 
ssh $host 'while read line; do bash -c "$line"; done' <$in &
exec 3>$in

#++++++++
if [ "$1" ]; then
    echo Getting a direct link
      f=$(echo "$1" | rev | cut -d '.' -f1 | rev)
      if [ "$f" = "mp4" ] || [ "$f" = "m3u8" ] || [ "$f" = "mkv" ]
      then
          url="$1"
      else
          data=$(youtube-dl --get-title -g -f 'best[height<=720]' $1)
          title=$(echo "$data" | grep -v http)
          url=$(echo "$data" | grep http)
      fi
#+++++++++
    echo Starting
    if [ "$url" != "" ]; then 
        echo 'if [ "$(pgrep omxplayer)" ]; then '$session' && dbus-send --print-reply=literal --session --dest=org.mpris.MediaPlayer2.omxplayer /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.OpenUri string:"'$url'" >/dev/null ; echo ok; else nohup omxplayer "'$url'" ; fi &' >$in
    else 
        echo "Link not supported"
    fi
fi

if [ "$title" ]
  then notification "$title"
  else notification "Raspberry cast"
fi

wait
termux-notification-remove $id
