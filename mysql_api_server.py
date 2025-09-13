#!/usr/bin/env python3
"""
极轻量级MySQL API服务器
资源占用极低，只提供基本的CRUD操作
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import mysql.connector
import json
from datetime import datetime
import os

app = Flask(__name__)
CORS(app)

# MySQL配置
MYSQL_CONFIG = {
    'host': 'localhost',
    'port': 3306,
    'user': 'kidsapp',
    'password': 'KidsApp2025!',
    'database': 'kids_schedule',
    'charset': 'utf8mb4'
}

def get_db_connection():
    """获取数据库连接"""
    try:
        connection = mysql.connector.connect(**MYSQL_CONFIG)
        return connection
    except mysql.connector.Error as err:
        print(f"数据库连接错误: {err}")
        return None

@app.route('/health', methods=['GET'])
def health_check():
    """健康检查"""
    try:
        conn = get_db_connection()
        if conn:
            conn.close()
            return jsonify({
                'status': 'OK',
                'timestamp': datetime.now().isoformat(),
                'message': 'MySQL连接正常'
            })
        else:
            return jsonify({
                'status': 'ERROR',
                'timestamp': datetime.now().isoformat(),
                'message': 'MySQL连接失败'
            }), 500
    except Exception as e:
        return jsonify({
            'status': 'ERROR',
            'timestamp': datetime.now().isoformat(),
            'message': str(e)
        }), 500

@app.route('/api/tasks', methods=['GET'])
def get_tasks():
    """获取任务列表"""
    user_id = request.args.get('user_id')
    if not user_id:
        return jsonify({'error': 'user_id is required'}), 400
    
    conn = get_db_connection()
    if not conn:
        return jsonify({'error': '数据库连接失败'}), 500
    
    try:
        cursor = conn.cursor(dictionary=True)
        cursor.execute("""
            SELECT id, user_id, title, description, due_date, is_completed, 
                   device_id, created_at, updated_at
            FROM tasks 
            WHERE user_id = %s 
            ORDER BY created_at DESC
        """, (user_id,))
        
        tasks = cursor.fetchall()
        
        # 转换日期格式
        for task in tasks:
            if task['due_date']:
                task['due_date'] = task['due_date'].isoformat()
            if task['created_at']:
                task['created_at'] = task['created_at'].isoformat()
            if task['updated_at']:
                task['updated_at'] = task['updated_at'].isoformat()
        
        return jsonify(tasks)
        
    except mysql.connector.Error as err:
        return jsonify({'error': f'查询失败: {err}'}), 500
    finally:
        if conn:
            conn.close()

@app.route('/api/tasks', methods=['POST'])
def create_task():
    """创建新任务"""
    try:
        data = request.get_json()
        
        # 验证必填字段
        required_fields = ['id', 'user_id', 'title']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'缺少必填字段: {field}'}), 400
        
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': '数据库连接失败'}), 500
        
        try:
            cursor = conn.cursor()
            
            # 插入任务
            insert_query = """
                INSERT INTO tasks (id, user_id, title, description, due_date, 
                                 is_completed, device_id, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s, NOW(), NOW())
            """
            
            values = (
                data['id'],
                data['user_id'],
                data['title'],
                data.get('description', ''),
                data.get('due_date'),
                data.get('is_completed', False),
                data.get('device_id', '')
            )
            
            cursor.execute(insert_query, values)
            conn.commit()
            
            print(f"✅ 任务创建成功: {data['title']}")
            return jsonify({
                'message': '任务创建成功',
                'task_id': data['id']
            }), 201
            
        except mysql.connector.Error as err:
            conn.rollback()
            print(f"❌ 创建任务失败: {err}")
            return jsonify({'error': f'保存任务失败: {err}'}), 500
        finally:
            if conn:
                conn.close()
                
    except Exception as e:
        print(f"❌ 服务器错误: {e}")
        return jsonify({'error': '服务器内部错误'}), 500

@app.route('/api/tasks/<task_id>', methods=['PUT'])
def update_task(task_id):
    """更新任务"""
    try:
        data = request.get_json()
        
        conn = get_db_connection()
        if not conn:
            return jsonify({'error': '数据库连接失败'}), 500
        
        try:
            cursor = conn.cursor()
            
            # 构建更新查询
            update_fields = []
            values = []
            
            if 'title' in data:
                update_fields.append('title = %s')
                values.append(data['title'])
            if 'description' in data:
                update_fields.append('description = %s')
                values.append(data['description'])
            if 'due_date' in data:
                update_fields.append('due_date = %s')
                values.append(data['due_date'])
            if 'is_completed' in data:
                update_fields.append('is_completed = %s')
                values.append(data['is_completed'])
            
            if not update_fields:
                return jsonify({'error': '没有要更新的字段'}), 400
            
            update_fields.append('updated_at = NOW()')
            values.append(task_id)
            
            update_query = f"""
                UPDATE tasks 
                SET {', '.join(update_fields)}
                WHERE id = %s
            """
            
            cursor.execute(update_query, values)
            conn.commit()
            
            if cursor.rowcount == 0:
                return jsonify({'error': '任务不存在'}), 404
            
            return jsonify({'message': '任务更新成功'})
            
        except mysql.connector.Error as err:
            conn.rollback()
            return jsonify({'error': f'更新任务失败: {err}'}), 500
        finally:
            if conn:
                conn.close()
                
    except Exception as e:
        return jsonify({'error': '服务器内部错误'}), 500

if __name__ == '__main__':
    print("🚀 启动轻量级MySQL API服务器...")
    print("📍 地址: http://0.0.0.0:8080")
    print("🔍 健康检查: http://0.0.0.0:8080/health")
    print("📝 任务API: http://0.0.0.0:8080/api/tasks")
    
    # 生产环境配置
    app.run(
        host='0.0.0.0',
        port=8080,
        debug=False,  # 生产环境关闭调试
        threaded=True  # 启用多线程
    )
