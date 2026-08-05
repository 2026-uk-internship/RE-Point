CREATE DATABASE repoint;
USE repoint;
SHOW TABLES;


# USER AND GRANT
CREATE USER 'repoint_user'@'localhost' IDENTIFIED BY 'helloworld';

GRANT ALL PRIVILEGES ON repoint.*
TO 'repoint_user'@'localhost';

FLUSH PRIVILEGES;


# TABLE
CREATE TABLE auth (
    id INT AUTO_INCREMENT PRIMARY KEY,
    phone VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE
);

CREATE TABLE users (
	id INTEGER PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE,
    img VARCHAR(255),
    comment VARCHAR(255),
    point INTEGER DEFAULT 100 CHECK (point >= 0),
    location_id INTEGER,
    temperature INTEGER DEFAULT 0,
    last_active_at DATETIME DEFAULT CURRENT_TIMESTAMP,   -- 추가: 최근 활동 시각 (공개 프로필의 'n시간 전' 표시용)

    FOREIGN KEY (id) REFERENCES auth(id)
		ON DELETE CASCADE
		ON UPDATE CASCADE,
    FOREIGN KEY (location_id) REFERENCES location(id)
		ON DELETE CASCADE
		ON UPDATE CASCADE
);

CREATE TABLE location (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    city VARCHAR(255) NOT NULL
);

CREATE TABLE point_history (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER,
    amount INTEGER NOT NULL,
    type ENUM('earn_sale', 'spend_purchase', 'charge', 'auction_win') NOT NULL,
    related_id INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE SET NULL		# 서버에서 NULL일 경우, '탈퇴한 사용자'
        ON UPDATE CASCADE
);

CREATE TABLE products (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    money_price INTEGER,
    point_price INTEGER,
    type ENUM('general', 'point', 'auction') NOT NULL,
    category_id INTEGER,
    location VARCHAR(255) NOT NULL,
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    status ENUM('sale', 'reserved', 'sold') DEFAULT 'sale',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (category_id) REFERENCES category(id)
		ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

CREATE TABLE trades (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    product_id INTEGER NOT NULL,
    buyer_id INTEGER,
    seller_id INTEGER,
    status ENUM('requested', 'accepted', 'rejected', 'completed', 'canceled') DEFAULT 'requested',
    requested_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    completed_at DATETIME,

    FOREIGN KEY (product_id) REFERENCES products(id),
    FOREIGN KEY (buyer_id) REFERENCES users(id)
		ON DELETE SET NULL		# 만약 거래 중에 회원 탈퇴를 요청할 경우, 서버에서 거부 메시지 / if null -> 'deleted user'
        ON UPDATE CASCADE,
    FOREIGN KEY (seller_id) REFERENCES users(id)
		ON DELETE SET NULL		# 만약 거래 중에 회원 탈퇴를 요청할 경우, 서버에서 거부 메시지 / if null -> 'deleted user'
        ON UPDATE CASCADE
);

CREATE TABLE auction (
	product_id INTEGER PRIMARY KEY,
    start_point INTEGER NOT NULL,
    end_date DATETIME NOT NULL,
    highest_user INTEGER,
    highest_point INTEGER NOT NULL,

    FOREIGN KEY (product_id) REFERENCES products(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (highest_user) REFERENCES users(id)
		ON DELETE SET NULL
		ON UPDATE CASCADE
);

CREATE TABLE bids (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    auction_id INTEGER NOT NULL,
    user_id INTEGER,
    point INTEGER NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (auction_id) REFERENCES auction(product_id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE product_images (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    img VARCHAR(255) NOT NULL,
    product_id INTEGER,

    FOREIGN KEY (product_id) REFERENCES products(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE category (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL UNIQUE,
    point_rate DECIMAL(10, 2) NOT NULL,
    co2_saved DECIMAL(10, 2) DEFAULT 0            -- 탄소 절감량 추정 가중치 (kg CO2)
);

CREATE TABLE user_category (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL,
    UNIQUE (user_id, category_id),

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (category_id) REFERENCES category(id)
		ON DELETE RESTRICT
        ON UPDATE RESTRICT
);

CREATE TABLE search (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL UNIQUE,
    count INTEGER DEFAULT 1
);

CREATE TABLE user_search_logs (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER,
    search_id INTEGER,
    date DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE SET NULL
        ON UPDATE CASCADE,
	FOREIGN KEY (search_id) REFERENCES search(id)
		ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE favorites (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER,
    product_id INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (product_id) REFERENCES products(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,

	UNIQUE(user_id, product_id)
);

CREATE TABLE view_product (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER,
    product_id INTEGER,
	date DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (product_id) REFERENCES products(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE rooms (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    seller INTEGER,
    buyer INTEGER,
    product_id INTEGER,

    FOREIGN KEY (seller) REFERENCES users(id)
		ON DELETE SET NULL
        ON UPDATE CASCADE,
	FOREIGN KEY (buyer) REFERENCES users(id)
		ON DELETE SET NULL
		ON UPDATE CASCADE,
	FOREIGN KEY (product_id) REFERENCES products(id)
		ON DELETE CASCADE		# 만약 채팅방이 존재하지만, 삭제 시도가 온다면 서버 로직에서 처리
        ON UPDATE CASCADE
);

CREATE TABLE chats (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    room_id INTEGER,
    user_id INTEGER,
    message TEXT NOT NULL,
    date DATETIME DEFAULT CURRENT_TIMESTAMP,

	FOREIGN KEY (room_id) REFERENCES rooms(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE coupons (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    valid_from DATETIME,
    valid_until DATETIME,
    effect_type ENUM('percent_discount', 'fixed_discount', 'point_bonus'),
    effect_value DECIMAL(10,2) NOT NULL,
    min_amount INTEGER DEFAULT 0,
    max_discount INTEGER
);

CREATE TABLE coupon_user (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER,
    coupon_id INTEGER,
    is_used BOOLEAN DEFAULT FALSE,
    issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    expires_at DATETIME,

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE,
	FOREIGN KEY (coupon_id) REFERENCES coupons(id)
		ON DELETE RESTRICT
        ON UPDATE CASCADE
);

CREATE TABLE notifications (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER,
    message VARCHAR(255) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE review (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    seller_id INTEGER,
    buyer_id INTEGER,
    product_id INTEGER,
    comment TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (seller_id) REFERENCES users(id)
		ON DELETE SET NULL
        ON UPDATE CASCADE,
	FOREIGN KEY (buyer_id) REFERENCES users(id)
		ON DELETE SET NULL
        ON UPDATE CASCADE,
	FOREIGN KEY (product_id) REFERENCES products(id)
		ON DELETE CASCADE
        ON UPDATE CASCADE
);

CREATE TABLE reports (
	id INTEGER PRIMARY KEY AUTO_INCREMENT,
    user_id INTEGER,
    date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('in_progress', 'end') DEFAULT 'in_progress',
    type ENUM('user', 'chat', 'product', 'review') NOT NULL,
    contents TEXT,
    related_id INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id)
		ON DELETE SET NULL
        ON UPDATE CASCADE
);

CREATE TABLE email_verifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) NOT NULL,
  code CHAR(6) NOT NULL,
  expires_at DATETIME NOT NULL,
  is_verified TINYINT(1) DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_email_code (email, code)
);

CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title TEXT NOT NULL,
    contents TEXT,
    date DATETIME DEFAULT CURRENT_TIMESTAMP,
    location VARCHAR(255),
    user_id INTEGER,

    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL          -- 수정: NOT NULL -> SET NULL (탈퇴 시 작성자만 NULL 처리)
        ON UPDATE CASCADE
);

CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contents TEXT NOT NULL,
    user_id INTEGER,
    post_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
        ON DELETE SET NULL          -- 수정: NOT NULL -> SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (post_id) REFERENCES posts(id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);