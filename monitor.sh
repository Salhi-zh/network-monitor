#!/bin/bash

# Brilliant Network Monitor - Tool Driver
# Description: Monitors per-process & per-interface network throughput.

set -e

INTERFACE=${1:-$(ip route | grep default | awk '{print $5}' | head -n1)}
THRESHOLD_KB=5000
LOG_DIR="$HOME/network-monitor/logs"
CAPTURE_DIR="$HOME/network-monitor/captures"

mkdir -p "$LOG_DIR" "$CAPTURE_DIR"

echo "--------------------------------------------------"
echo "📡 Brilliant Network Monitor active on interface: $INTERFACE"
echo "⚠️  Alert threshold: ${THRESHOLD_KB} KB/s"
echo "--------------------------------------------------"

# Check for dependencies
check_dep() {
    if ! command -v "$1" &> /dev/null; then
        echo "⚠️  Warning: $1 is not installed. Some features will be disabled."
        return 1
    fi
    return 0
}

# Main Monitoring Loop
while true; do
    # 1. Get current throughput (simple /proc/net/dev parsing)
    R1=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes)
    T1=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes)
    sleep 1
    R2=$(cat /sys/class/net/"$INTERFACE"/statistics/rx_bytes)
    T2=$(cat /sys/class/net/"$INTERFACE"/statistics/tx_bytes)
    
    RX_KB=$(( (R2 - R1) / 1024 ))
    TX_KB=$(( (T2 - T1) / 1024 ))
    TOTAL=$(( RX_KB + TX_KB ))

    # Display status
    printf "\rCurrent Throughput: [RX: %d KB/s] [TX: %d KB/s] [Total: %d KB/s]   " "$RX_KB" "$TX_KB" "$TOTAL"

    # 2. Check threshold
    if [ "$TOTAL" -gt "$THRESHOLD_KB" ]; then
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        LOG_FILE="$LOG_DIR/alert_$TIMESTAMP.log"
        echo -e "\n🔥 THRESHOLD EXCEEDED ($TOTAL KB/s) at $TIMESTAMP" | tee -a "$LOG_FILE"
        
        # Log top processes if nethogs is available
        if check_dep nethogs; then
            echo "Capturing top processes..." >> "$LOG_FILE"
            # Run nethogs in trace mode for a few seconds
            timeout 5 sudo nethogs -t "$INTERFACE" >> "$LOG_FILE" 2>/dev/null || true
        fi

        # Start a short capture if tcpdump is available
        if check_dep tcpdump; then
            PCAP_FILE="$CAPTURE_DIR/burst_$TIMESTAMP.pcap"
            echo "Starting 10s packet capture → $PCAP_FILE" | tee -a "$LOG_FILE"
            sudo timeout 10 tcpdump -i "$INTERFACE" -w "$PCAP_FILE" -c 1000 2>/dev/null &
        fi
        echo "--------------------------------------------------"
    fi
done
