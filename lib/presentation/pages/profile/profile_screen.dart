import 'package:caesar_puzzle/generated/l10n.dart';
import 'package:caesar_puzzle/infrastructure/firebase/firestore_paths.dart';
import 'package:caesar_puzzle/injection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.uid});

  final String uid;

  @override
  Widget build(final BuildContext context) {
    final doc = getIt<FirebaseFirestore>().doc(FirestorePaths.publicUserDoc(uid));
    return Scaffold(
      appBar: AppBar(title: Text(S.current.accountPublicProfileTitle)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: doc.snapshots(),
        builder: (final context, final snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data?.data();
          if (data == null) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.current.profileNoPublicProfile),
                  const SizedBox(height: 12),
                  _ShareRow(uid: uid),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                (data['displayName'] as String?) ?? S.current.profilePlayerFallback,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(S.current.profileUidLabel(uid), style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(S.current.profileSolvedSessions),
                  trailing: Text('${data['solvedSessions'] ?? 0}'),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text(S.current.profileSolvedVariants),
                  trailing: Text('${data['solvedVariants'] ?? 0}'),
                ),
              ),
              const SizedBox(height: 16),
              _ShareRow(uid: uid),
            ],
          );
        },
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.uid});

  final String uid;

  @override
  Widget build(final BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      // todo need to provide sharing
      // OutlinedButton.icon(
      //   onPressed: () async {
      //     await Clipboard.setData(ClipboardData(text: uid));
      //     if (!context.mounted) return;
      //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.current.profileCopiedUid)));
      //   },
      //   icon: const Icon(Icons.copy),
      //   label: Text(S.current.profileCopyUid),
      // ),
    ],
  );
}

