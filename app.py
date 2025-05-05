from flask import Flask, request, jsonify, send_from_directory
import mysql.connector
import os

app = Flask(__name__, static_folder='static')

# Database connection
def get_db_connection():
    conn = mysql.connector.connect(
        host=os.getenv('DB_URL'),
        user=os.getenv('DB_USER'),
        password=os.getenv('DB_PASSWORD'),
        database='liordb'
    )
    return conn

@app.route('/get_users', methods=['GET'])
def get_users():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    cursor.close()
    conn.close()
    return jsonify(users)

@app.route('/add_user', methods=['POST'])
def add_user():
    data = request.get_json()
    name = data.get('name')
    email = data.get('email')
    
    if not name or not email:
        return jsonify({'error': 'Name and email are required'}), 400
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute("INSERT INTO users (name, email) VALUES (%s, %s)", (name, email))
    conn.commit()
    cursor.close()
    conn.close()
    
    return jsonify({'message': 'User added successfully'}), 201

# Serve the index.html from the static folder
@app.route('/')
def index():
    return send_from_directory(app.static_folder, 'index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000)  # Changed port to 3000

