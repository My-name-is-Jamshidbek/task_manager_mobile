/// Chat types enumeration
enum ChatType {
  oneToOne('one_to_one'),
  group('group');

  const ChatType(this.value);
  final String value;
}

/// Message status enumeration
enum MessageStatus {
  sending('sending'),
  sent('sent'),
  delivered('delivered'),
  read('read'),
  failed('failed');

  const MessageStatus(this.value);
  final String value;
}

/// Message type enumeration
enum MessageType {
  text('text'),
  image('image'),
  file('file'),
  audio('audio'),
  video('video');

  const MessageType(this.value);
  final String value;
}

/// Chat member role enumeration
enum ChatMemberRole {
  admin('admin'),
  member('member');

  const ChatMemberRole(this.value);
  final String value;
}
