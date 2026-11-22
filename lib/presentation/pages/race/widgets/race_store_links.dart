import 'package:caesar_puzzle/presentation/pages/settings/widgets/store_links.dart';
import 'package:material_ui/material_ui.dart';

/// Web only: a visitor who came by a room link may prefer the app.
class RaceStoreLinks extends StatelessWidget {
  const RaceStoreLinks({super.key});

  @override
  Widget build(final BuildContext context) {
    final links = webStoreLinks().where((final link) => link.url != null).toList();
    if (links.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        children: [
          for (final link in links)
            TextButton.icon(onPressed: () => openStoreLink(link), icon: Icon(link.icon), label: Text(link.title)),
        ],
      ),
    );
  }
}
