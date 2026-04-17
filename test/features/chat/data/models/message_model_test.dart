import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yo_te_llevo/features/chat/data/models/message_model.dart';
import 'package:yo_te_llevo/features/chat/domain/entities/message.dart';

Message _sample() => Message(
      id: 'msg1',
      senderId: 'u1',
      text: 'Hola!',
      timestamp: DateTime(2026, 4, 15, 10, 30),
      read: false,
    );

void main() {
  group('MessageModel', () {
    test('toMap serializes timestamp and read flag', () {
      final map = MessageModel.toMap(_sample());

      expect(map[MessageModel.fSenderId], 'u1');
      expect(map[MessageModel.fText], 'Hola!');
      expect(map[MessageModel.fTimestamp], isA<Timestamp>());
      expect(
        (map[MessageModel.fTimestamp] as Timestamp).toDate(),
        DateTime(2026, 4, 15, 10, 30),
      );
      expect(map[MessageModel.fRead], false);
    });

    test('fromMap reconstructs the entity from Firestore data', () {
      final map = {
        MessageModel.fSenderId: 'u2',
        MessageModel.fText: 'responde',
        MessageModel.fTimestamp: Timestamp.fromDate(
          DateTime(2026, 4, 15, 11, 0),
        ),
        MessageModel.fRead: true,
      };

      final message = MessageModel.fromMap('msg2', map);

      expect(message.id, 'msg2');
      expect(message.senderId, 'u2');
      expect(message.text, 'responde');
      expect(message.timestamp, DateTime(2026, 4, 15, 11, 0));
      expect(message.read, true);
    });

    test('round-trip toMap -> fromMap preserves all fields', () {
      final original = _sample();
      final back = MessageModel.fromMap(original.id, MessageModel.toMap(original));

      expect(back, original);
    });

    test('fromMap uses safe defaults for missing fields', () {
      final message = MessageModel.fromMap('msg3', const {});

      expect(message.senderId, '');
      expect(message.text, '');
      expect(message.read, false);
      // timestamp fallback to DateTime.now(); just assert it's recent.
      expect(
        message.timestamp.difference(DateTime.now()).inSeconds.abs(),
        lessThan(5),
      );
    });

    test('toCreateMap uses FieldValue.serverTimestamp and read=false', () {
      final map = MessageModel.toCreateMap(senderId: 'u1', text: 'hi');

      expect(map[MessageModel.fSenderId], 'u1');
      expect(map[MessageModel.fText], 'hi');
      expect(map[MessageModel.fRead], false);
      expect(map[MessageModel.fTimestamp], isA<FieldValue>());
    });
  });
}
