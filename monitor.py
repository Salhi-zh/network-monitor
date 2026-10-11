import psutil
import time
import os
from datetime import datetime
from rich.console import Console
from rich.table import Table

console = Console()

def get_network_connections():
    """Returns a list of active network connections with PID and local/remote addresses."""
    connections = []
    for conn in psutil.net_connections(kind='inet'):
        if conn.status == 'ESTABLISHED':
            try:
                proc = psutil.Process(conn.pid)
                name = proc.name()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                name = "Unknown"
            
            connections.append({
                "pid": conn.pid,
                "name": name,
                "local": f"{conn.laddr.ip}:{conn.laddr.port}",
                "remote": f"{conn.raddr.ip}:{conn.raddr.port}"
            })
    return connections

def display_dashboard():
    while True:
        console.clear()
        console.print("[bold cyan]📡 Brilliant Connection Monitor[/bold cyan]", justify="center")
        console.print(f"[italic]Last Update: {datetime.now().strftime('%H:%M:%S')}[/italic]", justify="center")
        
        table = Table(title="Active Established Connections")
        table.add_column("PID", style="dim")
        table.add_column("Process", style="cyan")
        table.add_column("Local Address", style="green")
        table.add_column("Remote Address", style="magenta")

        conns = get_network_connections()
        for c in conns:
            table.add_row(str(c['pid']), c['name'], c['local'], c['remote'])
        
        console.print(table)
        console.print("\n[dim]Press Ctrl+C to exit[/dim]")
        time.sleep(2)

if __name__ == "__main__":
    try:
        display_dashboard()
    except KeyboardInterrupt:
        console.print("\n[bold yellow]Exiting monitor...[/bold yellow]")
