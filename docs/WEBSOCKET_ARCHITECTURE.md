# WebSocket Architecture Diagram

## System Architecture

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER APPLICATION                              │
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐  │
│  │                    PRESENTATION LAYER                              │  │
│  │                                                                     │  │
│  │  ┌──────────────────────────────────────────────────────────────┐  │  │
│  │  │         Chat Conversation Screen                            │  │  │
│  │  │  (with WebSocketChatMixin)                                  │  │  │
│  │  │                                                              │  │  │
│  │  │  - initializeWebSocket()                                    │  │  │
│  │  │  - onMessageReceived()                                      │  │  │
│  │  │  - onUserTyping()                                           │  │  │
│  │  │  - onMessagesRead()                                         │  │  │
│  │  │  - disposeWebSocket()                                       │  │  │
│  │  └────────┬──────────────────────────────────────────────────┬─┘  │  │
│  │           │                                                  │     │  │
│  │  ┌────────▼──────────────────────────────────────────────────▼──┐  │  │
│  │  │  WebSocketErrorDialog                                        │  │  │
│  │  │  WebSocketErrorSnackbar                                      │  │  │
│  │  │                                                              │  │  │
│  │  │  - showWebSocketErrorDialog()                               │  │  │
│  │  │  - showWebSocketErrorSnackbar()                             │  │  │
│  │  └──────────────────────────────────────────────────────────────┘  │  │
│  │                                                                     │  │
│  └─────────────────────────────┬──────────────────────────────────────┘  │
│                                │                                        │
│  ┌─────────────────────────────▼──────────────────────────────────────┐  │
│  │                  STATE MANAGEMENT LAYER                           │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────────┐  │  │
│  │  │      WebSocketManager (Provider/ChangeNotifier)            │  │  │
│  │  │                                                             │  │  │
│  │  │  Properties:                                               │  │  │
│  │  │  - _isConnected: bool                                      │  │  │
│  │  │  - _isConnecting: bool                                     │  │  │
│  │  │  - _lastError: String?                                     │  │  │
│  │  │  - _eventHistory: List<WebSocketEvent>                     │  │  │
│  │  │  - _subscriptions: Map<String, bool>                       │  │  │
│  │  │                                                             │  │  │
│  │  │  Methods:                                                   │  │  │
│  │  │  - connect(token, userId)                                  │  │  │
│  │  │  - subscribeToChannel(channel)                             │  │  │
│  │  │  - unsubscribeFromChannel(channel)                         │  │  │
│  │  │  - onEvent(callback)                                       │  │  │
│  │  │  - onEventType<T>(callback)                                │  │  │
│  │  │  - sendMessage(channel, event, data)                       │  │  │
│  │  │  - disconnect()                                            │  │  │
│  │  │                                                             │  │  │
│  │  │  Streams:                                                   │  │  │
│  │  │  - connectionStateStream: Stream<bool>                     │  │  │
│  │  │  - errorStream: Stream<String>                             │  │  │
│  │  │  - eventStream: Stream<WebSocketEvent>                     │  │  │
│  │  └─────────────────────────────┬──────────────────────────────┘  │  │
│  │                                │                               │  │
│  └────────────────────────────────┼───────────────────────────────┘  │
│                                   │                                │
│  ┌────────────────────────────────▼───────────────────────────────┐  │
│  │              SERVICE LAYER                                     │  │
│  │                                                               │  │
│  │  ┌──────────────────────────────────────────────────────────┐  │  │
│  │  │         WebSocketService                                │  │  │
│  │  │                                                          │  │  │
│  │  │  Properties:                                            │  │  │
│  │  │  - _channel: WebSocketChannel                           │  │  │
│  │  │  - _isConnected: bool                                   │  │  │
│  │  │  - _socketId: String?                                   │  │  │
│  │  │  - _userToken: String?                                  │  │  │
│  │  │  - _reconnectAttempts: int                              │  │  │
│  │  │                                                          │  │  │
│  │  │  Methods:                                               │  │  │
│  │  │  - connect(token, userId)                              │  │  │
│  │  │  - subscribeToChannel(channel, auth)                   │  │  │
│  │  │  - unsubscribeFromChannel(channel)                     │  │  │
│  │  │  - sendMessage(channel, event, data)                  │  │  │
│  │  │  - disconnect()                                        │  │  │
│  │  │  - _send(data)                                         │  │  │
│  │  │  - _handleMessage(message)                             │  │  │
│  │  │  - _handleError(error)                                 │  │  │
│  │  │  - _attemptReconnect()                                 │  │  │
│  │  │                                                          │  │  │
│  │  │  Streams:                                               │  │  │
│  │  │  - connectionStateStream                                │  │  │
│  │  │  - errorStream                                          │  │  │
│  │  │  - eventStream                                          │  │  │
│  │  └──────────────────────────┬───────────────────────────────┘  │  │
│  │                             │                               │  │
│  └─────────────────────────────┼───────────────────────────────┘  │
│                                │                                │
└────────────────────────────────┼────────────────────────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │                        │
          ┌─────────▼──────────┐   ┌────────▼─────────────┐
          │  WEBSOCKET LAYER   │   │   DATA MODELS      │
          │                    │   │                    │
          │ WebSocketChannel   │   │ WebSocketEvent     │
          │ (web_socket_pack)  │   │ ├─ MessageSent     │
          │                    │   │ ├─ UserTyping      │
          │ - connect(url)     │   │ ├─ MessagesRead    │
          │ - send(message)    │   │ └─ Unknown         │
          │ - listen(stream)   │   │                    │
          │ - close()          │   │                    │
          └─────────┬──────────┘   └────────────────────┘
                    │
          ┌─────────▼──────────────┐
          │   HTTP/TLS LAYER       │
          │                        │
          │ Pusher Server          │
          │ (tms.amusoft.uz:443)   │
          │                        │
          │ Reverb Service         │
          │ WebSocket Protocol 7   │
          │                        │
          └────────────────────────┘
```

## Data Flow Diagrams

### 1. Connection Establishment

```
User initiates Chat
         │
         ▼
Call initializeWebSocket()
         │
         ├─→ Connect to WebSocket ─→ Pusher Server
         │        │                      │
         │        │◄─ Connection OK      │
         │        │
         │   Get socket_id
         │        │
         ├─→ Authorize Channel ─→ Backend (/broadcasting/auth)
         │        │                      │
         │        │◄─ auth token         │
         │        │
         ├─→ Subscribe to Channel
         │        │
         │        ▼
         │    Pusher confirms
         │        │
         ▼        ▼
    READY for Events
         │
         ├─→ Listen to:
         │   - MessageSentEvent
         │   - UserIsTypingEvent
         │   - MessagesReadEvent
         │
         ▼
   Event Callbacks Fired
```

### 2. Message Received Flow

```
Backend sends event
         │
         ▼
Pusher broadcasts
         │
         ▼
WebSocket receives
         │
         ▼
_handleMessage() parses JSON
         │
         ▼
Pattern match on event type
         │
         ├─→ "message" ─→ MessageSentEvent
         │        │
         │        ▼
         │    _eventStreamController.add()
         │        │
         │        ▼
         │    Manager notifyListeners()
         │        │
         │        ▼
         │    Chat screen callback
         │        │
         │        ▼
         │    setState() → Update UI
         │
         ├─→ "typing" ─→ UserIsTypingEvent
         │        └─→ Show typing indicator
         │
         └─→ "read" ─→ MessagesReadEvent
                  └─→ Update message status
```

### 3. Error Handling Flow

```
Error occurs
     │
     ├─→ Connection Error
     │      │
     │      ├─→ Log: Logger.error()
     │      │
     │      ├─→ Stream: errorController.add()
     │      │
     │      ├─→ Manager: _lastError = error
     │      │
     │      ├─→ notifyListeners()
     │      │
     │      ├─→ Auto-reconnect (up to 5 attempts)
     │      │
     │      └─→ Show Dialog if fatal
     │
     ├─→ Subscription Error
     │      │
     │      ├─→ Log: Logger.error()
     │      │
     │      └─→ Show Snackbar
     │
     └─→ Event Parsing Error
            │
            ├─→ Log: Logger.warning()
            │
            └─→ Continue (non-blocking)
```

### 4. Disconnection & Cleanup

```
Screen dispose()
     │
     ├─→ disposeWebSocket() called
     │      │
     │      ├─→ Cancel event subscription
     │      │
     │      ├─→ Disconnect from server
     │      │
     │      ├─→ Close all streams
     │      │
     │      └─→ Clear state
     │
     ▼
Resources cleaned up
```

## Component Interactions

```
┌──────────────────────────────────────────────────────────────────────┐
│                        CHAT SCREEN                                  │
│                                                                      │
│  initState()                                                         │
│    │                                                                │
│    └─→ WebSocketChatMixin.initializeWebSocket()                    │
│           │                                                        │
│           ├─→ Manager.connect(token, userId)                      │
│           │      │                                                │
│           │      └─→ Service.connect()                            │
│           │             │                                         │
│           │             └─→ WebSocket.connect()                   │
│           │                    │                                  │
│           │                    └─→ Pusher                        │
│           │                         │                            │
│           │                         └─ Connection Established     │
│           │                                                       │
│           ├─→ Manager.subscribeToChannel(channelName)           │
│           │      │                                              │
│           │      ├─→ Call onAuthRequired()                      │
│           │      │      │                                       │
│           │      │      └─→ Backend /broadcasting/auth         │
│           │      │           │                                 │
│           │      │           └─ Returns auth token             │
│           │      │                                             │
│           │      └─→ Service.subscribeToChannel()              │
│           │             │                                      │
│           │             └─→ Send subscription payload           │
│           │                  │                                 │
│           │                  └─ Subscription Confirmed         │
│           │                                                     │
│           ├─→ Manager.onEvent((event) {...})                 │
│           │      │                                            │
│           │      └─→ Listen to eventStream                    │
│           │          When event arrives:                      │
│           │          - onMessageReceived(event)              │
│           │          - onUserTyping(event)                   │
│           │          - onMessagesRead(event)                 │
│           │                                                   │
│           └─→ Setup UI callbacks                             │
│                                                               │
│                                                               │
│  Events Received (Real-time Updates)                         │
│    │                                                         │
│    ├─→ MessageSentEvent → Update message list                │
│    │                                                         │
│    ├─→ UserIsTypingEvent → Show typing indicator             │
│    │                                                         │
│    └─→ MessagesReadEvent → Update message status             │
│                                                               │
│                                                               │
│  dispose()                                                    │
│    │                                                         │
│    └─→ WebSocketChatMixin.disposeWebSocket()               │
│           │                                                 │
│           ├─→ Cancel event subscription                    │
│           │                                                │
│           └─→ Manager.disconnect()                        │
│                  │                                         │
│                  ├─→ Service.disconnect()                │
│                  │      │                                │
│                  │      └─→ WebSocket.close()           │
│                  │           │                          │
│                  │           └─ Connection Closed       │
│                  │                                     │
│                  └─→ Cleanup resources                │
└──────────────────────────────────────────────────────────────────────┘
```

## Event Processing Pipeline

```
Raw WebSocket Message (JSON)
         │
         ▼
WebSocketService._handleMessage()
         │
         ├─→ Parse JSON
         │
         ├─→ Extract event type
         │
         ├─→ Route to handler:
         │
         ├─→ "pusher:connection_established"
         │      │
         │      └─→ _handleConnectionEstablished()
         │             │
         │             ├─→ Extract socket_id
         │             ├─→ Set _isConnected = true
         │             ├─→ Add to eventStream
         │             └─→ notifyListeners()
         │
         ├─→ "pusher:ping"
         │      │
         │      └─→ _handlePing()
         │             │
         │             └─→ Send "pusher:pong"
         │
         ├─→ "pusher:subscription_succeeded"
         │      │
         │      └─→ _handleSubscriptionSucceeded()
         │             │
         │             └─→ Add to eventStream
         │
         └─→ App Event (message|typing|read)
                │
                ├─→ Parse as WebSocketEvent
                │
                ├─→ Filter by type:
                │   ├─ MessageSentEvent
                │   ├─ UserIsTypingEvent
                │   ├─ MessagesReadEvent
                │
                ├─→ Add to eventStream
                │
                ├─→ Store in history (max 100)
                │
                └─→ notifyListeners()
```

## State Transitions

```
                      ┌──────────────┐
                      │ DISCONNECTED │
                      │ connected=F  │
                      │ connecting=F │
                      └──────┬───────┘
                             │
              connect(token, userId)
                             │
                             ▼
                      ┌──────────────┐
                      │ CONNECTING   │
                      │ connected=F  │
                      │ connecting=T │
                      └──────┬───────┘
                             │
                 WS connection established
                    socket_id received
                             │
                             ▼
    subscribeToChannel()  ┌──────────────┐
           ┌─────────────→│ CONNECTED    │◄─────────┐
           │              │ connected=T  │          │
           │              │ connecting=F │          │
           │              └──────┬───────┘          │
           │                     │                  │
    channel auth OK          subscribe()            │
    subscription confirmed        │           auto-reconnect
           │                      ▼                 │
           │              ┌──────────────┐          │
           └─────────────→│ SUBSCRIBED   │──────────┘
                          │ connected=T  │
                          │ listening=T  │
                          └──────┬───────┘
                                 │
                        Events received/sent
                                 │
                 disconnect() or connection lost
                                 │
                                 ▼
                          ┌──────────────┐
                          │ DISCONNECTED │
                          │ connected=F  │
                          └──────────────┘
```

---

**Architecture Design Principles**:
1. **Separation of Concerns**: Service, Manager, UI layers
2. **Stream-Based**: Reactive event handling
3. **Error Resilience**: Automatic reconnection and graceful degradation
4. **Logging**: Full observability at every step
5. **Resource Management**: Proper cleanup and disposal
