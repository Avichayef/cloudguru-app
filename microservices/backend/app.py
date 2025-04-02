import os
from flask import Flask, jsonify
import mysql.connector

class DBManager:
    def __init__(self, database='example', host="db", user="root", password_file=None):
        self.connection = None
        self.cursor = None
        try:
            if password_file and os.path.exists(password_file):
                pf = open(password_file, 'r')
                password = pf.read()
                pf.close()
            else:
                password = os.environ.get('DB_PASSWORD', 'password')

            self.connection = mysql.connector.connect(
                user=user,
                password=password,
                host=host,  # name of the mysql service as set in the docker compose file
                database=database,
                auth_plugin='mysql_native_password'
            )
            self.cursor = self.connection.cursor()
        except Exception as e:
            print(f"Database connection error: {e}")

    def populate_db(self):
        if not self.cursor:
            return False
        try:
            self.cursor.execute('DROP TABLE IF EXISTS tasks')
            self.cursor.execute('CREATE TABLE tasks (id INT AUTO_INCREMENT PRIMARY KEY, title VARCHAR(255), description TEXT, status VARCHAR(50))')
            self.cursor.executemany(
                'INSERT INTO tasks (id, title, description, status) VALUES (%s, %s, %s, %s);',
                [
                    (1, 'Task 1', 'Description for task 1', 'To Do'),
                    (2, 'Task 2', 'Description for task 2', 'In Progress'),
                    (3, 'Task 3', 'Description for task 3', 'Done')
                ]
            )
            self.connection.commit()
            return True
        except Exception as e:
            print(f"Database population error: {e}")
            return False

    def query_tasks(self):
        if not self.cursor:
            return []
        try:
            self.cursor.execute('SELECT id, title, description, status FROM tasks')
            tasks = []
            for (id, title, description, status) in self.cursor:
                tasks.append({
                    'id': id,
                    'title': title,
                    'description': description,
                    'status': status
                })
            return tasks
        except Exception as e:
            print(f"Database query error: {e}")
            return []

app = Flask(__name__)
conn = None

@app.route('/')
def index():
    return jsonify({"message": "Welcome to the Task API"})

@app.route('/tasks', methods=['GET'])
def get_tasks():
    # Always return sample data
    sample_tasks = [
        {
            'id': 1,
            'title': 'Deploy Infrastructure',
            'description': 'Set up AWS infrastructure using Terraform',
            'status': 'Done'
        },
        {
            'id': 2,
            'title': 'Configure CI/CD Pipeline',
            'description': 'Set up GitHub Actions for continuous integration and deployment',
            'status': 'In Progress'
        },
        {
            'id': 3,
            'title': 'Implement Security Measures',
            'description': 'Add security groups, IAM roles, and encryption',
            'status': 'To Do'
        },
        {
            'id': 4,
            'title': 'Test Application',
            'description': 'Perform end-to-end testing of the application',
            'status': 'To Do'
        }
    ]
    return jsonify(sample_tasks)

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port)
