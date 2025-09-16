package main

import (
	"bytes"
	"database/sql"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	_ "github.com/mattn/go-sqlite3"
	"github.com/rs/cors"
)

// Task 结构体
type Task struct {
	ID          interface{} `json:"id" db:"id"`
	UserID      string      `json:"user_id" db:"user_id"`
	Title       string      `json:"title" db:"title"`
	Description string      `json:"description" db:"description"`
	DueDate     string      `json:"due_date" db:"due_date"`
	IsCompleted bool        `json:"is_completed" db:"is_completed"`
	Category    string      `json:"category" db:"category"`
	Priority    int         `json:"priority" db:"priority"`
	DeviceID    string      `json:"device_id" db:"device_id"`
	RecordID    string      `json:"record_id" db:"record_id"`
	CreatedAt   string      `json:"created_at" db:"created_at"`
	UpdatedAt   string      `json:"updated_at" db:"updated_at"`
}

// API响应结构体
type TasksResponse struct {
	Tasks  []Task `json:"tasks"`
	Total  int    `json:"total"`
	Limit  int    `json:"limit"`
	Offset int    `json:"offset"`
}

// WebSocket消息类型
type WSMessage struct {
	Type string      `json:"type"`
	Data interface{} `json:"data"`
}

// WebSocket连接管理
type Hub struct {
	clients    map[*websocket.Conn]bool
	broadcast  chan WSMessage
	register   chan *websocket.Conn
	unregister chan *websocket.Conn
}

var (
	hub          *Hub
	sqliteAPIURL = "http://localhost:8080"
	db           *sql.DB
)

// WebSocket升级器
var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // 允许所有来源
	},
}

// 初始化数据库
func initDB() {
	var err error
	db, err = sql.Open("sqlite3", "./tasks.db")
	if err != nil {
		log.Fatal("❌ 无法打开数据库:", err)
	}

	// 创建表
	createTableSQL := `
	CREATE TABLE IF NOT EXISTS tasks (
		id TEXT PRIMARY KEY,
		user_id TEXT DEFAULT 'default_user',
		title TEXT NOT NULL,
		description TEXT,
		due_date TEXT,
		is_completed INTEGER DEFAULT 0,
		category TEXT DEFAULT '学习',
		priority INTEGER DEFAULT 1,
		device_id TEXT,
		record_id TEXT,
		created_at TEXT DEFAULT CURRENT_TIMESTAMP,
		updated_at TEXT DEFAULT CURRENT_TIMESTAMP
	);`

	_, err = db.Exec(createTableSQL)
	if err != nil {
		log.Fatal("❌ 无法创建表:", err)
	}

	// 为现有表添加新字段（如果不存在）
	alterTableSQL := []string{
		"ALTER TABLE tasks ADD COLUMN category TEXT DEFAULT '学习'",
		"ALTER TABLE tasks ADD COLUMN priority INTEGER DEFAULT 1",
		"ALTER TABLE tasks ADD COLUMN record_id TEXT",
	}

	for _, sql := range alterTableSQL {
		_, err = db.Exec(sql)
		if err != nil {
			// 字段可能已存在，忽略错误
			log.Printf("⚠️ ALTER TABLE警告 (可能字段已存在): %v", err)
		}
	}

	log.Println("✅ 数据库初始化完成")
}

func main() {
	// 初始化数据库
	initDB()
	defer db.Close()

	// 测试API连接
	testAPIConnection()

	// 初始化WebSocket Hub
	hub = &Hub{
		clients:    make(map[*websocket.Conn]bool),
		broadcast:  make(chan WSMessage),
		register:   make(chan *websocket.Conn),
		unregister: make(chan *websocket.Conn),
	}

	// 启动WebSocket Hub
	go hub.run()

	// 设置路由
	router := mux.NewRouter()

	// REST API路由
	router.HandleFunc("/health", healthHandler).Methods("GET")
	router.HandleFunc("/api/tasks", getTasksHandler).Methods("GET")
	router.HandleFunc("/api/tasks", createTaskHandler).Methods("POST")
	router.HandleFunc("/api/tasks/{id}", getTaskHandler).Methods("GET")
	router.HandleFunc("/api/tasks/{id}", updateTaskHandler).Methods("PUT")
	router.HandleFunc("/api/tasks/{id}", deleteTaskHandler).Methods("DELETE")

	// WebSocket路由
	router.HandleFunc("/ws", wsHandler)

	// 设置CORS
	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"*"},
	})

	handler := c.Handler(router)

	fmt.Println("🚀 WebSocket服务器启动在端口 8082")
	fmt.Println("📡 WebSocket端点: ws://localhost:8082/ws")
	fmt.Println("🔗 REST API端点: http://localhost:8082/api/tasks")
	log.Fatal(http.ListenAndServe(":8082", handler))
}

// 测试SQLite API连接
func testAPIConnection() {
	resp, err := http.Get("http://localhost:8080/health")
	if err != nil {
		log.Fatal("SQLite API连接失败:", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		fmt.Println("✅ SQLite API连接成功")
	} else {
		log.Fatal("SQLite API健康检查失败:", resp.StatusCode)
	}
}

// WebSocket Hub运行
func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.clients[client] = true
			log.Printf("客户端连接，当前连接数: %d", len(h.clients))

		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				client.Close()
				log.Printf("客户端断开，当前连接数: %d", len(h.clients))
			}

		case message := <-h.broadcast:
			log.Printf("📡 收到广播消息: type=%s, 目标客户端数=%d", message.Type, len(h.clients))
			successCount := 0
			for client := range h.clients {
				err := client.WriteJSON(message)
				if err != nil {
					log.Printf("❌ 发送消息失败: %v", err)
					delete(h.clients, client)
					client.Close()
				} else {
					successCount++
				}
			}
			log.Printf("✅ 广播完成: 成功发送给 %d/%d 个客户端", successCount, len(h.clients))
		}
	}
}

// WebSocket处理器
func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket升级失败: %v", err)
		return
	}

	hub.register <- conn

	// 发送当前所有任务给新连接的客户端
	go func() {
		tasks, err := getAllTasks("default_user")
		if err == nil {
			message := WSMessage{
				Type: "tasks_sync",
				Data: tasks,
			}
			conn.WriteJSON(message)
		}
	}()

	// 处理客户端消息
	go func() {
		defer func() {
			hub.unregister <- conn
		}()

		for {
			var msg WSMessage
			err := conn.ReadJSON(&msg)
			if err != nil {
				log.Printf("读取WebSocket消息失败: %v", err)
				break
			}

			// 处理不同类型的消息
			log.Printf("📨 收到WebSocket消息类型: %s", msg.Type)
			switch msg.Type {
			case "ping":
				conn.WriteJSON(WSMessage{Type: "pong", Data: "ok"})
			case "create_task":
				handleCreateTask(msg.Data)
			case "update_task":
				handleUpdateTask(msg.Data)
			case "delete_task":
				handleDeleteTask(msg.Data)
			default:
				log.Printf("❓ 未知消息类型: %s", msg.Type)
			}
		}
	}()
}

// 广播任务变更
func broadcastTaskChange(changeType string, task *Task) {
	message := WSMessage{
		Type: changeType,
		Data: task,
	}
	log.Printf("🔊 准备广播消息: type=%s, task=%s, 连接数=%d", changeType, task.Title, len(hub.clients))
	hub.broadcast <- message
	log.Printf("✅ 消息已发送到广播通道")
}

// REST API处理器
func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
}

func getTasksHandler(w http.ResponseWriter, r *http.Request) {
	userID := r.URL.Query().Get("userId")
	if userID == "" {
		userID = "default_user"
	}

	tasks, err := getAllTasks(userID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(tasks)
}

func getTaskHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]
	if id == "" {
		http.Error(w, "Invalid task ID", http.StatusBadRequest)
		return
	}

	task, err := getTaskByID(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(task)
}

func createTaskHandler(w http.ResponseWriter, r *http.Request) {
	var task Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	// 检查是否存在重复任务
	existingTask, err := findDuplicateTask(task.Title, task.DeviceID, task.UserID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if existingTask != nil {
		// 更新现有任务
		existingTask.Description = task.Description
		existingTask.DueDate = task.DueDate
		existingTask.IsCompleted = task.IsCompleted
		existingTask.RecordID = task.RecordID
		existingTask.UpdatedAt = time.Now().Format("2006-01-02 15:04:05")

		if err := updateTask(existingTask); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		// 广播更新
		broadcastTaskChange("task_updated", existingTask)

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(existingTask)
		return
	}

	// 创建新任务
	task.UserID = "default_user"
	task.CreatedAt = time.Now().Format("2006-01-02 15:04:05")
	task.UpdatedAt = time.Now().Format("2006-01-02 15:04:05")

	id, err := createTask(&task)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	task.ID = id

	// 广播新任务
	broadcastTaskChange("task_created", &task)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(task)
}

func updateTaskHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]
	if id == "" {
		http.Error(w, "Invalid task ID", http.StatusBadRequest)
		return
	}

	var task Task
	if err := json.NewDecoder(r.Body).Decode(&task); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	task.ID = id
	task.UpdatedAt = time.Now().Format("2006-01-02 15:04:05")

	if err := updateTask(&task); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// 广播更新
	broadcastTaskChange("task_updated", &task)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(task)
}

func deleteTaskHandler(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	id := vars["id"]
	if id == "" {
		http.Error(w, "Invalid task ID", http.StatusBadRequest)
		return
	}

	// 获取任务信息用于广播
	task, err := getTaskByID(id)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	if err := deleteTask(id); err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	// 广播删除
	broadcastTaskChange("task_deleted", task)

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{"message": "任务删除成功"})
}

// 数据库操作函数
func getAllTasks(userID string) ([]Task, error) {
	query := `SELECT id, user_id, title, description, due_date, is_completed,
	          COALESCE(category, '学习') as category,
	          COALESCE(priority, 1) as priority,
	          device_id, COALESCE(record_id, '') as record_id,
	          created_at, updated_at
	          FROM tasks WHERE user_id = ? ORDER BY created_at DESC`

	rows, err := db.Query(query, userID)
	if err != nil {
		log.Printf("❌ 数据库查询失败: %v", err)
		return nil, err
	}
	defer rows.Close()

	var tasks []Task
	for rows.Next() {
		var task Task
		err := rows.Scan(
			&task.ID, &task.UserID, &task.Title, &task.Description,
			&task.DueDate, &task.IsCompleted, &task.Category, &task.Priority,
			&task.DeviceID, &task.RecordID, &task.CreatedAt, &task.UpdatedAt,
		)
		if err != nil {
			log.Printf("❌ 扫描任务数据失败: %v", err)
			continue
		}
		tasks = append(tasks, task)
	}

	log.Printf("✅ 从数据库获取任务数组，任务数量: %d", len(tasks))
	return tasks, nil
}

func getTaskByID(id string) (*Task, error) {
	url := fmt.Sprintf("%s/api/tasks/%s", sqliteAPIURL, id)
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return nil, fmt.Errorf("API请求失败: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var task Task
	err = json.Unmarshal(body, &task)
	if err != nil {
		return nil, err
	}

	return &task, nil
}

func findDuplicateTask(title, deviceID, userID string) (*Task, error) {
	// 获取所有任务并在内存中查找重复
	tasks, err := getAllTasks(userID)
	if err != nil {
		return nil, err
	}

	for _, task := range tasks {
		if task.Title == title && task.DeviceID == deviceID {
			return &task, nil
		}
	}

	return nil, nil
}

func createTask(task *Task) (string, error) {
	jsonData, err := json.Marshal(task)
	if err != nil {
		return "", err
	}

	resp, err := http.Post(sqliteAPIURL+"/api/tasks", "application/json", bytes.NewBuffer(jsonData))
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 && resp.StatusCode != 201 {
		return "", fmt.Errorf("创建任务失败: %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	var response struct {
		TaskID string `json:"task_id"`
		ID     string `json:"id"`
	}
	err = json.Unmarshal(body, &response)
	if err != nil {
		return "", err
	}

	if response.TaskID != "" {
		return response.TaskID, nil
	}
	return response.ID, nil
}

func updateTask(task *Task) error {
	jsonData, err := json.Marshal(task)
	if err != nil {
		return err
	}

	url := fmt.Sprintf("%s/api/tasks/%d", sqliteAPIURL, task.ID)
	req, err := http.NewRequest("PUT", url, bytes.NewBuffer(jsonData))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("更新任务失败: %d", resp.StatusCode)
	}

	return nil
}

func deleteTask(id string) error {
	url := fmt.Sprintf("%s/api/tasks/%s", sqliteAPIURL, id)
	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		return err
	}

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return fmt.Errorf("删除任务失败: %d", resp.StatusCode)
	}

	return nil
}

// WebSocket消息处理函数
func handleCreateTask(data interface{}) {
	log.Printf("📨 收到创建任务消息: %+v", data)

	// 将interface{}转换为Task结构体
	taskMap, ok := data.(map[string]interface{})
	if !ok {
		log.Printf("❌ 创建任务消息格式错误")
		return
	}

	task := &Task{
		UserID:      getString(taskMap, "user_id"),
		Title:       getString(taskMap, "title"),
		Description: getString(taskMap, "description"),
		DueDate:     getString(taskMap, "due_date"),
		IsCompleted: getBool(taskMap, "is_completed"),
		Category:    getString(taskMap, "category"),
		Priority:    getInt(taskMap, "priority"),
		DeviceID:    getString(taskMap, "device_id"),
		RecordID:    getString(taskMap, "record_id"),
	}

	// 通过API创建任务
	err := createTaskViaAPI(task)
	if err != nil {
		log.Printf("❌ 创建任务失败: %v", err)
		return
	}

	log.Printf("✅ 任务创建成功，已广播给所有客户端")
}

func handleUpdateTask(data interface{}) {
	log.Printf("📨 收到更新任务消息: %+v", data)

	taskMap, ok := data.(map[string]interface{})
	if !ok {
		log.Printf("❌ 更新任务消息格式错误")
		return
	}

	task := &Task{
		UserID:      getString(taskMap, "user_id"),
		Title:       getString(taskMap, "title"),
		Description: getString(taskMap, "description"),
		DueDate:     getString(taskMap, "due_date"),
		IsCompleted: getBool(taskMap, "is_completed"),
		Category:    getString(taskMap, "category"),
		Priority:    getInt(taskMap, "priority"),
		DeviceID:    getString(taskMap, "device_id"),
		RecordID:    getString(taskMap, "record_id"),
	}

	// 通过API更新任务
	err := updateTaskViaAPI(task)
	if err != nil {
		log.Printf("❌ 更新任务失败: %v", err)
		return
	}

	log.Printf("✅ 任务更新成功，已广播给所有客户端")
}

func handleDeleteTask(data interface{}) {
	log.Printf("📨 收到删除任务消息: %+v", data)

	taskMap, ok := data.(map[string]interface{})
	if !ok {
		log.Printf("❌ 删除任务消息格式错误")
		return
	}

	// 优先使用record_id查找任务
	recordID := getString(taskMap, "record_id")
	title := getString(taskMap, "title")
	deviceID := getString(taskMap, "device_id") // 修正字段名

	log.Printf("🔍 删除任务参数: recordID=%s, title=%s, deviceID=%s", recordID, title, deviceID)

	// 通过API删除任务
	err := deleteTaskViaAPI(recordID, title, deviceID)
	if err != nil {
		log.Printf("❌ 删除任务失败: %v", err)
		return
	}

	log.Printf("✅ 任务删除成功，已广播给所有客户端")
}

// 辅助函数
func getString(m map[string]interface{}, key string) string {
	if val, ok := m[key]; ok {
		if str, ok := val.(string); ok {
			return str
		}
	}
	return ""
}

// 获取任务ID的字符串表示
func getTaskIDString(task *Task) string {
	switch id := task.ID.(type) {
	case string:
		return id
	case int:
		return fmt.Sprintf("%d", id)
	case float64:
		return fmt.Sprintf("%.0f", id)
	default:
		return ""
	}
}

func getStringPtr(m map[string]interface{}, key string) *string {
	if val, ok := m[key]; ok {
		if str, ok := val.(string); ok {
			if str != "" {
				return &str
			}
		}
	}
	return nil
}

func getBool(m map[string]interface{}, key string) bool {
	if val, ok := m[key]; ok {
		if b, ok := val.(bool); ok {
			return b
		}
	}
	return false
}

func getInt(m map[string]interface{}, key string) int {
	if val, ok := m[key]; ok {
		switch v := val.(type) {
		case int:
			return v
		case float64:
			return int(v)
		case string:
			// 尝试解析字符串为整数
			if i, err := strconv.Atoi(v); err == nil {
				return i
			}
		}
	}
	return 0
}

// 数据库操作函数
func createTaskViaAPI(task *Task) error {
	// 生成ID如果没有
	if task.ID == nil || task.ID == "" {
		task.ID = fmt.Sprintf("task_%d", time.Now().UnixNano())
	}

	query := `INSERT INTO tasks (id, user_id, title, description, due_date, is_completed,
	          category, priority, device_id, record_id, created_at, updated_at)
	          VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`

	_, err := db.Exec(query,
		task.ID, task.UserID, task.Title, task.Description,
		task.DueDate, task.IsCompleted, task.Category, task.Priority,
		task.DeviceID, task.RecordID)

	if err != nil {
		log.Printf("❌ 创建任务失败: %v", err)
		return err
	}

	log.Printf("✅ 任务创建成功: %s", task.Title)

	// 广播任务创建事件
	broadcastTaskChange("task_created", task)
	return nil
}

func updateTaskViaAPI(task *Task) error {
	log.Printf("🔍 查找任务: recordID=%s, title=%s, deviceID=%s", task.RecordID, task.Title, task.DeviceID)

	var query string
	var args []interface{}

	// 优先使用record_id查找任务
	if task.RecordID != "" {
		log.Printf("🔍 使用record_id查找任务: %s", task.RecordID)
		query = `UPDATE tasks SET title=?, description=?, due_date=?, is_completed=?,
		         category=?, priority=?, device_id=?, updated_at=CURRENT_TIMESTAMP
		         WHERE record_id=? AND user_id=?`
		args = []interface{}{
			task.Title, task.Description, task.DueDate, task.IsCompleted,
			task.Category, task.Priority, task.DeviceID, task.RecordID, task.UserID,
		}
	} else {
		// 如果没有record_id，使用title和device_id
		log.Printf("🔍 使用title+device_id查找任务")
		query = `UPDATE tasks SET description=?, due_date=?, is_completed=?,
		         category=?, priority=?, updated_at=CURRENT_TIMESTAMP
		         WHERE title=? AND device_id=? AND user_id=?`
		args = []interface{}{
			task.Description, task.DueDate, task.IsCompleted,
			task.Category, task.Priority, task.Title, task.DeviceID, task.UserID,
		}
	}

	result, err := db.Exec(query, args...)
	if err != nil {
		log.Printf("❌ 更新任务失败: %v", err)
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("❌ 获取影响行数失败: %v", err)
		return err
	}

	if rowsAffected == 0 {
		log.Printf("❌ 未找到要更新的任务: recordID=%s, title=%s, deviceID=%s", task.RecordID, task.Title, task.DeviceID)
		return fmt.Errorf("未找到要更新的任务")
	}

	log.Printf("✅ 任务更新成功: %s (影响行数: %d)", task.Title, rowsAffected)

	// 获取更新后的任务数据用于广播
	var updatedTask Task
	var selectQuery string
	var selectArgs []interface{}

	if task.RecordID != "" {
		selectQuery = `SELECT id, user_id, title, description, due_date, is_completed,
		               COALESCE(category, '学习') as category,
		               COALESCE(priority, 1) as priority,
		               device_id, COALESCE(record_id, '') as record_id,
		               created_at, updated_at
		               FROM tasks WHERE record_id=? AND user_id=?`
		selectArgs = []interface{}{task.RecordID, task.UserID}
	} else {
		selectQuery = `SELECT id, user_id, title, description, due_date, is_completed,
		               COALESCE(category, '学习') as category,
		               COALESCE(priority, 1) as priority,
		               device_id, COALESCE(record_id, '') as record_id,
		               created_at, updated_at
		               FROM tasks WHERE title=? AND device_id=? AND user_id=?`
		selectArgs = []interface{}{task.Title, task.DeviceID, task.UserID}
	}

	err = db.QueryRow(selectQuery, selectArgs...).Scan(
		&updatedTask.ID, &updatedTask.UserID, &updatedTask.Title, &updatedTask.Description,
		&updatedTask.DueDate, &updatedTask.IsCompleted, &updatedTask.Category, &updatedTask.Priority,
		&updatedTask.DeviceID, &updatedTask.RecordID, &updatedTask.CreatedAt, &updatedTask.UpdatedAt,
	)

	if err != nil {
		log.Printf("❌ 获取更新后的任务数据失败: %v", err)
		// 即使获取失败，也使用原始数据广播
		updatedTask = *task
	}

	// 广播任务更新事件
	broadcastTaskChange("task_updated", &updatedTask)
	return nil
}

func deleteTaskViaAPI(recordID, title, deviceID string) error {
	log.Printf("🔍 查找要删除的任务: recordID=%s, title=%s, deviceID=%s", recordID, title, deviceID)

	var query string
	var args []interface{}
	var targetTask Task

	// 优先使用recordID查找任务
	if recordID != "" {
		log.Printf("🔍 使用record_id查找任务: %s", recordID)
		query = `SELECT id, user_id, title, description, due_date, is_completed,
		         COALESCE(category, '学习') as category,
		         COALESCE(priority, 1) as priority,
		         device_id, COALESCE(record_id, '') as record_id,
		         created_at, updated_at
		         FROM tasks WHERE record_id=?`
		args = []interface{}{recordID}
	} else {
		// 如果没有recordID，使用title和deviceID
		log.Printf("🔍 使用title+device_id查找任务")
		query = `SELECT id, user_id, title, description, due_date, is_completed,
		         COALESCE(category, '学习') as category,
		         COALESCE(priority, 1) as priority,
		         device_id, COALESCE(record_id, '') as record_id,
		         created_at, updated_at
		         FROM tasks WHERE title=? AND device_id=?`
		args = []interface{}{title, deviceID}
	}

	err := db.QueryRow(query, args...).Scan(
		&targetTask.ID, &targetTask.UserID, &targetTask.Title, &targetTask.Description,
		&targetTask.DueDate, &targetTask.IsCompleted, &targetTask.Category, &targetTask.Priority,
		&targetTask.DeviceID, &targetTask.RecordID, &targetTask.CreatedAt, &targetTask.UpdatedAt,
	)

	if err != nil {
		if err == sql.ErrNoRows {
			log.Printf("❌ 未找到要删除的任务: recordID=%s, title=%s, deviceID=%s", recordID, title, deviceID)
			return fmt.Errorf("未找到要删除的任务")
		}
		log.Printf("❌ 查询任务失败: %v", err)
		return err
	}

	log.Printf("🎯 找到要删除的任务: ID=%v, Title=%s, RecordID=%s", targetTask.ID, targetTask.Title, targetTask.RecordID)

	// 执行删除
	var deleteQuery string
	var deleteArgs []interface{}

	if recordID != "" {
		deleteQuery = "DELETE FROM tasks WHERE record_id=?"
		deleteArgs = []interface{}{recordID}
	} else {
		deleteQuery = "DELETE FROM tasks WHERE title=? AND device_id=?"
		deleteArgs = []interface{}{title, deviceID}
	}

	result, err := db.Exec(deleteQuery, deleteArgs...)
	if err != nil {
		log.Printf("❌ 删除任务失败: %v", err)
		return err
	}

	rowsAffected, err := result.RowsAffected()
	if err != nil {
		log.Printf("❌ 获取影响行数失败: %v", err)
		return err
	}

	if rowsAffected == 0 {
		log.Printf("❌ 删除任务失败，没有行被影响")
		return fmt.Errorf("删除任务失败")
	}

	log.Printf("🗑️ 任务删除成功: %s (影响行数: %d)", targetTask.Title, rowsAffected)

	// 广播任务删除事件
	broadcastTaskChange("task_deleted", &targetTask)
	return nil
}
