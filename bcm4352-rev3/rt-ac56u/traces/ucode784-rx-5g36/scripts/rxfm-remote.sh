# rxfm-remote.sh LO HI: every MMIO address 0x400-0x7FE (data ports and the TX status FIFO skipped) sampled with
# FRAMELEN (RB 0x418) before, through and after the mark (FRAMELEN = 6): pdtrace with history, 1500 samples each side, keeping the first capture whose FRAMELEN peaks in [LO, HI] (one
# frame of the PC's pings), up to 8 tries; "addr <hex> <max>" then the rows (max 0 = none caught)
LO=$1; HI=$2
P=$(iw dev | awk '/^phy#/ {p=$1} /ssid AC56U-5open/ {print p}' | tr -d '#'); D=/sys/kernel/debug/b43_next/$P
for a in $(seq $((0x400)) 2 $((0x7FE))); do
	h=$(printf 0x%03X $a)
	case $h in 0x422|0x432|0x518|0x51A|0x51C|0x51E|0x540|0x542|0x560|0x562) continue;; esac
	got=0
	for t in 1 2 3 4 5 6 7 8; do
		echo "3000 0x60000006 $h 0x0418" > $D/pdtrace 2>/dev/null
		cat $D/pdtrace > /tmp/rxfm-cur.txt
		m=$(awk '$1 != "trig" && $1 >= 1500 { v = sprintf("%d", "0x" $5); if (v + 0 > m) m = v + 0 } END { print m + 0 }' /tmp/rxfm-cur.txt)
		if [ $m -ge $LO ] && [ $m -le $HI ]; then got=$m; break; fi
	done
	echo "addr $h $got"; [ $got -gt 0 ] && grep -v trig /tmp/rxfm-cur.txt
done
