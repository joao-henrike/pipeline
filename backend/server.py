from flask import Flask, request, jsonify
from flask_cors import CORS
import sqlite3
import os

app = Flask(__name__)
CORS(app)

DB_FILE = 'techstock.db'

# ==========================================
# SETUP DO BANCO DE DADOS (SQLITE)
# ==========================================
def init_db():
    with sqlite3.connect(DB_FILE) as conn:
        cursor = conn.cursor()
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS ativos (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                sku TEXT UNIQUE NOT NULL,
                nome TEXT NOT NULL,
                categoria TEXT NOT NULL,
                qtd INTEGER NOT NULL,
                local TEXT NOT NULL
            )
        ''')
        conn.commit()
    print("[BANCO] Banco de dados inicializado e tabela 'ativos' verificada.")

# Função auxiliar para converter o retorno do banco em dicionário (JSON)
def dict_factory(cursor, row):
    d = {}
    for idx, col in enumerate(cursor.description):
        d[col[0]] = row[idx]
    return d

# ==========================================
# ROTAS DE AUTENTICAÇÃO (MOCK)
# ==========================================
@app.route('/api/login', methods=['POST'])
def login():
    dados = request.get_json()
    print(f"[AUTH] Tentativa de login recebida: {dados.get('email')}")
    return jsonify({"status": "success", "message": "Login aprovado"}), 200

# ==========================================
# ROTAS DE INVENTÁRIO (CRUD REAL)
# ==========================================

# [READ] Listar todos os ativos
@app.route('/api/ativos', methods=['GET'])
def get_ativos():
    with sqlite3.connect(DB_FILE) as conn:
        conn.row_factory = dict_factory
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM ativos ORDER BY id DESC")
        ativos = cursor.fetchall()
    return jsonify(ativos), 200

# [CREATE] Adicionar novo ativo
@app.route('/api/ativos', methods=['POST'])
def criar_ativo():
    dados = request.get_json()
    try:
        with sqlite3.connect(DB_FILE) as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO ativos (sku, nome, categoria, qtd, local)
                VALUES (?, ?, ?, ?, ?)
            ''', (dados['sku'], dados['nome'], dados['categoria'], dados['qtd'], dados['local']))
            conn.commit()
            print(f"[INVENTARIO] Novo ativo cadastrado: {dados['sku']}")
        return jsonify({"status": "success", "message": "Ativo criado"}), 201
    except sqlite3.IntegrityError:
        return jsonify({"status": "error", "message": "SKU já cadastrado"}), 400

# [UPDATE] Editar ativo existente
@app.route('/api/ativos/<int:id_ativo>', methods=['PUT'])
def atualizar_ativo(id_ativo):
    dados = request.get_json()
    with sqlite3.connect(DB_FILE) as conn:
        cursor = conn.cursor()
        cursor.execute('''
            UPDATE ativos 
            SET sku=?, nome=?, categoria=?, qtd=?, local=?
            WHERE id=?
        ''', (dados['sku'], dados['nome'], dados['categoria'], dados['qtd'], dados['local'], id_ativo))
        conn.commit()
    print(f"[INVENTARIO] Ativo atualizado: ID {id_ativo}")
    return jsonify({"status": "success", "message": "Ativo atualizado"}), 200

# [DELETE] Remover ativo
@app.route('/api/ativos/<int:id_ativo>', methods=['DELETE'])
def deletar_ativo(id_ativo):
    with sqlite3.connect(DB_FILE) as conn:
        cursor = conn.cursor()
        cursor.execute("DELETE FROM ativos WHERE id=?", (id_ativo,))
        conn.commit()
    print(f"[INVENTARIO] Ativo deletado: ID {id_ativo}")
    return jsonify({"status": "success", "message": "Ativo deletado"}), 200

# ==========================================
# INICIALIZAÇÃO
# ==========================================
if __name__ == '__main__':
    print("[SISTEMA] Iniciando verificação pré-voo...")
    init_db()
    print("[SISTEMA] Servidor TechStock Backend rodando na porta 5000...")
    app.run(host='0.0.0.0', port=5000, debug=True)
