# RE-Point

A neighborhood marketplace platform for local secondhand trading. Supports general sale, point-based trading, and auction-style product listings, along with real-time chat.

## Tech Stack

**Backend**
- Node.js, Express
- MySQL (mysql2)
- JWT (jsonwebtoken) based authentication
- bcrypt for password hashing
- Socket.IO for real-time chat & live product viewing
- Resend for email verification
- Cloudinary for image storage
- Deployed on Railway

**Frontend**
- Flutter
- Google Maps API (location-based listings)
- socket_io_client for real-time chat

---

## Backend Structure (`server/node/src`)

```
src
│  app.js                      # Express app entry point — middleware, routers, socket init

├─config
│      cloudinary.js           # Cloudinary image upload config
│      db.js                   # MySQL connection pool config
│      resend.js               # Resend email verification config
│      upload.js               # Multer / file upload middleware config

├─controllers                  # Route handlers — validate requests, call models
│      authController.js       # Sign up / log in / delete account
│      bidController.js        # Auction bidding
│      categoryController.js   # Category lookup
│      favoriteController.js   # Favorite/like toggle — POST /products/:id/favorite
│      locationController.js   # Location-based lookup
│      postController.js       # Community posts
│      productController.js    # Product create/read/update
│      reportController.js     # Report handling
│      roomController.js       # Chat room list/creation (REST)
│      searchController.js     # Search
│      userController.js       # User profile read/update

├─middlewares
│      authMiddleware.js       # JWT verification middleware — applied to authenticated routes

├─models                       # DB query layer (MySQL)
│      authModel.js            # Auth data (auth table) — stores sensitive credentials
│      bidModel.js             # Auction bid records
│      categoryModel.js        # Categories
│      chatModel.js            # Chat message save/fetch (getMessagesByRoom, saveMessage, etc.)
│      commentModel.js         # Comments
│      favoriteModel.js        # Add/remove favorites, count management
│      locationModel.js        # Location data
│      postModel.js            # Posts
│      productModel.js         # Product data
│      reportModel.js          # Report records
│      roomModel.js            # Chat room info (getRoomInfo, getRoomList)
│      searchModel.js          # Search queries
│      userModel.js            # users table (references auth table via FK)

├─routes                       # Express routers — map URLs to controllers
│      authRoutes.js
│      categoryRoutes.js
│      locationRoutes.js
│      postRoutes.js
│      productRoutes.js
│      reportRoutes.js
│      roomRoutes.js
│      searchRoutes.js
│      userRoutes.js

├─sockets                      # Socket.IO namespaces/event handlers
│      chatSocket.js           # Chat room join/leave, message send/receive, typing indicators
│      productSocket.js        # Real-time viewer count on product detail page (joinProduct/leaveProduct)

└─utils
        formatTime.js          # Formats message timestamps as "09:41 AM"
        temperature.js         # Computes user reputation ("temperature") level (getTemperatureLevel)
```

### Database

- Relational (MySQL) schema made up of 26 tables in total
- Many-to-many relationships are separated into junction tables to preserve data consistency and integrity
- The `auth` table stores sensitive personal data; the `users` table references it via a foreign key used as its primary key
- Common product data lives in `products`, while auction-specific columns live in a separate `auction` table linked by foreign key
- Designed to prioritize stability over query performance, since the service directly handles users' money and assets

### Real-time (Socket.IO)

| Event | Direction | Description |
|---|---|---|
| `join_room` | client → server | Join a chat room; automatically leaves the previous room |
| `leave_room` | client → server | Leave a chat room; cleans up room membership |
| `room_info` | server → client | Counterpart info (name, reputation, product image) |
| `chat_history` | server → client | Past messages sent on room entry |
| `send_message` | client → server | Send a message |
| `receive_message` | server → client (room broadcast) | Broadcast to everyone in the room (including the sender) |
| `typing` / `stop_typing` | client ↔ server | Typing indicator |

---

## Frontend Structure (`client/lib`)

```
lib
│  main.dart                        # App entry point

├─models                            # Data models for parsing API/socket responses
│      chat_room_model.dart         # ChatRoomModel, ChatRoomInfoModel — chat room list / header info
│      message_model.dart           # MessageModel — parses chat_history / receive_message payloads

├─screens                           # Screen-level widgets
│      alarm_page.dart              # Notifications list
│      auction_detail_page.dart     # Auction product detail
│      chat_list_screen.dart        # Chat room list
│      chat_room_screen.dart        # Chat room — message send/receive, socket listener subscription
│      chat_search_page.dart        # In-chat search
│      choose_area_page.dart        # Area selection (onboarding)
│      create_account_page.dart     # Sign up
│      home_page.dart               # Home feed
│      item_detail_page.dart        # Product detail — favorite toggle, start chat, live-viewer socket
│      list_for_auction_page.dart   # Create auction listing
│      main_page.dart               # Main navigation container
│      map_page.dart                # Map-based product browsing (Google Maps API)
│      my_page.dart                 # My page / profile
│      pick_interests_page.dart     # Interest selection (onboarding)
│      post_auction_page.dart       # Auction post creation
│      report_listing_dialog.dart   # Report dialog
│      schedule_page.dart           # Schedule management (opened from chat room menu)
│      search_page.dart             # Search home
│      search_results_page.dart     # Search results list
│      sign_in_page.dart            # Log in
│      welcome_page.dart            # Welcome/start screen

├─services                          # API/socket communication layer
│      api_service.dart             # ApiConfig (baseUrl, token), AuthService, ProductService, and other REST services
│      api_test_screen.dart         # Temporary screen for API testing
│      chat_service.dart            # ChatService — manages Socket.IO connection, room join/leave, message streams (singleton)
│      current_user.dart            # CurrentUser — cached logged-in user profile (id, username, etc.)
│      productsocket_example.dart   # ProductSocketService — real-time viewer socket for product detail

├─theme
│      chat_theme.dart              # Chat screen color constants (ChatColors)

└─widgets                           # Reusable UI components
        auction_end_date_picker.dart  # Auction end-date picker widget
        chat_bubble.dart              # Chat message bubble
        custom_bottom_nav.dart        # Bottom navigation bar
        onboarding_step_header.dart   # Onboarding step header
        top_toast.dart                # Top toast notification
```

---
