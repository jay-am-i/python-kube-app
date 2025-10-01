from flask import Flask, render_template
import socket
import json

app = Flask(__name__)

# Load config message
with open('config.json') as config_file:
    config = json.load(config_file)

@app.route('/')
def home():
    message = config.get("message", "Default message")
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)

    return render_template(
        "index.html",
        message=message,
        hostname=hostname,
        ip_address=ip_address
    )