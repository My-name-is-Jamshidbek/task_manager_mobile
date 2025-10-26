#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
WebSocket Listener for Flutter Chat - Test Script

This script connects to your WebSocket server and listens for real-time chat events.
It helps verify your WebSocket implementation is working correctly.

Required env vars (or provide defaults):
  REVERB_APP_KEY   -> "1puo7oyhapqfczgdmt1d"
  REVERB_HOST      -> "tms.amusoft.uz"
  REVERB_PORT      -> 443
  REVERB_SCHEME    -> "https" (for wss) or "http" (for ws)
  API_BASE_URL     -> "https://tms.amusoft.uz/api"

Install dependencies:
  pip install requests websocket-client certifi

Usage:
  python websocket_listener.py
"""

import json
import os
import sys
import ssl
from typing import Any, Optional
from datetime import datetime

import certifi
import requests
try:
    from websocket import WebSocketApp
except ImportError:
    print("Error: websocket-client is not installed.")
    print("Install it with: pip install websocket-client")
    sys.exit(1)


def _env(name: str, default: Optional[str] = None) -> Optional[str]:
    """Get environment variable or use default"""
    val = os.getenv(name)
    return val if val is not None else default


def _join_url(base_url: str, path: str) -> str:
    """Join base URL with path"""
    base = base_url[:-1] if base_url.endswith('/') else base_url
    return f"{base}{path}"


def _timestamp() -> str:
    """Get current timestamp"""
    return datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def _log(message: str, level: str = "INFO") -> None:
    """Simple logging"""
    print(f"[{_timestamp()}] [{level}] {message}")


class WebSocketListener:
    """WebSocket listener for testing real-time chat events"""

    def __init__(
        self,
        *,
        app_key: str,
        host: str,
        port: int,
        scheme: str,
        api_base_url: str,
        token: str,
        user_id: Any,
        broadcast_base_url: str,
    ) -> None:
        self.app_key = app_key
        self.host = host
        self.port = port
        self.scheme = scheme
        self.api_base_url = api_base_url.rstrip('/')
        self.broadcast_base_url = broadcast_base_url.rstrip('/')
        self.token = token
        self.user_id = user_id
        self.channel_name = f"private-user.{user_id}"
        self.socket_id: Optional[str] = None
        self.ws: Optional[WebSocketApp] = None
        self.subscribed = False

    def _ws_url(self) -> str:
        """Construct WebSocket URL"""
        ws_scheme = 'wss' if self.scheme in ('https', 'wss') else 'ws'
        return f"{ws_scheme}://{self.host}:{self.port}/app/{self.app_key}?protocol=7&client=python&version=1.0&flash=false"

    def _headers(self) -> dict:
        """Construct request headers"""
        return {
            'Authorization': f'Bearer {self.token}',
            'X-Requested-With': 'XMLHttpRequest',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
        }

    def _authorize_channel(self, socket_id: str) -> str:
        """Get channel authorization"""
        url = _join_url(self.broadcast_base_url, '/broadcasting/auth')
        _log(f"Authorizing channel with URL: {url}")
        
        try:
            resp = requests.post(
                url,
                headers=self._headers(),
                json={
                    'channel_name': self.channel_name,
                    'socket_id': socket_id,
                },
                timeout=20,
            )
            
            if not resp.ok:
                _log(f"Authorization failed: {resp.status_code} {resp.text}", "ERROR")
                resp.raise_for_status()
            
            payload = resp.json()
            if 'auth' not in payload:
                raise RuntimeError('Auth endpoint did not return "auth"')
            
            _log(f"Channel authorized successfully", "SUCCESS")
            return payload['auth']
        except Exception as e:
            _log(f"Authorization error: {e}", "ERROR")
            raise

    def _send(self, event: str, data: Any) -> None:
        """Send message through WebSocket"""
        if self.ws:
            self.ws.send(json.dumps({
                'event': event,
                'data': data,
            }))

    def _on_open(self, ws: WebSocketApp) -> None:
        """Called when WebSocket connection opens"""
        _log("WebSocket connection opened", "SUCCESS")

    def _on_close(self, ws: WebSocketApp, status_code, msg) -> None:
        """Called when WebSocket connection closes"""
        _log(f"WebSocket connection closed: code={status_code} msg={msg}", "WARNING")

    def _on_error(self, ws: WebSocketApp, error: Exception) -> None:
        """Called when WebSocket error occurs"""
        _log(f"WebSocket error: {error}", "ERROR")

    def _on_message(self, ws: WebSocketApp, message: str) -> None:
        """Called when WebSocket message is received"""
        try:
            msg = json.loads(message)
        except Exception as e:
            _log(f"Failed to parse message JSON: {e}", "WARNING")
            _log(f"Raw message: {message}", "DEBUG")
            return

        event = msg.get('event')

        # Handle Pusher protocol events
        if event == 'pusher:connection_established':
            self._handle_connection_established(msg)
        elif event == 'pusher:ping':
            self._handle_ping()
        elif event == 'pusher_internal:subscription_succeeded' or event == 'pusher:subscription_succeeded':
            self._handle_subscription_succeeded(msg)
        else:
            self._handle_app_event(msg)

    def _handle_connection_established(self, msg: dict) -> None:
        """Handle connection established event"""
        try:
            data = json.loads(msg.get('data', '{}')) if isinstance(msg.get('data'), str) else msg.get('data', {})
            self.socket_id = data.get('socket_id')
            _log(f"Connected! socket_id={self.socket_id}", "SUCCESS")
            
            # Authorize and subscribe to channel
            try:
                auth_token = self._authorize_channel(self.socket_id)
                sub_payload = {
                    'channel': self.channel_name,
                    'auth': auth_token,
                }
                self._send('pusher:subscribe', sub_payload)
                _log(f"Subscribing to {self.channel_name}...", "INFO")
            except Exception as e:
                _log(f"Failed to authorize/subscribe: {e}", "ERROR")
                ws.close()
        except Exception as e:
            _log(f"Error handling connection established: {e}", "ERROR")

    def _handle_ping(self) -> None:
        """Handle ping message"""
        self._send('pusher:pong', {})

    def _handle_subscription_succeeded(self, msg: dict) -> None:
        """Handle subscription succeeded event"""
        channel = msg.get('channel')
        _log(f"Subscribed to {channel} ✓", "SUCCESS")
        self.subscribed = True

    def _handle_app_event(self, msg: dict) -> None:
        """Handle app-specific events"""
        try:
            data = msg.get('data')
            if isinstance(data, str):
                data = json.loads(data)
            
            if not isinstance(data, dict):
                _log(f"Invalid event data: {data}", "WARNING")
                return

            event_type = data.get('type')
            event_data = data.get('data', {})

            if event_type == 'message':
                self._log_message_event(event_data)
            elif event_type == 'typing':
                self._log_typing_event(event_data)
            elif event_type == 'read':
                self._log_read_event(event_data)
            else:
                _log(f"Unknown event type: {event_type}", "WARNING")
                _log(f"Full data: {json.dumps(data, indent=2)}", "DEBUG")
        except Exception as e:
            _log(f"Error handling app event: {e}", "ERROR")

    def _log_message_event(self, data: dict) -> None:
        """Log message event"""
        message = data.get('message', {})
        msg_id = message.get('id', 'unknown')
        sender = message.get('sender_name', 'Unknown')
        content = message.get('content', '')
        temp_id = data.get('tempId')
        
        _log(f"📨 NEW MESSAGE", "EVENT")
        _log(f"  ID: {msg_id}")
        if temp_id:
            _log(f"  Temp ID: {temp_id}")
        _log(f"  From: {sender}")
        _log(f"  Content: {content[:100]}{'...' if len(content) > 100 else ''}")
        _log(f"  Full: {json.dumps(data, indent=2)}", "DEBUG")

    def _log_typing_event(self, data: dict) -> None:
        """Log typing event"""
        user = data.get('user', {})
        user_id = user.get('id', 'unknown')
        user_name = user.get('firstName', 'Unknown')
        conv_id = data.get('conversation_id', 'unknown')
        
        _log(f"⌨️  USER TYPING", "EVENT")
        _log(f"  User ID: {user_id}")
        _log(f"  User Name: {user_name}")
        _log(f"  Conversation: {conv_id}")

    def _log_read_event(self, data: dict) -> None:
        """Log read event"""
        reader_id = data.get('reader_id', 'unknown')
        conv_id = data.get('conversation_id', 'unknown')
        msg_ids = data.get('message_ids', [])
        
        _log(f"✅ MESSAGES READ", "EVENT")
        _log(f"  Reader ID: {reader_id}")
        _log(f"  Conversation: {conv_id}")
        _log(f"  Message IDs: {msg_ids}")

    def run_forever(self) -> None:
        """Start listening to WebSocket"""
        _log(f"Connecting to WebSocket...")
        _log(f"URL: {self._ws_url()}")
        
        self.ws = WebSocketApp(
            self._ws_url(),
            on_open=self._on_open,
            on_message=self._on_message,
            on_error=self._on_error,
            on_close=self._on_close,
        )

        # SSL configuration
        insecure = _env('REVERB_INSECURE_SSL', '0') in ('1', 'true', 'TRUE')
        if insecure:
            sslopt = {"cert_reqs": ssl.CERT_NONE, "check_hostname": False}
            _log('Warning: REVERB_INSECURE_SSL enabled. TLS verification is disabled!', "WARNING")
        else:
            sslopt = {"cert_reqs": ssl.CERT_REQUIRED, "ca_certs": certifi.where()}

        self.ws.run_forever(ping_interval=30, ping_timeout=10, origin=None, sslopt=sslopt)


def api_login(*, base_url: str, phone: str, password: str, timeout: int = 20) -> dict:
    """Login to API and get token"""
    url = _join_url(base_url, '/auth/login')
    headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
    }
    body = {"phone": phone, "password": password}
    
    _log(f"Logging in as {phone}...")
    
    resp = requests.post(url, json=body, headers=headers, timeout=timeout)
    if not resp.ok:
        _log(f"Login failed: {resp.status_code}", "ERROR")
        try:
            resp.raise_for_status()
        except Exception as e:
            _log(f"Error: {e}", "ERROR")
            raise
    
    data = resp.json()
    if not data or 'token' not in data or 'user' not in data:
        raise RuntimeError('Login succeeded but token or user missing')
    
    _log(f"Login successful! ✓", "SUCCESS")
    return data


def main() -> int:
    """Main entry point"""
    print("\n" + "="*60)
    print("  WebSocket Chat Listener - Flutter Test Script")
    print("="*60 + "\n")

    # Configuration
    app_key = _env('REVERB_APP_KEY', '1puo7oyhapqfczgdmt1d')
    host = _env('REVERB_HOST', 'tms.amusoft.uz')
    port = int(_env('REVERB_PORT', '443'))
    scheme = _env('REVERB_SCHEME', 'https')
    api_base = _env('API_BASE_URL', 'https://tms.amusoft.uz/api')
    broadcast_base = f"{'https' if scheme in ('https', 'wss') else 'http'}://{host}"

    # Test credentials (replace with your test user)
    phone = _env('TEST_PHONE', '+998111111111')
    password = _env('TEST_PASSWORD', 'password')

    # Validate configuration
    missing = [
        name for name, val in {
            'REVERB_APP_KEY': app_key,
            'REVERB_HOST': host,
            'API_BASE_URL': api_base,
        }.items()
        if not val
    ]

    if missing:
        _log(f'Missing configuration: {", ".join(missing)}', "ERROR")
        return 2

    # Print configuration
    _log(f"Configuration:", "INFO")
    _log(f"  App Key: {app_key}", "DEBUG")
    _log(f"  Host: {host}:{port}", "DEBUG")
    _log(f"  Scheme: {scheme}", "DEBUG")
    _log(f"  API Base: {api_base}", "DEBUG")
    print()

    # Login
    try:
        auth = api_login(base_url=api_base, phone=phone, password=password)
        token = auth['token']
        user = auth['user']
        user_id = user.get('id')
        user_name = f"{user.get('firstName')} {user.get('lastName')}".strip()
        
        _log(f"User: {user_name} (ID: {user_id})", "INFO")
        print()
    except Exception as e:
        _log(f"Login failed: {e}", "ERROR")
        return 1

    # Start listening
    _log("Starting WebSocket listener...", "INFO")
    _log("Press Ctrl+C to stop\n", "INFO")

    listener = WebSocketListener(
        app_key=app_key,
        host=host,
        port=port,
        scheme=scheme,
        api_base_url=api_base,
        token=token,
        user_id=user_id,
        broadcast_base_url=broadcast_base,
    )

    try:
        listener.run_forever()
    except KeyboardInterrupt:
        _log("\nListener stopped by user", "INFO")
        return 0
    except Exception as e:
        _log(f"Unexpected error: {e}", "ERROR")
        return 1


if __name__ == '__main__':
    sys.exit(main())
