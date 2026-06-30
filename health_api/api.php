<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

// ==================== DATABASE ====================
$host = 'localhost';
$dbname = 'health_tracker_db';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
    exit();
}

function sendResponse($data, $status = 200) {
    http_response_code($status);
    echo json_encode($data);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];
$path = isset($_GET['path']) ? $_GET['path'] : '';
$input = json_decode(file_get_contents('php://input'), true);

// ==================== TEST ====================
if ($path === 'test') {
    sendResponse(['status' => 'ok', 'message' => 'API berjalan! 💗']);
}

// ==================== REGISTER ====================
if ($path === 'register' && $method === 'POST') {
    $username = $input['username'] ?? '';
    $password = $input['password'] ?? '';
    $email = $input['email'] ?? '';
    
    if (empty($username) || empty($password)) {
        sendResponse(['error' => 'Username dan password wajib diisi'], 400);
    }
    
    try {
        $stmt = $pdo->prepare("INSERT INTO users (username, password, email) VALUES (?, ?, ?)");
        $stmt->execute([$username, $password, $email]);
        sendResponse([
            'status' => 'sukses',
            'message' => 'Registrasi berhasil',
            'user_id' => $pdo->lastInsertId()
        ]);
    } catch(PDOException $e) {
        if ($e->errorInfo[1] == 1062) {
            sendResponse(['error' => 'Username sudah digunakan'], 400);
        }
        sendResponse(['error' => 'Gagal registrasi'], 500);
    }
}

// ==================== LOGIN ====================
if ($path === 'login' && $method === 'POST') {
    $username = $input['username'] ?? '';
    $password = $input['password'] ?? '';
    
    if (empty($username) || empty($password)) {
        sendResponse(['error' => 'Username dan password wajib diisi'], 400);
    }
    
    $stmt = $pdo->prepare("SELECT id, username, email FROM users WHERE username = ? AND password = ?");
    $stmt->execute([$username, $password]);
    $user = $stmt->fetch();
    
    if ($user) {
        sendResponse([
            'status' => 'sukses',
            'message' => 'Login berhasil',
            'user' => $user
        ]);
    } else {
        sendResponse(['error' => 'Username atau password salah'], 401);
    }
}

// ==================== REMINDERS ====================
if ($path === 'reminders' && $method === 'GET') {
    $user_id = $_GET['user_id'] ?? 0;
    if (!$user_id) sendResponse(['error' => 'user_id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("SELECT * FROM reminders WHERE user_id = ? ORDER BY reminder_date ASC, reminder_time ASC");
    $stmt->execute([$user_id]);
    sendResponse($stmt->fetchAll());
}

if ($path === 'reminders' && $method === 'POST') {
    $user_id = $input['user_id'] ?? 0;
    $title = $input['title'] ?? '';
    $description = $input['description'] ?? '';
    $reminder_date = $input['reminder_date'] ?? '';
    $reminder_time = $input['reminder_time'] ?? '';
    $category = $input['category'] ?? '';
    
    if (!$user_id || empty($title) || empty($reminder_date) || empty($reminder_time)) {
        sendResponse(['error' => 'Data tidak lengkap'], 400);
    }
    
    $stmt = $pdo->prepare("INSERT INTO reminders (user_id, title, description, reminder_date, reminder_time, category) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->execute([$user_id, $title, $description, $reminder_date, $reminder_time, $category]);
    sendResponse(['status' => 'sukses', 'message' => 'Reminder ditambahkan', 'id' => $pdo->lastInsertId()]);
}

if ($path === 'reminders_toggle' && $method === 'PUT') {
    $id = $_GET['id'] ?? 0;
    if (!$id) sendResponse(['error' => 'id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("SELECT is_completed FROM reminders WHERE id = ?");
    $stmt->execute([$id]);
    $current = $stmt->fetch();
    if (!$current) sendResponse(['error' => 'Reminder tidak ditemukan'], 404);
    
    $newStatus = $current['is_completed'] == 0 ? 1 : 0;
    $stmt = $pdo->prepare("UPDATE reminders SET is_completed = ? WHERE id = ?");
    $stmt->execute([$newStatus, $id]);
    sendResponse(['status' => 'sukses', 'message' => 'Status diubah', 'is_completed' => $newStatus]);
}

if ($path === 'reminders' && $method === 'DELETE') {
    $id = $_GET['id'] ?? 0;
    if (!$id) sendResponse(['error' => 'id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("DELETE FROM reminders WHERE id = ?");
    $stmt->execute([$id]);
    sendResponse(['status' => 'sukses', 'message' => 'Reminder dihapus']);
}

// ============ UPDATE REMINDER - ============
if ($path === 'reminders' && $method === 'PUT') {
    $id = $_GET['id'] ?? 0;
    if (!$id) sendResponse(['error' => 'id wajib diisi'], 400);
    
    $title = $input['title'] ?? '';
    $description = $input['description'] ?? '';
    $reminder_date = $input['reminder_date'] ?? '';
    $reminder_time = $input['reminder_time'] ?? '';
    $category = $input['category'] ?? '';
    
    if (empty($title) || empty($reminder_date) || empty($reminder_time)) {
        sendResponse(['error' => 'Data tidak lengkap'], 400);
    }
    
    $stmt = $pdo->prepare("UPDATE reminders SET title = ?, description = ?, reminder_date = ?, reminder_time = ?, category = ? WHERE id = ?");
    $stmt->execute([$title, $description, $reminder_date, $reminder_time, $category, $id]);
    sendResponse(['status' => 'sukses', 'message' => 'Reminder diupdate']);
}

if ($path === 'reminders_toggle' && $method === 'PUT') {
    $id = $_GET['id'] ?? 0;
    if (!$id) sendResponse(['error' => 'id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("SELECT is_completed FROM reminders WHERE id = ?");
    $stmt->execute([$id]);
    $current = $stmt->fetch();
    if (!$current) sendResponse(['error' => 'Reminder tidak ditemukan'], 404);
    
    $newStatus = $current['is_completed'] == 0 ? 1 : 0;
    $stmt = $pdo->prepare("UPDATE reminders SET is_completed = ? WHERE id = ?");
    $stmt->execute([$newStatus, $id]);
    sendResponse(['status' => 'sukses', 'message' => 'Status diubah', 'is_completed' => $newStatus]);
}

if ($path === 'reminders' && $method === 'DELETE') {
    $id = $_GET['id'] ?? 0;
    if (!$id) sendResponse(['error' => 'id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("DELETE FROM reminders WHERE id = ?");
    $stmt->execute([$id]);
    sendResponse(['status' => 'sukses', 'message' => 'Reminder dihapus']);
}

// ==================== HEALTH LOGS ====================
if ($path === 'health_logs' && $method === 'GET') {
    $user_id = $_GET['user_id'] ?? 0;
    if (!$user_id) sendResponse(['error' => 'user_id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("SELECT * FROM health_logs WHERE user_id = ? ORDER BY log_date DESC");
    $stmt->execute([$user_id]);
    sendResponse($stmt->fetchAll());
}

if ($path === 'health_logs' && $method === 'POST') {
    $user_id = $input['user_id'] ?? 0;
    $log_date = $input['log_date'] ?? date('Y-m-d');
    $weight = $input['weight'] ?? '';
    $blood_pressure = $input['blood_pressure'] ?? '';
    $blood_sugar = $input['blood_sugar'] ?? '';
    $heart_rate = $input['heart_rate'] ?? '';
    $sleep_hours = $input['sleep_hours'] ?? '';
    $mood = $input['mood'] ?? '';
    $notes = $input['notes'] ?? '';
    
    if (!$user_id) sendResponse(['error' => 'user_id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("INSERT INTO health_logs (user_id, log_date, weight, blood_pressure, blood_sugar, heart_rate, sleep_hours, mood, notes) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)");
    $stmt->execute([$user_id, $log_date, $weight, $blood_pressure, $blood_sugar, $heart_rate, $sleep_hours, $mood, $notes]);
    sendResponse(['status' => 'sukses', 'message' => 'Data kesehatan ditambahkan', 'id' => $pdo->lastInsertId()]);
}

if ($path === 'health_logs' && $method === 'DELETE') {
    $id = $_GET['id'] ?? 0;
    if (!$id) sendResponse(['error' => 'id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("DELETE FROM health_logs WHERE id = ?");
    $stmt->execute([$id]);
    sendResponse(['status' => 'sukses', 'message' => 'Data kesehatan dihapus']);
}

// ==================== STATS ====================
if ($path === 'reminder_stats' && $method === 'GET') {
    $user_id = $_GET['user_id'] ?? 0;
    if (!$user_id) sendResponse(['error' => 'user_id wajib diisi'], 400);
    
    $stmt = $pdo->prepare("SELECT COUNT(*) as total FROM reminders WHERE user_id = ?");
    $stmt->execute([$user_id]);
    $total = $stmt->fetch()['total'];
    
    $stmt = $pdo->prepare("SELECT COUNT(*) as completed FROM reminders WHERE user_id = ? AND is_completed = 1");
    $stmt->execute([$user_id]);
    $completed = $stmt->fetch()['completed'];
    
    sendResponse([
        'total' => (int)$total,
        'completed' => (int)$completed,
        'pending' => (int)($total - $completed)
    ]);
}

sendResponse(['error' => 'Endpoint tidak ditemukan'], 404);
?>