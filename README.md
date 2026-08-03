# RE-Point

A neighborhood marketplace platform for local secondhand trading. Supports general sale, point-based trading, and auction-style product listings, along with real-time chat.

## Tech Stack

**Backend**
- Node.js, Express
- MySQL (mysql2)
- JWT (jsonwebtoken) based authentication
- bcrypt for password hashing
- Socket.IO for real-time chat
- Resend for email verification

**Frontend**
- Flutter

## Key Features

- Signup / Login / Account deletion
- Email verification (currently auto-verified in the test environment)
- Preferred category selection (up to 5)
- Product registration (general sale / point-based / auction)
- Product listing (separated by trade type)
- Product detail view
- Real-time chat (room creation, room list, sending/receiving messages)
- Reporting (unified handling for user / chat / product / review targets)

## Folder Structure

```
server/node
├─ src/
│  ├─ app.js                # Server entry point
│  ├─ config/
│  │  └─ db.js              # MySQL connection pool setup
│  ├─ routes/                # Route definitions
│  ├─ controllers/           # Request handling and responses
│  ├─ models/                 # DB queries
│  ├─ middlewares/
│  │  └─ authMiddleware.js  # JWT verification
│  ├─ sockets/
│  │  └─ chatSocket.js      # Chat socket event handling
│  └─ utils/                 # Shared utility functions
├─ .env.local                # Environment variables (not committed to git)
└─ package.json
```

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd server/node
```

### 2. Install dependencies

```bash
npm install
```

### 3. Set up environment variables

Create a `.env.local` file and fill in the following values.

```
PORT=3000
DB_HOST=localhost
DB_USER=repoint_user
DB_PASSWORD=your_db_password
DB_NAME=repoint
JWT_SECRET=your_random_long_secret_string
JWT_EXPIRES_IN=7d
RESEND_API_KEY=your_resend_api_key
```

### 4. Set up the database

Connect to MySQL and create the database and tables. Run `db/schema.sql` (or the SQL file shared separately).

```bash
mysql -u repoint_user -p repoint < db/schema.sql
```

### 5. Run the server

```bash
npm start        # Production
npm run dev       # Development (nodemon, auto-restarts on file changes)
```

On success, you should see:

```
Server running on port 3000
```

## API Documentation

For the full API specification with example requests/responses, see `RE-Point_API_Docs.md`. Endpoints that require authentication expect the JWT issued at login in the header, formatted as follows.

```
Authorization: Bearer {token}
```

## Notes

- Authenticated requests can be tested with an API client such as Bruno or Postman.
- Chat runs over Socket.IO (WebSocket) rather than REST, and authenticates the connection by passing the JWT in `auth.token`.
