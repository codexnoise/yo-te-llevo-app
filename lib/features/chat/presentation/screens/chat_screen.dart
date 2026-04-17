import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../trips/presentation/providers/trips_providers.dart';
import '../../domain/entities/message.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

/// Pantalla de chat por match (spec §7).
class ChatScreen extends ConsumerStatefulWidget {
  final String matchId;

  const ChatScreen({super.key, required this.matchId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _markedOnce = false;

  Future<void> _markReadIfNeeded(List<Message> messages) async {
    if (_markedOnce) return;
    final currentUserId = ref.read(currentUserProvider).valueOrNull?.id;
    if (currentUserId == null) return;
    final hasUnread = messages.any(
      (m) => !m.read && m.senderId != currentUserId,
    );
    if (!hasUnread) return;
    _markedOnce = true;
    await ref
        .read(chatNotifierProvider(widget.matchId).notifier)
        .markAsRead(currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    final tripAsync = ref.watch(tripDetailStreamProvider(widget.matchId));
    final messagesAsync = ref.watch(messagesStreamProvider(widget.matchId));
    final notifierState = ref.watch(chatNotifierProvider(widget.matchId));

    ref.listen<AsyncValue<void>>(chatNotifierProvider(widget.matchId),
        (_, next) {
      next.whenOrNull(
        error: (err, _) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err.toString())),
        ),
      );
    });

    // Cuando entran nuevos mensajes, marcar leídos los entrantes.
    ref.listen<AsyncValue<List<Message>>>(
      messagesStreamProvider(widget.matchId),
      (_, next) {
        final data = next.valueOrNull;
        if (data != null) _markReadIfNeeded(data);
      },
    );

    final trip = tripAsync.valueOrNull;
    final viewerId = currentUser?.id;
    final notParticipant = trip != null &&
        viewerId != null &&
        !trip.isParticipant(viewerId);

    return Scaffold(
      appBar: _buildAppBar(trip),
      body: Column(
        children: [
          if (trip != null && !trip.canOpenChat && !notParticipant)
            _InfoBanner(
              text: 'Este viaje no permite chat en su estado actual. '
                  'Puedes leer el historial.',
            ),
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(err.toString(), textAlign: TextAlign.center),
                ),
              ),
              data: (messages) =>
                  _buildMessageList(messages, viewerId ?? ''),
            ),
          ),
          ChatInput(
            enabled: viewerId != null &&
                !notParticipant &&
                (trip?.canOpenChat ?? true),
            busy: notifierState.isLoading,
            onSend: (text) async {
              if (viewerId == null) return false;
              return ref
                  .read(chatNotifierProvider(widget.matchId).notifier)
                  .sendMessage(senderId: viewerId, text: text);
            },
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TripEntity? trip) {
    final counterpart = trip?.counterpart;
    if (counterpart == null) {
      return AppBar(title: const Text('Chat'));
    }
    return AppBar(
      title: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: counterpart.photoUrl != null
                ? NetworkImage(counterpart.photoUrl!)
                : null,
            child: counterpart.photoUrl == null
                ? const Icon(Icons.person, size: 16)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              counterpart.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<Message> messages, String viewerId) {
    if (messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sin mensajes todavía. Escribe el primero.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ListView reversed: índice 0 = último mensaje (abajo). Accedemos a la
    // lista desde el final para que autoscroll funcione sin controllers.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return MessageBubble(
          text: message.text,
          timestamp: message.timestamp,
          isMe: message.senderId == viewerId,
        );
      },
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;

  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.warning.withValues(alpha: 0.15),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      ),
    );
  }
}
