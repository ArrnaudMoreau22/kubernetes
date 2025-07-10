from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import json
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)

metrics = PrometheusMetrics(app)

# Configuration de l'encodage pour Flask
app.config['JSON_AS_ASCII'] = False  # Permet les caractères non-ASCII dans les réponses JSON
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = False  # Évite le formatage prettify qui peut causer des problèmes

# Configuration de la connexion MySQL
# Format: mysql+pymysql://username:password@hostname/database_name
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://appuser:password123@mysql/appdb'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

# S'assurer que la connexion MySQL utilise le bon encodage
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    "connect_args": {"charset": "utf8mb4"}
}

db = SQLAlchemy(app)

# Modèle de données
class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    message = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Création des tables au démarrage
with app.app_context():
    db.create_all()

@app.route('/', methods=['GET'])
def index():
    return 'Backend minimal en Python (Flask) fonctionne avec MySQL'

@app.route('/api/submit', methods=['POST'])
def submit():
    data = request.get_json()
    print('Données reçues:', data)
    
    # Vérification des données requises
    if not data or 'name' not in data or 'message' not in data:
        return jsonify({'error': 'Nom et message sont obligatoires'}), 400
    
    try:
        # Création d'un nouveau message
        new_message = Message(
            name=data['name'],
            message=data['message']
        )
        
        # Enregistrement en base de données
        db.session.add(new_message)
        db.session.commit()
        
        return jsonify({
            'status': 'success',
            'message': 'Données enregistrées avec succès',
            'id': new_message.id
        }), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"Erreur lors de l'enregistrement: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/messages', methods=['GET'])
def get_messages():
    messages = Message.query.order_by(Message.created_at.desc()).all()
    result = []
    for msg in messages:
        result.append({
            'id': msg.id,
            'name': msg.name,
            'message': msg.message,
            'created_at': msg.created_at.strftime('%Y-%m-%d %H:%M:%S')
        })
    return jsonify(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)