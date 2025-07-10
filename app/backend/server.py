from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime
import json
from prometheus_flask_exporter import PrometheusMetrics

# OpenTelemetry setup
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter

# Initialisation Flask
app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Instrumentation OpenTelemetry
trace.set_tracer_provider(
    TracerProvider(resource=Resource.create({"service.name": "flask-backend"}))
)
span_processor = BatchSpanProcessor(OTLPSpanExporter(endpoint="http://tempo.log.svc.cluster.local:4318/v1/traces"))
trace.get_tracer_provider().add_span_processor(span_processor)
FlaskInstrumentor().instrument_app(app)

# Configuration JSON
app.config['JSON_AS_ASCII'] = False
app.config['JSONIFY_PRETTYPRINT_REGULAR'] = False

# Connexion MySQL
app.config['SQLALCHEMY_DATABASE_URI'] = 'mysql+pymysql://appuser:password123@mysql/appdb'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
    "connect_args": {"charset": "utf8mb4"}
}

db = SQLAlchemy(app)

# Modèle
class Message(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    message = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

# Auto-migration
with app.app_context():
    db.create_all()

# Routes
@app.route('/', methods=['GET'])
def index():
    return 'Backend minimal en Python (Flask) fonctionne avec MySQL et Tempo'

@app.route('/api/submit', methods=['POST'])
def submit():
    data = request.get_json()
    print('Données reçues:', data)
    
    if not data or 'name' not in data or 'message' not in data:
        return jsonify({'error': 'Nom et message sont obligatoires'}), 400
    
    try:
        new_message = Message(name=data['name'], message=data['message'])
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
    result = [{
        'id': msg.id,
        'name': msg.name,
        'message': msg.message,
        'created_at': msg.created_at.strftime('%Y-%m-%d %H:%M:%S')
    } for msg in messages]
    return jsonify(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
