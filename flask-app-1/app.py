from flask import Flask, jsonify

app = Flask(__name__)

@app.route('/flask/flask-app-1')
def hello_world():
    return jsonify({
        "message": "Hello from Podman Dak!",
        "status": "running"
    })

@app.route('/flask/flask-app-1/health')
def health_check():
    return jsonify({
        "status": "healthy",
        "message": "Application is up and running"
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', debug=True)